version 1.0

workflow RunKraken2Analysis {
    input {
        String fastq1
        String fastq2
        String sampleName
    }

    String kraken2DatabasePath = "/Files/ReferenceData/k2_standard_08gb_20240605.tar.gz"
    String kraken2ReportPath = "/Files/ResultData/Workflow/kraken2_report.txt"

    call PerformKraken2Analysis {
        input:
            databasePath = kraken2DatabasePath,
            fastq1 = fastq1,
            fastq2 = fastq2,
            reportPath = kraken2ReportPath
    }

    output {
        File kraken2Report = PerformKraken2Analysis.kraken2Report
    }
}

task PerformKraken2Analysis {
    input {
        String databasePath
        String fastq1
        String fastq2
        String reportPath
    }

    command {
        kraken2 --db ${databasePath} --output ${reportPath} --minimum-base-quality 30 --threads 8 ${fastq1} ${fastq2}
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_77780bcb8b504a61a96058e5383412d4_private:latest"
        cpu: 8
        memory: "64Gi"
    }

    output {
        File kraken2Report = reportPath
    }
}