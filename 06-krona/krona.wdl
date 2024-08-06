version 1.0

task krona {
    input {
        File input_file
        String output_filename
    }

    command {
        ktImportTaxonomy \
        -o ${output_filename} \
        ${input_file}
    }

    runtime {
        docker: "shuai/krona:2.8.1"
        cpu: 1
        memory: "4 GB"
    }

    output {
        File output_html = "${output_filename}"
    }
}

workflow krona_workflow {
    input {
        Array[File] input_reports
        Array[String] output_html_names
    }

    scatter (idx in range(length(input_reports))) {
        call krona {
            input:
                input_file = input_reports[idx],
                output_filename = output_html_names[idx]
        }
    }

    output {
        Array[File] krona_html_reports = krona.output_html
    }
}