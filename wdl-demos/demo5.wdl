version 1.0

workflow MegaBOLT_WGS{
    input{
        String SampleID
        Array[Array[File]] FASTQ
        #Array[File] fastq1
        #Array[File] fastq2
        String type="full"
        String runtype="WGS"
        String ref_bundle="hg38"
        String adapter="Tn5"
        Int no_bqsr=0
        Int run_genotypegvcfs=1
        Int no_fastq_output=1
        Int no_bam_output_for_alignment=1
        Int no_bam_output_for_sort=1
        Int no_bam_output_for_bqsr=1
        Int bwa=1
        Int hc4=0
        Int stand_call_conf=30
        Int deepvariant=0
        String WGS_mode="PCR"
        Int genotypegvcfs_stand_call_conf=10
        Int bqsr4=0
        Int run_vqsr=0
        Int no_extra_stats=0
        String soapnuke_param="-n 0.1 -q 0.5 -l 12 -T 1"
    }
    Map[String,Map[String,String]] Bundle_Map = {
     "hg38": {
        "resource_tag": "hg38",
        "ref":"/mnt/ssd/MegaBOLT/reference/hg38.fa",
        "resource_dbsnp":"/mnt/ssd/MegaBOLT/reference/NCBI_dbsnp_b151_hg38/All_20180418.vcf.gz",
        "vcf":"/mnt/ssd/MegaBOLT/reference/NCBI_dbsnp_b151_hg38/All_20180418.vcf.gz",
        "resource_omni":"/mnt/ssd/MegaBOLT/reference/1000G_omni2.5.hg38.vcf.gz",
        "resource_mills":"/mnt/ssd/MegaBOLT/reference/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz",
        "resource_1000G":"/mnt/ssd/MegaBOLT/reference/1000G_phase1.snps.high_confidence.hg38.vcf.gz",
        "resource_hapmap":"/mnt/ssd/MegaBOLT/reference/hapmap_3.3.hg38.vcf.gz"
        },
     "hg19": {
        "resource_tag": "hg19",
        "ref":"/mnt/ssd/MegaBOLT/reference/hg19.fa",
        "resource_dbsnp":"/mnt/ssd/MegaBOLT/reference/NCBI_dbsnp_b151_hg19/All_20180423.vcf.gz",
        "vcf":"/mnt/ssd/MegaBOLT/reference/NCBI_dbsnp_b151_hg19/All_20180423.vcf.gz",
        "resource_omni":"/mnt/ssd/MegaBOLT/reference/1000G_omni2.5.hg19.vcf.gz",
        "resource_mills":"/mnt/ssd/MegaBOLT/reference/Mills_and_1000G_gold_standard.indels.hg19.vcf.gz",
        "resource_1000G":"/mnt/ssd/MegaBOLT/reference/1000G_phase1.snps.high_confidence.hg19.vcf.gz",
        "resource_hapmap":"/mnt/ssd/MegaBOLT/reference/hapmap_3.3.hg19.vcf.gz"
        },
    }
    
    Map[String,Array[String]] Adapter_Dict = {
        "Tn5": ["CTGTCTCTTATACACATCTCCGAGCCCACGAGAC","CTGTCTCTTATACACATCTGACGCTGCCGACGAAAGTCGGATCGTAGCCATGTCGTTC"],
        "Ad153": ["AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA","AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG"]
    }
    String Adapter_f= Adapter_Dict[adapter][0]
    String Adapter_r= Adapter_Dict[adapter][1]
    Map[String,String] Bundle = Bundle_Map[ref_bundle]
    String ref=Bundle["ref"]
    String resource_dbsnp=Bundle["resource_dbsnp"]
    String vcf=Bundle["vcf"]
    String resource_omni=Bundle["resource_omni"]
    String resource_mills=Bundle["resource_mills"]
    String resource_1000G=Bundle["resource_1000G"]
    String resource_hapmap=Bundle["resource_hapmap"]
    Array[File] FASTQ_index0=select_all(FASTQ[0])
    Int fqNum=length(FASTQ_index0)
    Boolean whetherPE=if fqNum > 1 then true else false
    Array[File] allFQ=flatten(FASTQ)

    call WGS{
        input:
            # authlog=DirAuth.log,
            sampleid=SampleID,
            allFQ=allFQ,
            Adapter_f=Adapter_f,
            Adapter_r=Adapter_r,
            whetherPE=whetherPE,
            type=type,
            runtype=runtype,
            ref=ref,
            resource_dbsnp=resource_dbsnp,
            vcf=vcf,
            resource_omni=resource_omni,
            resource_mills=resource_mills,
            resource_1000G=resource_1000G,
            resource_hapmap=resource_hapmap,
            no_bqsr=no_bqsr,
            run_genotypegvcfs=run_genotypegvcfs,
            no_fastq_output=no_fastq_output,
            no_bam_output_for_alignment=no_bam_output_for_alignment,
            no_bam_output_for_sort=no_bam_output_for_sort,
            no_bam_output_for_bqsr=no_bam_output_for_bqsr,
            bwa=bwa,
            hc4=hc4,
            stand_call_conf=stand_call_conf,
            deepvariant=deepvariant,
            WGS_mode=WGS_mode,
            genotypegvcfs_stand_call_conf=genotypegvcfs_stand_call_conf,
            bqsr4=bqsr4,
            run_vqsr=run_vqsr,
            no_extra_stats=no_extra_stats,
            soapnuke_param=soapnuke_param
    }

    output {
        File result=WGS.result
    }
}

