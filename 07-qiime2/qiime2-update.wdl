version 1.0

# 宏基因组分析工作流使用QIIME2工具进行分析
workflow Qiime2Analysis {
    input {
        # 输入的BIOM格式的宏基因组特征表文件
        File metagenome_biom
        # 输入的合并分类信息文件，TSV格式
        File merged_taxonomy_tsv
        # 样本元数据文件，包含样本信息
        File sample_metadata
        # 过滤低丰度特征时的最小频率阈值
        Int min_frequency = 10
        # 过滤稀有特征时的最小样本数阈值
        Int min_samples = 2
        # 稀释深度，用于均匀采样
        Int sampling_depth = 10
        # 转换kraken输出tsv脚本
        File taxonomy_convert_script
        # 元数据中的分类信息列名
        String? metadata_category
        # Beta多样性计算的距离度量
        String beta_diversity_metric = "braycurtis"
        # Alpha多样性计算的指标
        String alpha_diversity_metric = "shannon"
        # 是否运行Emperor进行PCoA结果可视化
        Boolean run_emperor = false
        # 是否运行ANCOM进行统计分析
        Boolean run_ancom = false
    }

    # 数据质量控制
    call QualityControl {
        input:
            metagenome_biom = metagenome_biom,
            merged_taxonomy_tsv = merged_taxonomy_tsv,
            sample_metadata = sample_metadata
    }

    if (QualityControl.passed_qc) {
        # 导入特征表的任务
        call ImportFeatureTable {
            input:
                input_biom = metagenome_biom
        }

        # 进行kraken2的tsv转换
        call ConvertKraken2Tsv {
            input:
                merged_taxonomy_tsv = merged_taxonomy_tsv,
                taxonomy_convert_script = taxonomy_convert_script
        }

        # 导入分类表的任务
        call ImportTaxonomy {
            input:
                input_tsv = ConvertKraken2Tsv.merge_converted_taxonomy
        }

        # 过滤低丰度特征，去除可能是噪声的数据
        call FilterLowAbundanceFeatures {
            input:
                input_table = ImportFeatureTable.output_qza,
                min_frequency = min_frequency
        }

        # 过滤稀有特征，去除在较少样本中出现的特征
        call FilterRareFeatures {
            input:
                input_table = FilterLowAbundanceFeatures.filtered_table,
                min_samples = min_samples
        }

        # 稀释特征表，标准化不同样本的序列深度
        call RarefyTable {
            input:
                input_table = FilterRareFeatures.filtered_table,
                sampling_depth = sampling_depth
        }

        # 计算Alpha多样性，衡量单个样本内的物种丰富度
        call CalculateAlphaDiversity {
            input:
                input_table = RarefyTable.rarefied_table,
                metric = alpha_diversity_metric
        }

        # 导出Alpha多样性结果为人类可读格式
        call ExportAlphaDiversity {
            input:
                input_qza = CalculateAlphaDiversity.alpha_diversity,
                metric = alpha_diversity_metric
        }

        # 计算Beta多样性，衡量样本间的物种差异
        call CalculateBetaDiversity {
            input:
                input_table = RarefyTable.rarefied_table,
                metric = beta_diversity_metric
        }

        # 主坐标分析（PCoA），对Beta多样性结果进行降维可视化
        call PerformPCoA {
            input:
                distance_matrix = CalculateBetaDiversity.distance_matrix
        }

        # 使用Emperor进行PCoA结果的可视化
        if (run_emperor) {
            call VisualizeEmperor {
                input:
                    pcoa_qza = PerformPCoA.pcoa,
                    metadata = sample_metadata
            }
        }

        # 添加伪计数，以避免零计数对后续统计分析的影响
        call AddPseudocount {
            input:
                input_table = FilterRareFeatures.filtered_table
        }

        # 使用ANCOM进行统计分析，比较不同条件下的物种丰度
        if (run_ancom && defined(metadata_category)) {
            call PerformANCOM {
                input:
                    comp_table = AddPseudocount.comp_table,
                    metadata = sample_metadata,
                    metadata_column = select_first([metadata_category])
            }
        }

        # 整理输出结果
        call OrganizeOutput {
            input:
                filtered_table = FilterRareFeatures.filtered_table,
                rarefied_table = RarefyTable.rarefied_table,
                distance_matrix = CalculateBetaDiversity.distance_matrix,
                pcoa = PerformPCoA.pcoa,
                comp_table = AddPseudocount.comp_table,
                alpha_diversity = ExportAlphaDiversity.exported_diversity,
                emperor_plot = if run_emperor then VisualizeEmperor.emperor_visualization else None,
                ancom_results = if (run_ancom && defined(metadata_category)) then PerformANCOM.ancom_results else None
        }
    }

    output {
        File? organized_output = OrganizeOutput.output_directory
        File qc_report = QualityControl.qc_report
    }
}

