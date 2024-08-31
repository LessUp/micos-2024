version 1.0

workflow metagenomic_analysis_workflow {
    input {
        # KneadData inputs
        Array[File] input_files_r1
        Array[File] input_files_r2
        Array[File] kneaddata_db_files
        Int kneaddata_threads = 4

        # Kraken2
        Array[File] kraken2_db_files
        Int kraken_threads = 4
        Float confidence = 0.01
        Int min_base_quality = 20
        Int min_hit_groups = 3

        # Krona
        Array[String] basename_list

        # Qiime2
        File metadata
        Int qiime2_min_frequency = 10
        Int qiime2_min_samples = 3
        Int qiime2_sampling_depth = 1000
        File taxonomy_convert_script
    }

    # Step 1: Run KneadData on input files
    scatter (i in range(length(input_files_r1))) {
        call KneadDataTask {
            input:
                input_file_r1 = input_files_r1[i],
                input_file_r2 = input_files_r2[i],
                kneaddata_db_files = kneaddata_db_files,
                threads = kneaddata_threads
        }
    }

    # Step 2: Run Kraken2 on KneadData output
    scatter (i in range(length(KneadDataTask.output_paired_1))) {
        call Kraken2Task {
            input:
                input_file_r1 = KneadDataTask.output_paired_1[i],
                input_file_r2 = KneadDataTask.output_paired_2[i],
                kraken2_db_files = kraken2_db_files,
                threads = kraken_threads,
                confidence = confidence,
                min_base_quality = min_base_quality,
                min_hit_groups = min_hit_groups,
                output_basename = basename_list[i],
        }
    }

    # Step 3: Merge Kraken2 TSV outputs
    call MergeTSVTask {
        input:
            input_files = Kraken2Task.output_tsv_file
    }

    # Step 4: Generate BIOM file from Kraken2 reports
    call kraken_biom {
        input:
            input_files = Kraken2Task.report_txt_file,
            output_filename = "kraken_biom_output.biom"
    }

    # Step 5: Generate Krona visualizations
    scatter (idx in range(length(Kraken2Task.report_txt_file))) {
        call krona {
            input:
                input_file = Kraken2Task.report_txt_file[idx],
                output_basename = basename_list[idx]
        }
    }

    # Step 6: QIIME2 analysis
    call ImportFeatureTable {
        input:
            input_biom = kraken_biom.output_biom
    }

    call ConvertKraken2Tsv {
        input:
            qiime2_merged_taxonomy_tsv = MergeTSVTask.merged_tsv,
            taxonomy_convert_script = taxonomy_convert_script
    }

    call ImportTaxonomy {
        input:
            input_tsv = ConvertKraken2Tsv.merge_converted_taxonomy
    }

    call FilterRareFeatures {
        input:
            input_table = ImportFeatureTable.output_qza,
            qiime2_min_samples = qiime2_min_samples
    }

    call CalculateChao1Diversity {
        input:
            input_table = FilterRareFeatures.filtered_table
    }

    call ExportChao1Diversity {
        input:
            chao1_diversity = CalculateChao1Diversity.chao1_diversity
    }


    # 计算Alpha指数的箱线图
    call AlphaDiversityBoxPlot {
        input:
            chao1_diversity = CalculateChao1Diversity.chao1_diversity,
            metadata = metadata
    }



    call CalculateBetaDiversity {
        input:
            input_table = FilterRareFeatures.filtered_table
    }

    call PerformAndVisualizePCoA {
        input:
            distance_matrix = CalculateBetaDiversity.distance_matrix,
            metadata = metadata
    }

    call AddPseudocount {
        input:
            input_table = FilterRareFeatures.filtered_table
    }

    # 计算热图
    call GenerateHeatmap {
        input:
            input_table = ImportFeatureTable.output_qza,
            metadata = metadata
    }

    output {
        # 分类结果
        Array[File] kraken2_report_txt = Kraken2Task.report_txt_file
        Array[File] kraken2_tsv_file = Kraken2Task.output_tsv_file

        # 物种分类图
        Array[File] krona_html_reports = krona.output_html

        File filtered_table = FilterRareFeatures.filtered_table
        File distance_matrix = CalculateBetaDiversity.distance_matrix
        File comp_table = AddPseudocount.comp_table

        # beta 多样性 PCoA
        File pcoa_qzv = PerformAndVisualizePCoA.visualization
        File pcoa_exports = PerformAndVisualizePCoA.exported_files

        # alpha 多样性
        File chao1_diversity = ExportChao1Diversity.exported_chao1_diversity

        # 热图
        File heatmap_qzv = GenerateHeatmap.heatmap_visualization
        File heatmap_exports = GenerateHeatmap.exported_files

        # 箱线图
        File alpha_diversity_boxplot = AlphaDiversityBoxPlot.alpha_group_significance_visualization
        File alpha_diversity_boxplot_exports = AlphaDiversityBoxPlot.exported_files

        # 过滤后的fastq
        Array[File] kneaddata_paired_1 = KneadDataTask.output_paired_1
        Array[File] kneaddata_paired_2 = KneadDataTask.output_paired_2

        # 其他文件
        File output_biom = kraken_biom.output_biom
        File merged_tsv = MergeTSVTask.merged_tsv
        File convert_csv = ConvertKraken2Tsv.merge_converted_taxonomy
    }
}

