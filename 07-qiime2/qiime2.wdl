version 1.0

workflow Qiime2Analysis {
    input {
        File metagenome_biom
        File merged_taxonomy
        File sample_metadata
        Int min_frequency = 10
        Int min_samples = 2
        Int sampling_depth = 10
    }

    call ImportFeatureTable {
        input:
            input_biom = metagenome_biom
    }

    call ImportTaxonomy {
        input:
            input_tsv = merged_taxonomy
    }

    call FilterLowAbundanceFeatures {
        input:
            input_table = ImportFeatureTable.output_qza,
            min_frequency = min_frequency
    }

    call FilterRareFeatures {
        input:
            input_table = FilterLowAbundanceFeatures.filtered_table,
            min_samples = min_samples
    }

    call RarefyTable {
        input:
            input_table = FilterRareFeatures.filtered_table,
            sampling_depth = sampling_depth
    }

    call CalculateAlphaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    call ExportAlphaDiversity {
        input:
            input_qza = CalculateAlphaDiversity.alpha_diversity
    }

    call CalculateBetaDiversity {
        input:
            input_table = RarefyTable.rarefied_table
    }

    call PerformPCoA {
        input:
            distance_matrix = CalculateBetaDiversity.distance_matrix
    }

    call VisualizeEmperor {
        input:
            pcoa_qza = PerformPCoA.pcoa,
            metadata = sample_metadata
    }

    call AddPseudocount {
        input:
            input_table = FilterRareFeatures.filtered_table
    }

    call PerformANCOM {
        input:
            comp_table = AddPseudocount.comp_table,
            metadata = sample_metadata
    }

    output {
        File shannon_diversity = ExportAlphaDiversity.exported_diversity
        File emperor_plot = VisualizeEmperor.emperor_visualization
        File ancom_results = PerformANCOM.ancom_results
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
            --o-filtered-table final-table.qza
    }

    output {
        File filtered_table = "final-table.qza"
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
            --output-path shannon
    }

    output {
        File exported_diversity = "shannon/alpha-diversity.tsv"
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