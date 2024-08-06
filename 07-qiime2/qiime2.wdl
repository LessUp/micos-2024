version 1.0

# 宏基因组分析工作流使用QIIME2工具进行分析
workflow Qiime2Analysis {
    input {
        # 输入的BIOM格式的宏基因组特征表文件
        File metagenome_biom
        # 输入的合并分类信息文件，TSV格式
        File merged_taxonomy
        # 样本元数据文件，包含样本信息
        File sample_metadata
        # 过滤低丰度特征时的最小频率阈值
        Int min_frequency = 10
        # 过滤稀有特征时的最小样本数阈值
        Int min_samples = 2
        # 稀释深度，用于均匀采样
        Int sampling_depth = 10
    }

    # 导入特征表的任务
    call ImportFeatureTable {
        input:
            input_biom = metagenome_biom
    }

    # 导入分类表的任务
    call ImportTaxonomy {
        input:
            input_tsv = merged_taxonomy
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
            input_table = RarefyTable.rarefied_table
    }

    # 导出Alpha多样性结果为人类可读格式
    call ExportAlphaDiversity {
        input:
            input_qza = CalculateAlphaDiversity.alpha_diversity
    }

    # 计算Beta多样性，衡量样本间的物种差异
    call CalculateBetaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    # 主坐标分析（PCoA），对Beta多样性结果进行降维可视化
    call PerformPCoA {
        input:
            distance_matrix = CalculateBetaDiversity.distance_matrix
    }

    # 使用Emperor进行PCoA结果的可视化
    call VisualizeEmperor {
        input:
            pcoa_qza = PerformPCoA.pcoa,
            metadata = sample_metadata
    }

    # 添加伪计数，以避免零计数对后续统计分析的影响
    call AddPseudocount {
        input:
            input_table = FilterRareFeatures.filtered_table
    }

    # 使用ANCOM进行统计分析，比较不同条件下的物种丰度
    call PerformANCOM {
        input:
            comp_table = AddPseudocount.comp_table,
            metadata = sample_metadata
    }

    output {
        # 过滤后的特征表
        File filtered_table = FilterRareFeatures.filtered_table
        # 稀释后的特征表
        File rarefied_table = RarefyTable.rarefied_table
        # Beta多样性计算生成的距离矩阵
        File distance_matrix = CalculateBetaDiversity.distance_matrix
        # PCoA分析生成的降维结果
        File pcoa = PerformPCoA.pcoa
        # 加伪计数后的特征表
        File comp_table = AddPseudocount.comp_table
        # 导出的Alpha多样性结果
        File shannon_diversity = ExportAlphaDiversity.exported_diversity
        # Emperor可视化结果
        File emperor_plot = VisualizeEmperor.emperor_visualization
        # ANCOM统计分析结果
        File ancom_results = PerformANCOM.ancom_results
    }
}

# 导入分类学表格任务
task ImportFeatureTable {
    input {
        File input_biom
    }

    command {
        qiime tools import \
            --input-path ${input_biom} \
            --type 'FeatureTable[Frequency]' \
            --input-format BIOMV210Format \
            --output-path feature-table.qza
    }

    output {
        File output_qza = "feature-table.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 导入特征表任务
task ImportTaxonomy {
    input {
        File input_tsv
    }

    command {
        qiime tools import \
            --input-path ${input_tsv} \
            --type 'FeatureData[Taxonomy]' \
            --input-format HeaderlessTSVTaxonomyFormat \
            --output-path taxonomy.qza
    }

    output {
        File output_qza = "taxonomy.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 过滤低丰度特征任务
task FilterLowAbundanceFeatures {
    input {
        File input_table
        Int min_frequency
    }

    command {
        qiime feature-table filter-features \
            --i-table ${input_table} \
            --p-min-frequency ${min_frequency} \
            --o-filtered-table filtered-table.qza
    }

    output {
        File filtered_table = "filtered-table.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 过滤稀有特征任务
task FilterRareFeatures {
    input {
        File input_table
        Int min_samples
    }

    command {
        qiime feature-table filter-features \
            --i-table ${input_table} \
            --p-min-samples ${min_samples} \
            --o-filtered-table filtered-table.qza
    }

    output {
        File filtered_table = "filtered-table.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 稀释表格任务
task RarefyTable {
    input {
        File input_table
        Int sampling_depth
    }

    command {
        qiime feature-table rarefy \
            --i-table ${input_table} \
            --p-sampling-depth ${sampling_depth} \
            --o-rarefied-table rarefied-table.qza
    }

    output {
        File rarefied_table = "rarefied-table.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 计算Alpha多样性任务
task CalculateAlphaDiversity {
    input {
        File input_table
    }

    command {
        qiime diversity alpha \
            --i-table ${input_table} \
            --p-metric shannon \
            --o-alpha-diversity shannon.qza
    }

    output {
        File alpha_diversity = "shannon.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 导出Alpha多样性任务
task ExportAlphaDiversity {
    input {
        File input_qza
    }

    command {
        qiime tools export \
            --input-path ${input_qza} \
            --output-path exported_diversity
    }

    output {
        File exported_diversity = "exported_diversity/shannon.tsv"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 计算Beta多样性任务
task CalculateBetaDiversity {
    input {
        File input_table
    }

    command {
        qiime diversity beta \
            --i-table ${input_table} \
            --p-metric braycurtis \
            --o-distance-matrix braycurtis.qza
    }

    output {
        File distance_matrix = "braycurtis.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 执行PCoA任务
task PerformPCoA {
    input {
        File distance_matrix
    }

    command {
        qiime diversity pcoa \
            --i-distance-matrix ${distance_matrix} \
            --o-pcoa pcoa.qza
    }

    output {
        File pcoa = "pcoa.qza"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 生成Emperor图任务
task VisualizeEmperor {
    input {
        File pcoa_qza
        File metadata
    }

    command {
        qiime emperor plot \
            --i-pcoa ${pcoa_qza} \
            --m-metadata-file ${metadata} \
            --o-visualization braycurtis-emperor.qzv
    }

    output {
        File emperor_visualization = "braycurtis-emperor.qzv"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}

# 添加伪计数任务
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
    }
}

# 执行ANCOM分析任务
task PerformANCOM {
    input {
        File comp_table
        File metadata
    }

    command {
        qiime composition ancom \
            --i-table ${comp_table} \
            --m-metadata-file ${metadata} \
            --m-metadata-column treatment \
            --o-visualization ancom-results.qzv
    }

    output {
        File ancom_results = "ancom-results.qzv"
    }

    runtime {
        docker: "quay.io/qiime2/metagenome:2024.5"
    }
}