# KneadData task to preprocess raw sequencing data
task KneadDataTask {
    input {
        File input_file_r1
        File input_file_r2
        Array[File] kneaddata_db_files
        Int threads
    }

    command <<<
        mkdir -p kneaddata_db
        for db_file in ~{sep=' ' kneaddata_db_files}; do
            ln -sf ${db_file} kneaddata_db/
        done

        kneaddata \
        --input1 ~{input_file_r1} \
        --input2 ~{input_file_r2} \
        --reference-db kneaddata_db \
        --output kneaddata_out \
        --threads ~{threads} \
        --remove-intermediate-output \
        --bypass-trf
    >>>

    output {
        File output_paired_1 = "kneaddata_out/~{basename(input_file_r1, '.fq.gz')}_kneaddata_paired_1.fastq"
        File output_paired_2 = "kneaddata_out/~{basename(input_file_r1, '.fq.gz')}_kneaddata_paired_2.fastq"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_61de51c7c6c94844b47e7ea1d7b8830e_private:latest"
        req_cpu: 4
        req_mem: "4GB"
    }
}


# 分类学分类 taxonomic classification
task Kraken2Task {
    input {
        File input_file_r1
        File input_file_r2
        Array[File] kraken2_db_files
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
        String output_basename
    }

    # 定义输出文件路径变量
    String output_tsv_name = output_basename + ".kraken_tsv"
    String report_txt_name = output_basename + ".kraken_report"

    command <<<
        mkdir -p kraken2_db
        for db_file in ~{sep=' ' kraken2_db_files}; do
            ln -sf ${db_file} kraken2_db/
        done

        kraken2 --db kraken2_db \
        --threads ~{threads} \
        --confidence ~{confidence} \
        --minimum-base-quality ~{min_base_quality} \
        --minimum-hit-groups ~{min_hit_groups} \
        --output ~{output_tsv_name} \
        --report ~{report_txt_name} \
        --paired ~{input_file_r1} ~{input_file_r2} \
        --use-names --memory-mapping
    >>>

    output {
        File output_tsv_file = output_tsv_name
        File report_txt_file = report_txt_name
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_6c85305847034eadb18c77824949bcc6_private:latest"
        req_cpu: 4
        req_mem: "4GB"
    }
}

# 合并 Kraken2 的 TSV 输出文件，并去除重复行
task MergeTSVTask {
    input {
        Array[File] input_files
    }

    command {
        cat ${sep=" " input_files} | awk '!seen[$0]++' > merged_taxonomy.tsv
    }

    output {
        File merged_tsv = "merged_taxonomy.tsv"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_a185cfae5f194b339ad0cc511cc46eeb_private:latest"
        req_cpu: 1
        req_mem: "1G"
    }
}

# 生成 BIOM 文件
task kraken_biom {
    input {
        Array[File] input_files
        String output_filename
    }

    command {
        kraken-biom ${sep=" " input_files} --fmt hdf5 -o ${output_filename}
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_5adecffec5fc45f0980a2a9b7ba0b607_private:latest"
        req_cpu: 1
        req_mem: "1G"
    }

    output {
        File output_biom = "${output_filename}"
    }
}

# 生成分类学数据的可视化图表
task krona {
    input {
        File input_file
        String output_basename
    }

    # 定义输出文件路径变量
    String output_filename = output_basename + ".kraken_report.html"

    command {
        ktImportTaxonomy \
        -o ${output_filename} \
        ${input_file}
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_209cb871c67c4cb3996ac80e426f45c6_private:latest"        
        req_cpu: 2
        req_mem: "2G"
    }

    output {
        File output_html = "${output_filename}"
    }
}

# 将 Kraken2 的 TSV 文件转换为 QIIME2 兼容的格式
task ConvertKraken2Tsv {
    input {
        File qiime2_merged_taxonomy_tsv
        File taxonomy_convert_script
    }

    command <<<
        python3 ~{taxonomy_convert_script} ~{qiime2_merged_taxonomy_tsv} merge_converted_taxonomy.tsv
    >>>

    output {
        File merge_converted_taxonomy = "merge_converted_taxonomy.tsv"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_41343869128b4502a4801b3f5078e89e_private:latest"
        req_cpu: 1
        req_mem: "1G"
    }
}

