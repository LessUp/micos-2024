workflow Kraken2Workflow {
    input {
        File input_file_r1
        File input_file_r2
        String kraken2_db
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
    }
    call Kraken2Task {
        input:
            input_file_r1 = input_file_r1,
            input_file_r2 = input_file_r2,
            kraken2_db = kraken2_db,
            threads = threads,
            confidence = confidence,
            min_base_quality = min_base_quality,
            min_hit_groups = min_hit_groups
    }
    output {
        File output_tsv = Kraken2Task.output_tsv
        File report_txt = Kraken2Task.report_txt
    }
}

task Kraken2Task {
    input {
        File input_file_r1
        File input_file_r2
        String kraken2_db
        Int threads
        Float confidence
        Int min_base_quality
        Int min_hit_groups
    }
    command {
        kraken2 --db ${kraken2_db} --threads ${threads} \
                --confidence ${confidence} --minimum-base-quality ${min_base_quality} \
                --minimum-hit-groups ${min_hit_groups} \
                --output output_tsv --report report_txt \
                --paired ${input_file_r1} ${input_file_r2}
    }
    output {
        File output_tsv = "output_tsv"
        File report_txt = "report_txt"
    }
    runtime {
        docker: "shuai/kraken2:2.1.3"  # 替换为实际的Docker镜像名称
    }
}