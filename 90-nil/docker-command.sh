version 1.0

task quality_control {
    input {
        File input_file
    }

    command {
        # 质控步骤
        quality_control_tool --input ${input_file} --output qc_output.txt
    }

    output {
        File qc_output = "qc_output.txt"
    }

    runtime {
        docker: "quality_control_image:latest"
    }
}

task kraken2_classification {
    input {
        File qc_output
    }

    command {
        # 使用kraken2进行分类
        kraken2 --db kraken2_db --output kraken2_output.txt ${qc_output}
    }

    output {
        File kraken2_output = "kraken2_output.txt"
    }

    runtime {
        docker: "kraken2_image:latest"
    }
}

task kraken2_visualization {
    input {
        File kraken2_output
    }

    command {
        # 对kraken2的结果进行可视化
        kraken2_visualizer --input ${kraken2_output} --output kraken2_visualization.png
    }

    output {
        File kraken2_visualization = "kraken2_visualization.png"
    }

    runtime {
        docker: "kraken2_visualizer_image:latest"
    }
}

task generate_biom {
    input {
        File kraken2_output
    }

    command {
        # 生成BIOM文件
        biom convert -i ${kraken2_output} -o output.biom --to-hdf5
    }

    output {
        File biom_file = "output.biom"
    }

    runtime {
        docker: "biom_image:latest"
    }
}

task qiime_import {
    input {
        File biom_file
    }

    command {
        # QIIME导入特征数据和分类数据
        qiime tools import --input-path ${biom_file} --type 'FeatureTable[Frequency]' --input-format BIOMV210Format --output-path feature_table.qza
    }

    output {
        File feature_table = "feature_table.qza"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task quality_control_denoise {
    input {
        File feature_table
    }

    command {
        # 进行质量控制和去噪
        qiime dada2 denoise-single --i-demultiplexed-seqs ${feature_table} --o-table denoised_table.qza --o-representative-sequences rep_seqs.qza --o-denoising-stats denoising_stats.qza
    }

    output {
        File denoised_table = "denoised_table.qza"
        File rep_seqs = "rep_seqs.qza"
        File denoising_stats = "denoising_stats.qza"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task remove_low_abundance {
    input {
        File denoised_table
    }

    command {
        # 去除低丰度的特征
        qiime feature-table filter-features --i-table ${denoised_table} --p-min-frequency 10 --o-filtered-table filtered_table.qza
    }

    output {
        File filtered_table = "filtered_table.qza"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task remove_rare_taxa {
    input {
        File filtered_table
    }

    command {
        # 去除罕见分类单元
        qiime feature-table filter-features --i-table ${filtered_table} --p-min-samples 5 --o-filtered-table rare_taxa_filtered_table.qza
    }

    output {
        File rare_taxa_filtered_table = "rare_taxa_filtered_table.qza"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task data_normalization {
    input {
        File rare_taxa_filtered_table
    }

    command {
        # 数据标准化 稀疏化
        qiime feature-table rarefy --i-table ${rare_taxa_filtered_table} --p-sampling-depth 1000 --o-rarefied-table rarefied_table.qza
    }

    output {
        File rarefied_table = "rarefied_table.qza"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task alpha_diversity {
    input {
        File rarefied_table
    }

    command {
        # alpha多样性分析, 导出结果并可视化
        qiime diversity alpha --i-table ${rarefied_table} --p-metric shannon --o-alpha-diversity alpha_diversity.qza
        qiime tools export --input-path alpha_diversity.qza --output-path alpha_diversity
    }

    output {
        File alpha_diversity = "alpha_diversity/alpha-diversity.tsv"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task beta_diversity {
    input {
        File rarefied_table
    }

    command {
        # beta多样性，导出结果并可视化
        qiime diversity beta --i-table ${rarefied_table} --p-metric bray_curtis --o-beta-diversity beta_diversity.qza
        qiime tools export --input-path beta_diversity.qza --output-path beta_diversity
    }

    output {
        File beta_diversity = "beta_diversity/distance-matrix.tsv"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

task differential_abundance {
    input {
        File rarefied_table
    }

    command {
        # 差异丰度分析
        qiime composition ancom --i-table ${rarefied_table} --m-metadata-file sample-metadata.tsv --o-visualization ancom.qzv
    }

    output {
        File ancom_visualization = "ancom.qzv"
    }

    runtime {
        docker: "qiime2_image:latest"
    }
}

workflow MetaWorkflow {
    input {
        File input_file
    }

    call quality_control {
        input:
            input_file = input_file
    }

    call kraken2_classification {
        input:
            qc_output = quality_control.qc_output
    }

    call kraken2_visualization {
        input:
            kraken2_output = kraken2_classification.kraken2_output
    }

    call generate_biom {
        input:
            kraken2_output = kraken2_classification.kraken2_output
    }

    call qiime_import {
        input:
            biom_file = generate_biom.biom_file
    }

    call quality_control_denoise {
        input:
            feature_table = qiime_import.feature_table
    }

    call remove_low_abundance {
        input:
            denoised_table = quality_control_denoise.denoised_table
    }

    call remove_rare_taxa {
        input:
            filtered_table = remove_low_abundance.filtered_table
    }

    call data_normalization {
        input:
            rare_taxa_filtered_table = remove_rare_taxa.rare_taxa_filtered_table
    }

    call alpha_diversity {
        input:
            rarefied_table = data_normalization.rarefied_table
    }

    call beta_diversity {
        input:
            rarefied_table = data_normalization.rarefied_table
    }

    call differential_abundance {
        input:
            rarefied_table = data_normalization.rarefied_table
    }

    output {
        File final_alpha_diversity = alpha_diversity.alpha_diversity
        File final_beta_diversity = beta_diversity.beta_diversity
        File final_ancom_visualization = differential_abundance.ancom_visualization
    }
}