# 数据质量控制任务
task QualityControl {
    input {
        File metagenome_biom
        File merged_taxonomy_tsv
        File sample_metadata
    }

    command <<<
        set -e
        echo "Performing quality control checks..." > qc_report.txt
        
        # 检查文件是否存在且不为空
        for file in ~{metagenome_biom} ~{merged_taxonomy_tsv} ~{sample_metadata}
        do
            if [ ! -s "$file" ]; then
                echo "Error: File $file is empty or does not exist." >> qc_report.txt
                exit 1
            fi
        done

        # 检查BIOM文件格式
        if ! biom validate-table -i ~{metagenome_biom} &>> qc_report.txt; then
            echo "Error: Invalid BIOM file format." >> qc_report.txt
            exit 1
        fi

        # 检查分类文件格式
        if ! awk -F'\t' 'NF != 2 {exit 1}' ~{merged_taxonomy_tsv}; then
            echo "Error: Taxonomy file should have exactly two columns." >> qc_report.txt
            exit 1
        fi

        # 检查元数据文件格式
        if ! awk -F'\t' 'NR==1 {if (NF < 2) exit 1}' ~{sample_metadata}; then
            echo "Error: Metadata file should have at least two columns." >> qc_report.txt
            exit 1
        fi

        echo "All quality control checks passed." >> qc_report.txt
        echo true > passed_qc.txt
    >>>

    output {
        Boolean passed_qc = read_boolean("passed_qc.txt")
        File qc_report = "qc_report.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 1
        memory: "4 GB"
        disks: "local-disk 10 SSD"
    }
}

# Kraken2转换成Qiime2支持的格式
task ConvertKraken2Tsv {
    input {
        File merged_taxonomy_tsv
        File taxonomy_convert_script
    }

    command <<<
        set -e
        python3 ~{taxonomy_convert_script} ~{merged_taxonomy_tsv} merge_converted_taxonomy.tsv
        echo "Kraken2 TSV conversion completed successfully." > conversion_log.txt
    >>>

    output {
        File merge_converted_taxonomy = "merge_converted_taxonomy.tsv"
        File conversion_log = "conversion_log.txt"
    }

    runtime {
        docker: "amancevice/pandas:1.1.5"
        cpu: 1
        memory: "4 GB"
        disks: "local-disk 10 SSD"
    }
}