task WGS{
    input{
        String sampleid
        Array[File] allFQ
        Boolean whetherPE
        String whetherPE1 = if whetherPE then "0" else "1"
        String Adapter_f
        String Adapter_r
        String type="full"
        String runtype="WGS"
        String ref
        String resource_dbsnp
        String vcf
        String resource_omni
        String resource_mills
        String resource_1000G
        String resource_hapmap
        Int no_bqsr
        Int run_genotypegvcfs
        Int no_fastq_output
        Int no_bam_output_for_alignment
        Int no_bam_output_for_sort
        Int no_bam_output_for_bqsr
        Int bwa
        Int hc4
        Int stand_call_conf
        Int deepvariant
        String WGS_mode
        Int genotypegvcfs_stand_call_conf
        Int bqsr4
        Int run_vqsr
        String no_extra_stats
        String soapnuke_param
    }
    command<<<
        set -e
        mkdir -p result
        chmod 777 result
        if [ ~{whetherPE1} = 0 ]; then
        fq1=`echo ~{sep=',' allFQ} | awk -F',' '{OFS=",";for(i=1; i<=NF; i+=2) printf("%s%s", $i, (i<=NF)?OFS:ORS)}'`
        fq2=`echo ~{sep=',' allFQ} | awk -F',' '{OFS=",";for(i=2; i<=NF; i+=2) printf("%s%s", $i, (i<=NF)?OFS:ORS)}'`
        echo ~{sampleid}$'\t'${fq1%?}$'\t'${fq2%?}$'\t'~{Adapter_f}$'\t'~{Adapter_r} > ./sample.list
        else
        echo ~{sampleid}$'\t'~{sep=',' allFQ}$'\t'~{Adapter_f} > ./sample.list
        fi
        /usr/bin/time -v MegaBOLT --list ./sample.list --type ~{type} --runtype ~{runtype} \
~{"--ref " + ref} ~{"--knownSites " + resource_omni} ~{"--knownSites " + resource_mills} ~{"--knownSites " + resource_1000G} ~{"--knownSites " + resource_hapmap} ~{"--resource-dbsnp " + resource_dbsnp} \
        ~{"--resource-omni " + resource_omni} ~{"--resource-mills " + resource_mills} ~{"--resource-1000G " + resource_1000G} ~{"--resource-hapmap " + resource_hapmap} ~{"--vcf " + vcf}  \
        --se ~{whetherPE1} \
        --outputdir ./result \
        --no-bqsr ~{no_bqsr} \
        --run-genotypegvcfs ~{run_genotypegvcfs} \
        --no-fastq-output ~{no_fastq_output} \
        --no-bam-output-for-alignment ~{no_bam_output_for_alignment} \
        --no-bam-output-for-sort ~{no_bam_output_for_sort} \
        --no-bam-output-for-bqsr ~{no_bam_output_for_bqsr} \
        --bwa ~{bwa} \
        --hc4 ~{hc4} \
        --stand-call-conf ~{stand_call_conf} \
        --deepvariant ~{deepvariant} \
        --WGS-mode ~{WGS_mode} \
        --genotypegvcfs-stand-call-conf ~{genotypegvcfs_stand_call_conf} \
        --bqsr4 ~{bqsr4} \
        --run-vqsr ~{run_vqsr} \
        --no-extra-stats ~{no_extra_stats} \
        --soapnuke-param "~{soapnuke_param}" 
        sleep 1s
        resultNum=`find ./result/ -name \* | wc -l`
        if [ $resultNum = 132 ]; then
        echo $resultNum
        else
        echo $resultNum
        exit 1
        fi
        # rm ./result/megabolt.log
        # rm ./result/megabolt.out
        # rm ./result/~{sampleid}/~{sampleid}.log
        # rm ./result/~{sampleid}/~{sampleid}.out
        rm -r ./result/~{sampleid}/stat/bam_stats/merged/
        zero_files=$(find ./result -type f -size 0 | wc -l)
        if [ $zero_files -gt 0 ]; then
            find ./result -type f -size 0
            exit 1
        else
            echo "All files are non-zero"
        fi
        new_gvcf_md5=$(md5sum ./result/~{sampleid}/~{sampleid}.bwa.sortdup.bqsr.hc.g.vcf.gz | awk '{ print $1 }')
        old_gvcf_md5=$(cat ./result/~{sampleid}/stat/vcf_stats/md5sum/~{sampleid}.g.vcf.gz.md5 | awk '{ print $1 }')
        if [ "$new_gvcf_md5" == "$old_gvcf_md5" ]; then
            echo "gvcf file md5sum is correct"
        else
            echo "gvcf file md5sum is incorrect, please check the output file"
            exit 1
        fi
        new_vcf_md5=$(md5sum ./result/~{sampleid}/~{sampleid}.bwa.sortdup.bqsr.hc.genotype.vcf.gz | awk '{ print $1 }')
        old_vcf_md5=$(cat ./result/~{sampleid}/stat/vcf_stats/md5sum/~{sampleid}.vcf.gz.md5 | awk '{ print $1 }')
        if [ "$new_vcf_md5" == "$old_vcf_md5" ]; then
            echo "genotype vcf file md5sum is correct"
        else
            echo "genotype vcf file md5sum is incorrect, please check the output file"
            exit 1
        fi
    >>>
    output{
        File result="./result"
    }
    runtime{
        backend:"SGE"
        cpu:20
        memory:"35 GB"
        maxRetries:1
        job_name:"MegaBOLT-WGS"
    }
}
