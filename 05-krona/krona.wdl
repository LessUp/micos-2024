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
        cpu: 4
        memory: "4 GB"
    }

    output {
        File output_html = "${output_filename}"
    }
}

workflow krona_workflow {
    input {
        File input_report
        String output_html = "krona_report.html"
    }

    call krona {
        input:
            input_file = input_report,
            output_filename = output_html
    }

    output {
        File krona_html = krona.output_html
    }
}