# 导入特征表任务
task ImportFeatureTable {
    input {
        File input_biom
    }

    command <<<
        set -e
        qiime tools import \
            --input-path ~{input_biom} \
            --type 'FeatureTable[Frequency]' \
            --input-format BIOMV210Format \
            --output-path feature-table.qza
        echo "Feature table imported successfully." > import_log.txt
    >>>

    output {
        File output_qza = "feature-table.qza"
        File import_log = "import_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 导入分类表任务
task ImportTaxonomy {
    input {
        File input_tsv
    }

    command <<<
        set -e
        qiime tools import \
            --input-path ~{input_tsv} \
            --type 'FeatureData[Taxonomy]' \
            --input-format HeaderlessTSVTaxonomyFormat \
            --output-path taxonomy.qza
        echo "Taxonomy imported successfully." > import_log.txt
    >>>

    output {
        File output_qza = "taxonomy.qza"
        File import_log = "import_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 1
        memory: "4 GB"
        disks: "local-disk 10 SSD"
    }
}

# 过滤低丰度特征任务
task FilterLowAbundanceFeatures {
    input {
        File input_table
        Int min_frequency
    }

    command <<<
        set -e
        qiime feature-table filter-features \
            --i-table ~{input_table} \
            --p-min-frequency ~{min_frequency} \
            --o-filtered-table filtered-table.qza
        echo "Low abundance features filtered successfully." > filter_log.txt
    >>>

    output {
        File filtered_table = "filtered-table.qza"
        File filter_log = "filter_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 过滤稀有特征任务
task FilterRareFeatures {
    input {
        File input_table
        Int min_samples
    }

    command <<<
        set -e
        qiime feature-table filter-features \
            --i-table ~{input_table} \
            --p-min-samples ~{min_samples} \
            --o-filtered-table filtered-table.qza
        echo "Rare features filtered successfully." > filter_log.txt
    >>>

    output {
        File filtered_table = "filtered-table.qza"
        File filter_log = "filter_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 稀释表格任务
task RarefyTable {
    input {
        File input_table
        Int sampling_depth
    }

    command <<<
        set -e
        qiime feature-table rarefy \
            --i-table ~{input_table} \
            --p-sampling-depth ~{sampling_depth} \
            --o-rarefied-table rarefied-table.qza
        echo "Table rarefied successfully." > rarefaction_log.txt
    >>>

    output {
        File rarefied_table = "rarefied-table.qza"
        File rarefaction_log = "rarefaction_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 计算Alpha多样性任务
task CalculateAlphaDiversity {
    input {
        File input_table
        String metric
    }

    command <<<
        set -e
        qiime diversity alpha \
            --i-table ~{input_table} \
            --p-metric ~{metric} \
            --o-alpha-diversity alpha_diversity.qza
        echo "Alpha diversity calculated successfully using ~{metric} metric." > alpha_diversity_log.txt
    >>>

    output {
        File alpha_diversity = "alpha_diversity.qza"
        File alpha_diversity_log = "alpha_diversity_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 导出Alpha多样性任务
task ExportAlphaDiversity {
    input {
        File input_qza
        String metric
    }

    command <<<
        set -e
        qiime tools export \
            --input-path ~{input_qza} \
            --output-path exported_diversity
        mv exported_diversity/alpha-diversity.tsv exported_diversity/~{metric}.tsv
        echo "Alpha diversity exported successfully." > export_log.txt
    >>>

    output {
        File exported_diversity = "exported_diversity/~{metric}.tsv"
        File export_log = "export_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 1
        memory: "4 GB"
        disks: "local-disk 10 SSD"
    }
}

# 计算Beta多样性任务
task CalculateBetaDiversity {
    input {
        File input_table
        String metric
    }

    command <<<
        set -e
        qiime diversity beta \
            --i-table ~{input_table} \
            --p-metric ~{metric} \
            --o-distance-matrix distance_matrix.qza
        echo "Beta diversity calculated successfully using ~{metric} metric." > beta_diversity_log.txt
    >>>

    output {
        File distance_matrix = "distance_matrix.qza"
        File beta_diversity_log = "beta_diversity_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 执行PCoA任务
task PerformPCoA {
    input {
        File distance_matrix
    }

    command <<<
        set -e
        qiime diversity pcoa \
            --i-distance-matrix ~{distance_matrix} \
            --o-pcoa pcoa.qza
        echo "PCoA analysis completed successfully." > pcoa_log.txt
    >>>

    output {
        File pcoa = "pcoa.qza"
        File pcoa_log = "pcoa_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 生成Emperor图任务
task VisualizeEmperor {
    input {
        File pcoa_qza
        File metadata
    }

    command <<<
        set -e
        qiime emperor plot \
            --i-pcoa ~{pcoa_qza} \
            --m-metadata-file ~{metadata} \
            --o-visualization emperor-plot.qzv
        echo "Emperor visualization created successfully." > emperor_log.txt
    >>>

    output {
        File emperor_visualization = "emperor-plot.qzv"
        File emperor_log = "emperor_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 添加伪计数任务
task AddPseudocount {
    input {
        File input_table
    }

    command <<<
        set -e
        qiime composition add-pseudocount \
            --i-table ~{input_table} \
            --o-composition-table comp-table.qza
        echo "Pseudocount added successfully." > pseudocount_log.txt
    >>>

    output {
        File comp_table = "comp-table.qza"
        File pseudocount_log = "pseudocount_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 1
        memory: "4 GB"
        disks: "local-disk 10 SSD"
    }
}

# 执行ANCOM分析任务
task PerformANCOM {
    input {
        File comp_table
        File metadata
        String metadata_column
    }

    command <<<
        set -e
        qiime composition ancom \
            --i-table ~{comp_table} \
            --m-metadata-file ~{metadata} \
            --m-metadata-column ~{metadata_column} \
            --o-visualization ancom-results.qzv
        echo "ANCOM analysis completed successfully." > ancom_log.txt
    >>>

    output {
        File ancom_results = "ancom-results.qzv"
        File ancom_log = "ancom_log.txt"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
        cpu: 2
        memory: "8 GB"
        disks: "local-disk 20 SSD"
    }
}

# 整理输出结果任务
task OrganizeOutput {
    input {
        File filtered_table
        File rarefied_table
        File distance_matrix
        File pcoa
        File comp_table
        File alpha_diversity
        File? emperor_plot
        File? ancom_results
    }

    command <<<
        set -e
        mkdir -p output
        cp ~{filtered_table} output/
        cp ~{rarefied_table} output/
        cp ~{distance_matrix} output/
        cp ~{pcoa} output/
        cp ~{comp_table} output/
        cp ~{alpha_diversity} output/
        if [ -f "~{emperor_plot}" ]; then
            cp ~{emperor_plot} output/
        fi
        if [ -f "~{ancom_results}" ]; then
            cp ~{ancom_results} output/
        fi
        echo "Output files organized successfully." > organize_log.txt
        tar -czf output.tar.gz output
    >>>

    output {
        File output_directory = "output.tar.gz"
        File organize_log = "organize_log.txt"
    }

    runtime {
        docker: "ubuntu:20.04"
        cpu: 1
        memory: "2 GB"
        disks: "local-disk 20 SSD"
    }
}