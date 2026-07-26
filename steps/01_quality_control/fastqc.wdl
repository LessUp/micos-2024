version 1.1

workflow fastqc_workflow {
  input {
    Array[File] fastq_files
  }

  scatter (fastq in fastq_files) {
    call fastqc_task {
      input:
        fastq = fastq
    }
  }

  output {
    Array[File] reports = flatten(fastqc_task.reports)
  }
}

task fastqc_task {
  input {
    File fastq
  }

  command {
    fastqc ~{fastq} --outdir=./ > stdout.log 2> stderr.log
  }

  output {
    Array[File] reports = glob("*_fastqc.html")
    File stdout = "stdout.log"
    File stderr = "stderr.log"
  }

  runtime {
    docker: "biocontainers/fastqc:v0.11.9_cv8"
  }
}