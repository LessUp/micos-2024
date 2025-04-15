
version development

workflow kneaddata_workflow {
  input {
    Array[File] R1_fastq
    Array[File] R2_fastq
    Directory kneaddata_db
    Int threads = 1
  }

  scatter (pair in zip(R1_fastq, R2_fastq)) {
    call kneaddata_task {
      input:
        R1_fastq = pair.left,
        R2_fastq = pair.right,
        kneaddata_db = kneaddata_db,
        threads = threads
    }
  }

  output {
    Array[Array[File]] raw_output_files = kneaddata_task.output_files
    Array[File] output_files = flatten(kneaddata_task.output_files)
  }
}

task kneaddata_task {
  input {
    File R1_fastq
    File R2_fastq
    Directory kneaddata_db
    Int threads
  }

  command {
    mkdir -p output
    kneaddata \
      -i1 ~{R1_fastq} \
      -i2 ~{R2_fastq} \
      -db ~{kneaddata_db} \
      --output output \
      -t ~{threads}
  }

  output {
    Array[File] output_files = glob("output/*")
  }

  runtime {
    docker: "quay.io/kneaddata:0.12.0"
    cpu: threads
    memory: "16G"
  }
}