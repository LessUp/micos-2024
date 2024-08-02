version development

workflow Kraken2Workflow {
    input {
        File inputFileR1
        File inputFileR2
        Directory kraken2Db
        Int numThreads
        Float confidenceThreshold
        Int minBaseQuality
        Int minHitGroups
        Directory outputDir
        String outputTsvPath
        String reportTxtPath
    }

    call Kraken2Task {
        input:
            inputFileR1 = inputFileR1,
            inputFileR2 = inputFileR2,
            kraken2Db = kraken2Db,
            numThreads = numThreads,
            confidenceThreshold = confidenceThreshold,
            minBaseQuality = minBaseQuality,
            minHitGroups = minHitGroups,
            outputDir = outputDir,
            outputTsvPath = outputTsvPath,
            reportTxtPath = reportTxtPath
    }

    output {
        File kraken2OutputTsv = Kraken2Task.outputTsvFile
        File kraken2ReportTxt = Kraken2Task.reportTxtFile
        File stdoutLog = Kraken2Task.stdoutFile
        File stderrLog = Kraken2Task.stderrFile
    }
}

task Kraken2Task {
    input {
        File inputFileR1
        File inputFileR2
        Directory kraken2Db
        Int numThreads
        Float confidenceThreshold
        Int minBaseQuality
        Int minHitGroups
        Directory outputDir
        String outputTsvPath
        String reportTxtPath
    }

    String outputTsvName = basename(outputTsvPath)
    String reportTxtName = basename(reportTxtPath)

    command <<<
        mkdir -p ~{outputDir}
        kraken2 --db ~{kraken2Db} \
        --threads ~{numThreads} \
        --confidence ~{confidenceThreshold} \
        --minimum-base-quality ~{minBaseQuality} \
        --minimum-hit-groups ~{minHitGroups} \
        --output ~{outputDir}/~{outputTsvName} \
        --report ~{outputDir}/~{reportTxtName} \
        --paired ~{inputFileR1} ~{inputFileR2} \
        --use-names --memory-mapping \
        > >(tee ~{outputDir}/stdout.log) 2> >(tee ~{outputDir}/stderr.log >&2)
    >>>

    output {
        File outputTsvFile = "~{outputDir}/~{outputTsvName}"
        File reportTxtFile = "~{outputDir}/~{reportTxtName}"
        File stdoutFile = "~{outputDir}/stdout.log"
        File stderrFile = "~{outputDir}/stderr.log"
    }

    runtime {
        docker: "shuai/kraken2:2.1.3"
    }
}