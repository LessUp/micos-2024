version 1.0
task merge {
    input {
        Array[File] fq1_files
        Array[File] fq2_files
        String sampleid
    }
    command {
        touch ${sampleid}.1.fq.gz
        for file in ${sep=" " fq1_files}
        do
            cat $file >> ${sampleid}.1.fq.gz
        done
        touch ${sampleid}.2.fq.gz
        for file in ${sep=" " fq2_files}
        do
            cat $file >> ${sampleid}.2.fq.gz
        done
    }
    output {
        File fq1 = "${sampleid}.1.fq.gz"
        File fq2 = "${sampleid}.2.fq.gz"
    }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_e2466877f08f4e50af16875413763fe0_private:latest"
        req_cpu:4
        req_memory:"4Gi"
    }
}
task trimming{
    input {
        File fq1
        File fq2
        String sampleid
        Int? min_len=30
        String? ad_r1="AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA"
        String? ad_r2="AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG"
    }
    command {
    fastp -i ${fq1} -I ${fq2} -o "${sampleid}.trimmming.1.fq.gz" -O "${sampleid}.trimmming.2.fq.gz" -w 4 --length_required ${min_len} --adapter_sequence=${ad_r1} --adapter_sequence_r2=${ad_r2} -j "${sampleid}.fastp.json" -h "${sampleid}.fastp.html" 2> "${sampleid}.fastp.log"
    }
    output {
        File fastp_json = "${sampleid}.fastp.json"
        File fastp_html = "${sampleid}.fastp.html"
        File fastp_log = "${sampleid}.fastp.log"
        File trimming1 = "${sampleid}.trimmming.1.fq.gz"
        File trimming2 = "${sampleid}.trimmming.2.fq.gz"
  }
    runtime {
    docker_url: "stereonote_hpc_external/chenjunhong_e2466877f08f4e50af16875413763fe0_private:latest"
    req_cpu:4
    req_memory:"4Gi"
  }
}

task bowtie {
    input {
        String sampleid
        File trimming1
        File trimming2
        String? bowtie2_index="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/Metagenomics/history_data/P18Z10200N0127/LXM/chenjunhong/workdir/MP4/metaphlan_databases/bowtie2_index/hg38full"
    }
    command {
        bowtie2 --end-to-end --very-sensitive -p 4 -x ${bowtie2_index} -1 "${trimming1}" -2 "${trimming2}" 2> "${sampleid}.rmhost.log" | samtools fastq -N -c 5 -f 12 --threads 4 -1 "${sampleid}.rmhost.1.fq.gz" -2 "${sampleid}.rmhost.2.fq.gz" -
    }
    output {
        File rmhost_log = "${sampleid}.rmhost.log"
        File rmhost1 = "${sampleid}.rmhost.1.fq.gz"
        File rmhost2 = "${sampleid}.rmhost.2.fq.gz"
    }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_56465bc053a8438281e79492306a708a_private:latest"
        req_cpu:4
        req_memory:"4Gi"
    }
}

task metaphlan4_1 {
    input {
        File rmhost1
        File rmhost2
        String sampleid
        String? bowtie2db="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/Metagenomics/history_data/P18Z10200N0127/LXM/chenjunhong/workdir/MP4/metaphlan_databases"
        String? index="mpa_vOct22_CHOCOPhlAnSGB_202212"
    }
    command {
        export PATH="/opt/conda/bin:$PATH"
        metaphlan ${rmhost1},${rmhost2} --bowtie2db ${bowtie2db} --index ${index} --nproc 4 --input_type fastq -s "${sampleid}.sam.bz2" --bowtie2out "${sampleid}.mp4.bw2.bz2" -t rel_ab_w_read_stats > "${sampleid}.mp4.profile"
    }
    output {
        File sam = "${sampleid}.sam.bz2"
        File bw2 = "${sampleid}.mp4.bw2.bz2"
        File profile1 = "${sampleid}.mp4.profile"
  }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_9902181e90704e7a852bc20b16954b05_private:latest"
        req_cpu:4
        req_memory:"20Gi"
  }
}

task metaphlan4_2 {
    input {
        File sam
        File bw2
        String sampleid
        String? bowtie2db="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/Metagenomics/history_data/P18Z10200N0127/LXM/chenjunhong/workdir/MP4/metaphlan_databases"
        String? index="mpa_vOct22_CHOCOPhlAnSGB_202212"
    }
    command {
        export PATH="/opt/conda/bin:$PATH"
        /opt/conda/bin/sample2markers.py -i ${sam}  -d ${bowtie2db}  -o ./ -n 4
        metaphlan ${bw2} --bowtie2db ${bowtie2db} --index ${index} --nproc 4 --input_type bowtie2out --unclassified_estimation > "${sampleid}.mp4.unclassified.profile"
    }
    output {
        File profile2 = "${sampleid}.mp4.unclassified.profile"
        File strain = "${sampleid}.pkl"
  }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_9902181e90704e7a852bc20b16954b05_private:latest"
        req_cpu:4
        req_memory:"20Gi"
  }

}

workflow main{
    input {
        Array[File] Fq1_files
        Array[File] Fq2_files
        String Sampleid
        Int? Min_len=30
        String? Ad_r1="AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA"
        String? Ad_r2="AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG"
        String? Bowtie2_index="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/Metagenomics/history_data/P18Z10200N0127/LXM/chenjunhong/workdir/MP4/metaphlan_databases/bowtie2_index/hg38full"
        String? Bowtie2db="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/Metagenomics/history_data/P18Z10200N0127/LXM/chenjunhong/workdir/MP4/metaphlan_databases"
        String? Index="mpa_vOct22_CHOCOPhlAnSGB_202212"
    }
    
    if(length(Fq1_files) > 1){
        call merge {
            input:
                fq1_files=Fq1_files,
                fq2_files=Fq2_files,
                sampleid=Sampleid
        }
    }
    File fq1_input = select_first([merge.fq1, Fq1_files[0]])
    File fq2_input = select_first([merge.fq2, Fq2_files[0]])
    call trimming {
        input:
            fq1=fq1_input,
            fq2=fq2_input,
            sampleid=Sampleid,
            min_len=Min_len,
            ad_r1=Ad_r1,
            ad_r2=Ad_r2,
        }
    
    call bowtie {
        input:
            sampleid=Sampleid,
            trimming1=trimming.trimming1,
            trimming2=trimming.trimming2,
            bowtie2_index=Bowtie2_index
    }

    call metaphlan4_1 {
        input:
            sampleid=Sampleid,
            rmhost1=bowtie.rmhost1,
            rmhost2=bowtie.rmhost2,
            bowtie2db=Bowtie2db,
            index=Index
    }

    call metaphlan4_2 {
        input:
            sampleid=Sampleid,
            bowtie2db=Bowtie2db,
            index=Index,
            sam=metaphlan4_1.sam,
            bw2=metaphlan4_1.bw2
    }

    output {
        File out1=trimming.fastp_json
        File out2=trimming.fastp_html
        File out3=trimming.fastp_log
        File out4=bowtie.rmhost1
        File out5=bowtie.rmhost2
        File out6=bowtie.rmhost_log
        File out7=metaphlan4_1.profile1
        File out8=metaphlan4_2.profile2
        File out9=metaphlan4_2.strain
        File out10=metaphlan4_1.bw2
    }
}