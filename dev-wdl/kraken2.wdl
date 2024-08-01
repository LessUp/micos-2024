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
        String outputTsvName
        String reportTxtName
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
            outputTsv = "${outputDir}/${outputTsvName}",
            reportTxt = "${outputDir}/${reportTxtName}"
    }

    output {
        File kraken2OutputTsv = Kraken2Task.outputTsvFile
        File kraken2ReportTxt = Kraken2Task.reportTxtFile
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
        String outputTsv
        String reportTxt
    }

    command {
        set -e
        echo "Current directory: $(pwd)"
        echo "Contents of kraken2Db:"
        ls -l ${kraken2Db}
        
        # 创建输出文件
        mkdir -p $(dirname ${outputTsv})
        touch ${outputTsv}
        touch ${reportTxt}
        
        kraken2 --db ${kraken2Db} --threads ${numThreads} \
                --confidence ${confidenceThreshold} --minimum-base-quality ${minBaseQuality} \
                --minimum-hit-groups ${minHitGroups} \
                --output ${outputTsv} --report ${reportTxt} \
                --paired ${inputFileR1} ${inputFileR2} \
                --use-names --memory-mapping \
                > >(tee stdout.log) 2> >(tee stderr.log >&2)
        
        # 检查输出文件是否生成
        echo "Checking output files:"
        ls -l ${outputTsv}
        ls -l ${reportTxt}
    }

    output {
        File outputTsvFile = "${outputTsv}"
        File reportTxtFile = "${reportTxt}"
        File stdoutFile = "stdout.log"
        File stderrFile = "stderr.log"
    }

    runtime {
        docker: "shuai/kraken2:2.1.3"
    }
}