# 导入特征表数据
task ImportFeatureTable {
    input {
        File input_biom
    }

    command {
        qiime tools import \
        --type 'FeatureTable[Frequency]' \
        --input-path ${input_biom} \
        --output-path feature-table.qza
    }

    output {
        File output_qza = "feature-table.qza"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}

# 导入分类学数据
task ImportTaxonomy {
    input {
        File input_tsv
    }

    command {
        qiime tools import \
        --type 'FeatureData[Taxonomy]' \
        --input-format HeaderlessTSVTaxonomyFormat \
        --input-path ${input_tsv} \
        --output-path taxonomy.qza
    }

    output {
        File output_qza = "taxonomy.qza"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}

# 过滤掉在样本中出现频率较低的特征
task FilterRareFeatures {
    input {
        File input_table
        Int qiime2_min_samples
    }

    command {
        qiime feature-table filter-features \
        --i-table ${input_table} \
        --p-min-samples ${qiime2_min_samples} \
        --o-filtered-table filtered-table.qza
    }

    output {
        File filtered_table = "filtered-table.qza"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}



# 计算 Chao1 指数
task CalculateChao1Diversity {
    input {
        File input_table
    }

    command <<<
        qiime diversity alpha \
        --i-table ~{input_table} \
        --p-metric chao1 \
        --o-alpha-diversity chao1_diversity.qza
    >>>

    output {
        File chao1_diversity = "chao1_diversity.qza"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 1
        req_mem: "1G"
    }
}

# 导出 Chao1 指数
task ExportChao1Diversity {
    input {
        File chao1_diversity
    }

    command <<<
        qiime tools export \
        --input-path ~{chao1_diversity} \
        --output-path exported_chao1_diversity

        mv exported_chao1_diversity/alpha-diversity.tsv exported_chao1_diversity/chao1-diversity.tsv
    >>>

    output {
        File exported_chao1_diversity = "exported_chao1_diversity/chao1-diversity.tsv"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 1
        req_mem: "1G"
    }
}

# 计算输入表的beta多样性（Bray-Curtis 距离矩阵）
task CalculateBetaDiversity {
    input {
        File input_table
    }

    command {
        qiime diversity beta \
        --i-table ${input_table} \
        --p-metric braycurtis \
        --o-distance-matrix distance-matrix.qza
    }

    output {
        File distance_matrix = "distance-matrix.qza"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}

# 对输入的距离矩阵文件执行主坐标分析(PCoA)，并进行可视化
task PerformAndVisualizePCoA {
    input {
        File distance_matrix
        File metadata
    }

    command {
        # 执行主坐标分析（PCoA）
        qiime diversity pcoa \
        --i-distance-matrix ${distance_matrix} \
        --o-pcoa pcoa.qza

        # 使用QIIME 2的Emperor工具对PCoA结果进行可视化
        qiime emperor plot \
        --i-pcoa pcoa.qza \
        --m-metadata-file ${metadata} \
        --o-visualization pcoa.qzv

        # 导出可视化文件为通用图像格式
        mkdir -p pcoa
        qiime tools export \
        --input-path pcoa-visualization.qzv \
        --output-path pcoa

        # 打包所有导出的文件
        tar -czvf pcoa.tar.gz pcoa
    }

    output {
        # File pcoa = "pcoa.qza"
        File visualization = "pcoa.qzv"
        File exported_files = "pcoa.tar.gz"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}

# 输入表添加伪计数
task AddPseudocount {
    input {
        File input_table
    }

    command {
        qiime composition add-pseudocount \
        --i-table ${input_table} \
        --o-composition-table comp-table.qza
    }

    output {
        File comp_table = "comp-table.qza"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}

# 增加热图的计算
task GenerateHeatmap {
    input {
        File input_table
        File metadata
    }

    command <<<
        # 生成热图
        qiime feature-table heatmap \
        --i-table ~{input_table} \
        --m-sample-metadata-file ~{metadata} \
        --m-sample-metadata-column treatment \
        --o-visualization feature-table-heatmap.qzv

        # 导出可视化文件为通用图像格式
        mkdir -p feature-table-heatmap
        qiime tools export \
        --input-path feature-table-heatmap.qzv \
        --output-path feature-table-heatmap

        # 打包所有导出的文件
        tar -czvf feature-table-heatmap.tar.gz feature-table-heatmap
    >>>

    output {
        File heatmap_visualization = "feature-table-heatmap.qzv"
        File exported_files = "feature-table-heatmap.tar.gz"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}

# 生成 Alpha 多样性指数的箱线图
task AlphaDiversityBoxPlot {
    input {
        File chao1_diversity
        File metadata
    }

    command <<<
        qiime diversity alpha-group-significance \
        --i-alpha-diversity ~{chao1_diversity} \
        --m-metadata-file ~{metadata} \
        --o-visualization alpha-group-significance.qzv

        mkdir -p alpha_group_significance
        qiime tools export \
        --input-path alpha-group-significance.qzv \
        --output-path alpha_group_significance

        # 打包所有导出的文件
        tar -czvf alpha_group_significance.tar.gz alpha_group_significance
    >>>

    output {
        File alpha_group_significance_visualization = "alpha-group-significance.qzv"
        File exported_files = "alpha_group_significance.tar.gz"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_8cae64f3b5b346db85bc9976cbd51bf8_private:latest"
        req_cpu: 4
        req_mem: "4G"
    }
}