version development

workflow combined_kraken_workflow {
    input {
        Array[File] input_files_r1
        Array[File] input_files_r2
        Directory kraken2_db
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
        Array[String] output_tsv_names
        Array[String] report_txt_names
        String biom_output_filename
    }

    scatter (i in range(length(input_files_r1))) {
        call Kraken2Task {
            input:
                input_file_r1 = input_files_r1[i],
                input_file_r2 = input_files_r2[i],
                kraken2_db = kraken2_db,
                threads = threads,
                confidence = confidence,
                min_base_quality = min_base_quality,
                min_hit_groups = min_hit_groups,
                output_tsv_name = output_tsv_names[i],
                report_txt_name = report_txt_names[i]
        }
    }

    call kraken_biom {
        input:
            input_files = Kraken2Task.report_txt_file,
            output_filename = biom_output_filename
    }

    output {
        Array[File] kraken2_output_tsv = Kraken2Task.output_tsv_file
        Array[File] kraken2_report_txt = Kraken2Task.report_txt_file
        File output_biom = kraken_biom.output_biom
    }
}

task Kraken2Task {
    input {
        File input_file_r1
        File input_file_r2
        Directory kraken2_db
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
        String output_tsv_name
        String report_txt_name
    }

    command {
        kraken2 --db ${kraken2_db} \
                --threads ${threads} \
                --confidence ${confidence} \
                --minimum-base-quality ${min_base_quality} \
                --minimum-hit-groups ${min_hit_groups} \
                --output ${output_tsv_name} \
                --report ${report_txt_name} \
                --paired ${input_file_r1} ${input_file_r2} \
                --use-names --memory-mapping
    }

    output {
        File output_tsv_file = output_tsv_name
        File report_txt_file = report_txt_name
    }

    runtime {
        docker: "shuai/kraken2:2.1.3"
    }
}

task kraken_biom {
    input {
        Array[File] input_files
        String output_filename
    }

    command {
        kraken-biom ${sep=" " input_files} --fmt json -o ${output_filename}
    }

    runtime {
        docker: "shuai/kraken-biom:1.0.0"
        memory: "4 GB"
        cpu: 1
    }

    output {
        File output_biom = "${output_filename}"
    }
}