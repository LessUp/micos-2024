version 1.0

workflow metagenomic_analysis_workflow {
    input {
        # KneadData inputs
        Array[File] input_files_r1
        Array[File] input_files_r2
        Array[File] kneaddata_db_files
        Int kneaddata_threads

        # Kraken2
        Array[File] kraken2_db_files
        Int kraken_threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups

        # Krona
        Array[String] krona_output_html_names
        Array[String] output_tsv_names
        Array[String] report_txt_names

        # Qiime2
        File metadata
        Int qiime2_min_frequency = 1
        Int qiime2_min_samples = 1
        Int qiime2_sampling_depth = 1
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
                output_tsv_name = output_tsv_names[i],
                report_txt_name = report_txt_names[i]
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
                output_filename = krona_output_html_names[idx]
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

    call FilterLowAbundanceFeatures {
        input:
            input_table = ImportFeatureTable.output_qza,
            qiime2_min_frequency = qiime2_min_frequency
    }

    call FilterRareFeatures {
        input:
            input_table = FilterLowAbundanceFeatures.filtered_table,
            qiime2_min_samples = qiime2_min_samples
    }

    call RarefyTable {
        input:
            input_table = FilterRareFeatures.filtered_table,
            qiime2_sampling_depth = qiime2_sampling_depth
    }

    call CalculateAndExportAlphaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    # 计算Alpha指数的箱线图
    call AlphaDiversityBoxPlot {
        input:
            shannon_diversity = CalculateAndExportAlphaDiversity.shannon_diversity,
            metadata = metadata
    }

    call CalculateAndExportChao1Diversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    call CalculateBetaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    call PerformAndVisualizePCoA {
        input:
            distance_matrix = CalculateBetaDiversity.distance_matrix,
            metadata = metadata
    }

    call AddPseudocount {
        input:
            input_table = RarefyTable.rarefied_table
    }

    # 计算热图
    call GenerateHeatmap {
        input:
            input_table = ImportFeatureTable.output_qza,
            metadata = metadata
    }

    output {
        Array[File] kneaddata_paired_1 = KneadDataTask.output_paired_1
        Array[File] kneaddata_paired_2 = KneadDataTask.output_paired_2
        File merged_tsv = MergeTSVTask.merged_tsv
        File convert_csv = ConvertKraken2Tsv.merge_converted_taxonomy
        Array[File] kraken2_report_txt = Kraken2Task.report_txt_file
        File output_biom = kraken_biom.output_biom
        Array[File] krona_html_reports = krona.output_html
        File filtered_table = FilterRareFeatures.filtered_table
        File rarefied_table = RarefyTable.rarefied_table
        File distance_matrix = CalculateBetaDiversity.distance_matrix
        File pcoa_qzv = PerformAndVisualizePCoA.visualization
        Array[File] pcoa_exports = PerformAndVisualizePCoA.exported_files
        File comp_table = AddPseudocount.comp_table
        File shannon_diversity = CalculateAndExportAlphaDiversity.exported_shannon_diversity
        File chao1_diversity = CalculateAndExportChao1Diversity.exported_chao1_diversity
        File heatmap_visualization = GenerateHeatmap.heatmap_visualization
        Array[File] heatmap_exported_files = GenerateHeatmap.exported_files
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
        docker: "shuai/kneaddata:0.12.0.2"
        cpu: 16
        memory: "32 GB"
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
        String output_tsv_name
        String report_txt_name
    }


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
        docker: "shuai/kraken2:2.1.3"
        cpu: 16
        memory: "32 GB"
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
        docker: "ubuntu:20.04"
        cpu: 1
        memory: "1 GB"
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
        docker: "shuai/kraken-biom:1.0.0"
        cpu: 16
        memory: "32 GB"
    }

    output {
        File output_biom = "${output_filename}"
    }
}

# 生成分类学数据的可视化图表
task krona {
    input {
        File input_file
        String output_filename
    }

    command {
        ktImportTaxonomy \
        -o ${output_filename} \
        ${input_file}
    }

    runtime {
        docker: "shuai/krona:2.8.1"
        cpu: 16
        memory: "32 GB"
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
        docker: "amancevice/pandas:1.1.5"
        cpu: 16
        memory: "32 GB"
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
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
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
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
    }
}

# 过滤掉丰度较低的特征
task FilterLowAbundanceFeatures {
    input {
        File input_table
        Int qiime2_min_frequency
    }

    command {
        qiime feature-table filter-features \
        --i-table ${input_table} \
        --p-min-frequency ${qiime2_min_frequency} \
        --o-filtered-table filtered-table.qza
    }

    output {
        File filtered_table = "filtered-table.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
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
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
    }
}

# 这个任务使用 QIIME2 工具对输入表进行稀释
task RarefyTable {
    input {
        File input_table
        Int qiime2_sampling_depth
    }

    command {
        qiime feature-table rarefy \
        --i-table ${input_table} \
        --p-sampling-depth ${qiime2_sampling_depth} \
        --o-rarefied-table rarefied-table.qza
    }

    output {
        File rarefied_table = input_table
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
    }
}

# 计算和导出 Alpha 多样性（Shannon 指数）
task CalculateAndExportAlphaDiversity {
    input {
        File input_table
    }

    command {
        qiime diversity alpha \
        --i-table ${input_table} \
        --p-metric shannon \
        --o-alpha-diversity shannon_diversity.qza

        qiime tools export \
        --input-path shannon_diversity.qza \
        --output-path exported_shannon_diversity
    }

    output {
        File shannon_diversity = "shannon_diversity.qza"
        File exported_shannon_diversity = "exported_shannon_diversity/alpha-diversity.tsv"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
    }
}

# 计算和导出 Alpha 多样性（Chao1 指数）
task CalculateAndExportChao1Diversity {
    input {
        File input_table
    }

    command {
        qiime diversity alpha \
        --i-table ${input_table} \
        --p-metric chao1 \
        --o-alpha-diversity chao1-diversity.qza

        qiime tools export \
        --input-path chao1-diversity.qza \
        --output-path exported-chao1-diversity
    }

    output {
        File exported_chao1_diversity = "exported-chao1-diversity/alpha-diversity.tsv"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
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
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
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
        --o-visualization pcoa-visualization.qzv

        # 导出可视化文件为通用图像格式
        mkdir -p exported_visualization
        qiime tools export \
        --input-path pcoa-visualization.qzv \
        --output-path exported_visualization
    }

    output {
        # File pcoa = "pcoa.qza"
        File visualization = "pcoa-visualization.qzv"
        Array[File] exported_files = glob("exported_visualization/**/*")
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
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
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
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
        mkdir -p exported_heatmap
        qiime tools export \
        --input-path feature-table-heatmap.qzv \
        --output-path exported_heatmap
    >>>

    output {
        File heatmap_visualization = "feature-table-heatmap.qzv"
        Array[File] exported_files = glob("exported_heatmap/**/*")
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
    }
}

# 生成 Alpha 多样性指数的箱线图
task AlphaDiversityBoxPlot {
    input {
        File shannon_diversity
        File metadata
    }

    command {
        qiime diversity alpha-group-significance \
        --i-alpha-diversity ${shannon_diversity} \
        --m-metadata-file ${metadata} \
        --o-visualization alpha-group-significance.qzv

        mkdir -p exported_alpha_group_significance
        qiime tools export \
        --input-path alpha-group-significance.qzv \
        --output-path exported_alpha_group_significance
    }

    output {
        File alpha_group_significance_visualization = "alpha-group-significance.qzv"
        Array[File] exported_files = glob("exported_alpha_group_significance/**/*")
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 16
        memory: "32 GB"
    }
}