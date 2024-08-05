version 1.0

workflow kraken_biom_workflow {
    input {
        Array[File] input_files
        String output_filename
    }

    call kraken_biom {
        input:
            input_files = input_files,
            output_filename = output_filename
    }

    output {
        File output_biom = kraken_biom.output_biom
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