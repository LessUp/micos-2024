version 1.0
workflow Qiime2Analysis {
    input {
        File metagenome_biom       # 输入文件：特征表 (BIOM)
        File merged_taxonomy       # 输入文件：分类学表格
        File sample_metadata       # 输入文件：样本元数据
        Int min_frequency = 10     # 参数：最低特征频率
        Int min_samples = 2        # 参数：最低样本数
        Int sampling_depth = 10    # 参数：采样深度
    }

    # 导入特征表
    call ImportFeatureTable {
        input:
            input_biom = metagenome_biom
    }

    # 导入分类学表格
    call ImportTaxonomy {
        input:
            input_tsv = merged_taxonomy
    }

    # 过滤低丰度特征
    call FilterLowAbundanceFeatures {
        input:
            input_table = ImportFeatureTable.output_qza,
            min_frequency = min_frequency
    }

    # 过滤稀有特征
    call FilterRareFeatures {
        input:
            input_table = FilterLowAbundanceFeatures.filtered_table,
            min_samples = min_samples
    }

    # 稀释表格
    call RarefyTable {
        input:
            input_table = FilterRareFeatures.filtered_table,
            sampling_depth = sampling_depth
    }

    # 计算Alpha多样性
    call CalculateAlphaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    # 导出Alpha多样性
    call ExportAlphaDiversity {
        input:
            input_qza = CalculateAlphaDiversity.alpha_diversity
    }

    # 计算Beta多样性
    call CalculateBetaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    # 执行PCoA
    call PerformPCoA {
        input:
            distance_matrix = CalculateBetaDiversity.distance_matrix
    }

    # 生成Emperor图
    call VisualizeEmperor {
        input:
            pcoa_qza = PerformPCoA.pcoa,
            metadata = sample_metadata
    }

    # 添加伪计数
    call AddPseudocount {
        input:
            input_table = FilterRareFeatures.filtered_table
    }

    # 执行ANCOM分析
    call PerformANCOM {
        input:
            comp_table = AddPseudocount.comp_table,
            metadata = sample_metadata
    }

    output {
        File shannon_diversity = ExportAlphaDiversity.exported_diversity  # Shannon多样性指数
        File emperor_plot = VisualizeEmperor.emperor_visualization        # Emperor可视化图
        File ancom_results = PerformANCOM.ancom_results                   # ANCOM分析结果
    }
}

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
