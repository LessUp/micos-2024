version 1.0

task kraken2_classification {
    input {
        File input_file_r1
        File input_file_r2
        String kraken2_db
        String output_tsv
        String report_txt
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
    }

    command {
        kraken2 --paired \
                --db ${kraken2_db} \
                --output ${output_tsv} \
                --report ${report_txt} \
                --use-names \
                --threads ${threads} \
                --confidence ${confidence} \
                --minimum-base-quality ${min_base_quality} \
                --minimum-hit-groups ${min_hit_groups} \
                --memory-mapping \
                ${input_file_r1} ${input_file_r2}
    }

    output {
        File kraken2_output_tsv = "${output_tsv}"
        File kraken2_report_txt = "${report_txt}"
    }

    runtime {
        docker: "shuai/kraken2:2.1.3"
    }
}

workflow Kraken2Workflow {
    input {
        File input_file_r1
        File input_file_r2
        String kraken2_db
        String output_tsv = "/ResultData/m11213.kraken.tsv"
        String report_txt = "/ResultData/m11213.report.txt"
        Int threads = 16
        Float confidence = 0.1
        Int min_base_quality = 20
        Int min_hit_groups = 2
    }

    call kraken2_classification {
        input:
            input_file_r1 = input_file_r1,
            input_file_r2 = input_file_r2,
            kraken2_db = kraken2_db,
            output_tsv = output_tsv,
            report_txt = report_txt,
            threads = threads,
            confidence = confidence,
            min_base_quality = min_base_quality,
            min_hit_groups = min_hit_groups
    }

    output {
        File final_output_tsv = kraken2_classification.kraken2_output_tsv
        File final_report_txt = kraken2_classification.kraken2_report_txt
    }
}