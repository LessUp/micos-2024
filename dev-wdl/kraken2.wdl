workflow Kraken2Workflow {
    input {
        File input_file_r1
        File input_file_r2
        Directory kraken2_db  # Changed from String to File
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
        File output_tsv
        File report_txt
    }

    call Kraken2Task {
        input:
            input_file_r1 = input_file_r1,
            input_file_r2 = input_file_r2,
            kraken2_db = kraken2_db,
            threads = threads,
            confidence = confidence,
            min_base_quality = min_base_quality,
            min_hit_groups = min_hit_groups,
            output_tsv = output_tsv,
            report_txt = report_txt
    }

    output {
        File kraken2_output_tsv = Kraken2Task.output_tsv_file
        File kraken2_report_txt = Kraken2Task.report_txt_file
    }
}

task Kraken2Task {
    input {
        File input_file_r1
        File input_file_r2
        Directory kraken2_db  # Changed from String to File
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
        File output_tsv
        File report_txt
    }

    command {
        set -e
        echo "Current directory: $(pwd)"
        echo "Contents of kraken2_db:"
        ls -l ${kraken2_db}
        echo "Checking taxo.k2d:"
        file ${kraken2_db}/taxo.k2d
        kraken2 --db ${kraken2_db} --threads ${threads} \
                --confidence ${confidence} --minimum-base-quality ${min_base_quality} \
                --minimum-hit-groups ${min_hit_groups} \
                --output ${output_tsv} --report ${report_txt} \
                --paired ${input_file_r1} ${input_file_r2} \
                --use-names --memory-mapping
    }

    output {
        File output_tsv_file = "${output_tsv}"
        File report_txt_file = "${report_txt}"
    }

    runtime {
        docker: "shuai/kraken2:2.1.3"
    }
}