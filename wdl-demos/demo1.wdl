version 1.0
workflow Microbiome_pipeline4Stereo_seq {
    input {
        File mask
        String referenceIndex = "human"
        String sn
        Array[Array[File]] fastqs  #total fastq as input
        #Array[File]? fastqs_read2
        Int offset_x
        Int offset_y
        String CIDStart
        String CIDLength
        Int MIDStart
        String MIDLength
        Int SplitNum
        Int binsize = 50
    }

    String sampleid=sn
    String UMIRead="1"
    String kraken2Database = "/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/Singlecell/Reference_Sequencing/P21Z10200N0096/caoshuhuan/k2_standard_20210517"   #only support standard database
    Boolean whetherPE= if length(fastqs[0]) > 1 then true else false
    String Species=referenceIndex
    String indexid=Species
    Int jobn=length(fastqs)

    call RefRead{
        input:
            referenceFile="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/STOmics/Reference_Sequencing/Reference_v1/spatialRNAreference.json",
            sampleid=sn,
            ref=referenceIndex
    }

    String starRef = RefRead.referenceMap[indexid][0]
    String refPath = starRef+"/Genome"
    String genomeFile = refPath
    Float genomeSize = size(genomeFile,"GB")

    if(!whetherPE){
        call SplitBarcodeBin{       #splitMask for SE data
            input:
                barcodeBin=mask,
                sampleid=sn,
                bcPos=if CIDStart=="1" && CIDLength=="24" then "2_25" else "1_24",
                sNum=SplitNum
        }
        call mask2seq_SE{
            input:
                mask=mask,
                sn=sn
        }
    }

    scatter(index in range(jobn)){
        Array[File] DataLine1 = fastqs[index]
        File SEfq = DataLine1[0]
    }
    call GetFQlist{                 #Q4_SE.fq.list
        input:
            sampleid=sn,
            SEfq=SEfq
    }
    Int SEn = GetFQlist.SEn

    Int jobN = if whetherPE then length(fastqs) else SEn

    if(whetherPE){
        call BcNumCountPE{
            input:
                mask=mask,
                species=indexid,
                genomesize=genomeSize
        }
        Float PEmem = BcNumCountPE.mem*1.5
    }


    scatter(index in range(jobN)){
        Array[File] DataLine = fastqs[index]
        File raw_fq1 = if whetherPE then DataLine[0] else GetFQlist.SEfqlist[index]
        File raw_fq2 = if whetherPE then DataLine[1] else "None"
        String base=basename(raw_fq1)
        String slide=if whetherPE then sub(base,"_1\\..*","")+"_"+index else base+"_"+index
        Float fq2Size=160

        if(!whetherPE){
            call BcNumCountSE{
                input:
                    infq=raw_fq1,
                    bindir=SplitBarcodeBin.bindir,
                    sampleid=sn,
                    species=indexid,
                    genomesize=genomeSize
            }
            Float SEmem = BcNumCountSE.mem*1.5
        }
        call BarcodeMappingAndStar{
            input:
                sampleid=sn,
                index=index,
                binfile=if whetherPE then BcNumCountPE.binfile else BcNumCountSE.binfile,
                binfile1=if whetherPE then mask else BcNumCountSE.binfile,
                fqfile=raw_fq1,
                fq2file=if whetherPE then raw_fq2 else "",
                mismatch=1,
                pe=whetherPE,
                fqbase=slide,
                ref=starRef,
                refIndex=indexid,
                umiStart=MIDStart,
                umiLen=MIDLength,
                umiRead=UMIRead,
                barcodeStart=if whetherPE then CIDStart else 0,
                barcodeLen=CIDLength,
                outputBins=if fq2Size>150 then 100 else 50,
            #mem=if whetherPE then PEmem else SEmem,
                bcNum=if whetherPE then BcNumCountPE.bcnum else BcNumCountSE.bcnum
        }
        if(whetherPE){
            call mask2CID_PE{
                input:
                    fqfile=raw_fq1,
                    fq2file=raw_fq2,
                    mask=mask,
                    sn=sn,
                    umiStart=MIDStart,
                    umiLen=MIDLength,
                    umiRead=UMIRead,
                    barcodeStart=if whetherPE then CIDStart else 0,
                    barcodeLen=CIDLength
            }
            call getBarcode_PE{
                input:
                    combinedfq=mask2CID_PE.outfile1,
                    sn=sn
            }
            call unmap_fq as unmap_fq_PE{
                input:
                    align_bam = BarcodeMappingAndStar.bam,
                    sn = sn
                #fqfile = raw_fq1,
                #PE = whetherPE
            }
        }
        if(!whetherPE){
            call mask2CID_SE{
                input:
                    fqfile = raw_fq1,
                    mask2seqfile = select_first([mask2seq_SE.out]),
                    sn=sn
            }
            call unmap_fq as unmap_fq_SE {
                input:
                    align_bam = BarcodeMappingAndStar.bam,
                    sn = sn
                #fqfile = DataLine[0],
                #PE = whetherPE
            }
        }
    }

    if(whetherPE){
        Array[File?] unmap_PEfqs = unmap_fq_PE.out
        call kraken2 as kraken2_PE{
            input:
                unmap_fqs = select_all(unmap_PEfqs),
                sn = sn,
                kraken2Database = kraken2Database
        }
        call kraken2CID as kraken2CID_PE {
            input:
                kraken2tablegz = kraken2_PE.kraken2tablegz,
                sn = sn,
                kraken2reportgz = kraken2_PE.kraken2reportgz
        }
    }
    if(!whetherPE){
        Array[File?] unmap_SEfqs = unmap_fq_SE.out
        call kraken2 as kraken2_SE{
            input:
                unmap_fqs = select_all(unmap_SEfqs),
                sn = sn,
                kraken2Database = kraken2Database
        }
        call kraken2CID as kraken2CID_SE {
            input:
                kraken2tablegz = kraken2_SE.kraken2tablegz,
                sn = sn,
                kraken2reportgz = kraken2_SE.kraken2reportgz
        }
    }

    scatter(index in range(jobN)){
        Array[File] DataLine2 = fastqs[index]
        File raw_Fq1  = if whetherPE then DataLine2[0] else GetFQlist.SEfqlist[index]
        #File raw_Fq2 = if whetherPE then DataLine2[1] else "None"

        if(whetherPE){
            #Array[File?] mask2CID_PEbarcodefiles = mask2CID_PE.outfile1
            Array[File?] getBarcode_PEbarcodefiles = getBarcode_PE.outfile2
            call getUMI as getUMI_PE {
                input:
                    fqfile = raw_Fq1,
                    barcodeinfo = getBarcode_PEbarcodefiles[index],
                    readTax = select_first([kraken2CID_PE.readTax]),
                    PE = whetherPE
            }
        }
        if(!whetherPE){
            Array[File?] mask2CID_SEbarcodefiles = mask2CID_SE.barcodefile
            call getUMI as getUMI_SE {
                input:
                    fqfile = raw_Fq1,
                    barcodeinfo = mask2CID_SEbarcodefiles[index],
                    readTax = select_first([kraken2CID_SE.readTax]),
                    PE = whetherPE
            }
        }
    }

    if(whetherPE){
        Array[File?] kraken2umispe = getUMI_PE.kraken2umi
        call catumi as catumi_PE {
            input :
                kraken2umifiles = select_all(kraken2umispe),
                readTax = select_first([kraken2CID_PE.readTax])
        }
        call kraken2gem as kraken2gem_PE {
            input:
                offset_x = offset_x,
                offset_y = offset_y,
                binsize = binsize,
                kraken2umi = catumi_PE.krakenumi
        }
    }
    if(!whetherPE){
        Array[File?] kraken2umisse = getUMI_SE.kraken2umi
        call catumi as catumi_SE {
            input :
                kraken2umifiles = select_all(kraken2umisse),
                readTax = select_first([kraken2CID_SE.readTax])
        }
        call kraken2gem as kraken2gem_SE {
            input:
                offset_x = offset_x,
                offset_y = offset_y,
                binsize = binsize,
                kraken2umi = catumi_SE.krakenumi
        }
    }
    output {
        Array[File?] out00_mapping_runStat = BarcodeMappingAndStar.bcStat
        File? outkrakenfq = if whetherPE then kraken2_PE.kraken2fqgz else kraken2_SE.kraken2fqgz
        File? outkrakenreport = if whetherPE then kraken2_PE.kraken2reportgz else kraken2_SE.kraken2reportgz
        File? outkrakentable = if whetherPE then kraken2_PE.kraken2tablegz else kraken2_SE.kraken2tablegz
        File? outumi = if whetherPE then catumi_PE.krakenumi else catumi_SE.krakenumi
        File? outgem = if whetherPE then kraken2gem_PE.kraken2gem else kraken2gem_SE.kraken2gem
        Array[File?] outunmapfq = if whetherPE then unmap_fq_PE.out else unmap_fq_SE.out
    }
}

task RefRead{
    input{
        String referenceFile
        String sampleid
        String ref
    }
    command {
        echo "Read reference configure file of ${ref}"
        echo "Workflow Version: Develop"
    }
    output{
        Map[String, Array[String]] referenceMap = read_json("${referenceFile}")
    }
    runtime{
        req_cpu: 1
        req_memory: "1Gi"
        docker_url: "stomics/saw:06.0.2"
    }
}

task GetFQlist{
    input{
        Array[String] SEfq
        String sampleid
        String python="/opt/conda/bin/python3"
    }
    command {
        mkdir -p ./output
        echo "${sep='\n' SEfq}" > ./Total.fastq
        python << CODE
        from collections import defaultdict
        outdict = defaultdict(str)
        with open('./Total.fastq','r') as fi:
        for line in fi:
        fq = line.strip()
        index = str(fq.split('_')[-1].split('.')[0])
        if index in outdict:
        outdict[index] += '\n'+fq
        else:
        outdict[index] = fq
        for key, value in outdict.items():
        with open('./output/${sampleid}_SE_fastq_'+key+'.list','w') as fo:
        fo.write(value+'\n')
        print(len(outdict))
        CODE
    }
    output{
        Array[File] SEfqlist=glob("./output/*.list")
        Int SEn = read_int(stdout())
        File Output = "./output"
    }
    runtime {
        req_cpu: 1
        req_memory: "1Gi"
        docker_url: "stomics/saw:06.0.2"
    }
}

task SplitBarcodeBin{   #splitMask for SE data
    input {
        File barcodeBin
        String sampleid
        String bcPos="1_24"
        Int sNum
    }
    Int threadsNum=if sNum>16 then 16 else sNum
    command {
        export HDF5_USE_FILE_LOCKING=FALSE
        binFileBasename=$(basename ${barcodeBin})
        mkdir -p splitBin
        outDir=`realpath ../../../../`
        barcodeBinDir=`dirname ${barcodeBin}`
        export SINGULARITY_BIND=$barcodeBinDir,$outDir
        splitMask \
        ~{barcodeBin} splitBin/ ~{threadsNum} ~{sNum} ~{bcPos}
    }
    output {
        Array[File] smallBins=glob("./splitBin/*.bin")
        String? bindir=glob("./splitBin/*.bin")[0]
    }
    runtime {
        req_cpu: threadsNum
        req_memory: "20Gi"
        docker_url: "stomics/saw:06.0.2"
    }
}

task BcNumCountSE{
    input {
        File infq
        String? bindir
        String species
        Float genomesize
        String sampleid
    }
    command {
        export HDF5_USE_FILE_LOCKING=FALSE
        outDir=`realpath ../../../../`
        infqDir=`dirname ${infq}`
        export SINGULARITY_BIND=$outDir,$infqDir,~{bindir}
        python3 << CODE
        import os
        fq = "~{infq}"
        bindir = os.path.dirname("${bindir}")
        with open('./CidIndex','w') as fo:
        index = fq.split('_')[-1].split('.')[0]
        if int(index) < 10:
        index = '0'+index
        fo.write(index+'\n')
        fo.write(bindir+'/'+index+'.${sampleid}.barcodeToPos.bin\n')
        fo.write(bindir+'\n')
        CODE
        CidIndex=$(cat ./CidIndex | head -n 1)
        bindir=$(cat ./CidIndex | tail -n 1)
        CIDCount \
        -i $bindir/$CidIndex.${sampleid}.barcodeToPos.bin \
        -s ${species} -g ${genomesize} > './BcNumCount'
    }
    output {
        String? bcnum = read_lines("./BcNumCount")[0]
        Float mem = read_lines("./BcNumCount")[1]
        File? binfile = read_lines("./CidIndex")[1]
    }
    runtime {
        req_cpu: 1
        req_memory: "1Gi"
        docker_url: "stomics/saw:06.0.2"
    }
}

task BcNumCountPE{
    input {
        File mask
        String species
        Float genomesize
    }
    command {
        export HDF5_USE_FILE_LOCKING=FALSE
        outDir=`realpath ../../../../`
        maskDir=`dirname ${mask}`
        export SINGULARITY_BIND=$outDir,$maskDir

        CIDCount \
        -i ~{mask} -s ~{species} -g ~{genomesize} >'./BcNumCount'
    }
    output {
        String? bcnum = read_lines("./BcNumCount")[0]
        Float mem = read_lines("./BcNumCount")[1]
        File? binfile = "~{mask}"
    }
    runtime {
        req_cpu: 1
        req_memory: "1Gi"
        docker_url: "stomics/saw:06.0.2"
    }
}

task BarcodeMappingAndStar{
    input {
        String sampleid
        File? binfile
        String? binfile1
        String fqfile
        String? fq2file
        Int? barcodeStart
        String? umiStart
        String umiLen
        String umiRead
        String barcodeLen
        String ref
        String refIndex
        String fqbase
        String? bcNum

        String index
        Boolean pe=false
        Int mismatch=1
        Int outputBins=50
    }
    command {
        export HDF5_USE_FILE_LOCKING=FALSE
        fastqPath=${fqfile}
        fastqdir=`dirname $fastqPath`
        fq2fileDir=`pwd`
        echo "in=${binfile}" > ~{index}.bcPara
        echo "in1=${fqfile}" >> ~{index}.bcPara
        if [ ~{pe} = true ];then
        echo "in2=${fq2file}" >> ~{index}.bcPara
        echo "encodeRule=ACTG" >> ~{index}.bcPara
        fq2fileDir=`dirname ${fq2file}`
        export SINGULARITY_BIND=fq2fileDir
        fq2size=`stat -c %s ${fq2file}`
        OutputBins=`expr $(( $fq2size / 1073741824 / 500 + 1 )) \* 100`
        else
        for i in `cat ${fqfile}`;do fqd=`dirname $i`,$fqd;done
        OutputBins=${outputBins}
        fi

        echo "out=${sampleid}.bc.out${index}" >> ~{index}.bcPara
        echo "action=4" >> ~{index}.bcPara
        echo "barcodeReadsCount=${index}.barcodeReadsCount.txt" >> ~{index}.bcPara
        echo "platform=T10" >> ~{index}.bcPara
        echo "barcodeStart=${barcodeStart}" >> ~{index}.bcPara
        echo "barcodeLen=${barcodeLen}" >> ~{index}.bcPara
        echo "umiStart=${umiStart}" >> ~{index}.bcPara
        echo "umiLen=${umiLen}" >> ~{index}.bcPara
        echo "umiRead=${umiRead}" >> ~{index}.bcPara
        if [ ~{mismatch} = 1 ];then
        echo "mismatch=${mismatch}" >> ~{index}.bcPara
        fi
        echo "useF14" >> ~{index}.bcPara
        echo "bcNum=${bcNum}" >> ~{index}.bcPara
        echo "polyAnum=15" >> ~{index}.bcPara
        echo "mismatchInPolyA=2" >> ~{index}.bcPara
        echo "rRNAremove" >> ~{index}.bcPara

        outDir=`realpath ../../../../`
        fastqDir=`dirname ${fqfile}`
        binDir=`dirname ${binfile1}`
        refDir=`dirname ${ref}`
        mkdir -p 00.mapping
        mapping \
        --outSAMattributes spatial \
        --outSAMtype BAM Unsorted \
        --genomeDir ${ref} \
        --runThreadN 16 \
        --outFileNamePrefix ~{fqbase}. \
        --limitOutSJcollapsed 10000000 \
        --limitIObufferSize=480000000 \
        --limitBAMsortRAM 63168332971 \
        --outSAMmultNmax 1 \
        --sysShell /bin/bash \
        --stParaFile ~{index}.bcPara \
        --readNameSeparator \" \" \
        --outBAMsortingBinsN $OutputBins \
        --outSAMunmapped Within > ${fqbase}_barcodeMap.stat
        mv ${fqbase}.Aligned.out.bam ${index}.barcodeReadsCount.txt ${fqbase}.Log.final.out ${fqbase}.SJ.out.tab ${index}.bcPara ${fqbase}.Log.out ${fqbase}.Log.progress.out ${fqbase}_barcodeMap.stat ./00.mapping
    }
    output {
        File result="./00.mapping"
        File bam="./00.mapping/~{fqbase}.Aligned.out.bam"    #the output bam name change from Aligned.sortedByCoord.out.bam to Aligned.out.bam because of Unsorted
        File barcodeReadsCount = "./00.mapping/~{index}.barcodeReadsCount.txt"
        File bcStat="./00.mapping/~{fqbase}_barcodeMap.stat"
        File starStat="./00.mapping/~{fqbase}.Log.final.out"
        File starSJ="./00.mapping/~{fqbase}.SJ.out.tab"
        File bcPara="./00.mapping/~{index}.bcPara"
        File fqLog="./00.mapping/~{fqbase}.Log.out"
        File progressLog="./00.mapping/~{fqbase}.Log.progress.out"
    }
    runtime {
        req_cpu: 16
        req_memory: "76Gi"
        docker_url: "stomics/saw:06.0.2"
    }
}

task mask2seq_SE{
    input {
        File mask
        String sn
        #File out
    }
    #String sndir= "/01.Mask/~{sn}" + sn
    command {
        if [ ! -d "./Mask2Seq/~{sn}" ] ;then mkdir -p ./Mask2Seq/~{sn};fi
        export LD_LIBRARY_PATH=/usr/lib64:/opt/conda/lib:/usr/local/lib
        /ST_BarcodeMap/ST_BarcodeMap-0.0.1 --in ~{mask} --out ./Mask2Seq/~{sn}/~{sn}.mask2seq.txt --action 3 --thread 4
        pigz -p 4 ./Mask2Seq/~{sn}/~{sn}.mask2seq.txt
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_1a76a89dc79d4ecc9960fe490b2da149_public:latest"
        req_cpu: 4
        req_memory: "50Gi"
    }
    output {
        File out= "./Mask2Seq/~{sn}/~{sn}.mask2seq.txt.gz"
    }
}

task mask2seq_PE{
    input {
        File mask
        String sn
        String fqfile
        String fq2file
        #File out
    }
    #String sndir= "/01.Mask/~{sn}" + sn
    command {
        if [ ! -d "./Mask2Seq/~{sn}" ] ;then mkdir -p ./Mask2Seq/~{sn};fi
        export LD_LIBRARY_PATH=/usr/lib64:/opt/conda/lib:/usr/local/lib
        /ST_BarcodeMap/ST_BarcodeMap-0.0.1 --in ~{mask} --in1 ~{fqfile} --in2 ~{fq2file} --out ./Mask2Seq/~{sn}/~{sn}.mask2seq.txt --action 3 --thread 4
        pigz -p 4 ./Mask2Seq/~{sn}/~{sn}.mask2seq.txt
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_1a76a89dc79d4ecc9960fe490b2da149_public:latest"
        req_cpu: 4
        req_memory: "50Gi"
    }
    output {
        File out= "./Mask2Seq/~{sn}/~{sn}.mask2seq.txt.gz"
    }
}

task mask2CID_SE{
    input {
        String fqfile
        File mask2seqfile
        String sn
    }
    #String outfileprefix = basename(fqfile,".fq.gz")
    String outfileprefix2 = basename(fqfile)
    String outfileprefix = sub(outfileprefix2,".list","")
    #String outfile1name = outfileprefix + "_combined.fq.gz"
    String outfile2name = outfileprefix + "_barcode.info.gz"
    command {
        if [ ! -d "./Mask2CID/~{sn}" ] ;then mkdir -p ./Mask2CID/~{sn};fi
        cat ~{fqfile} | xargs zcat | pigz --fast -p 4 > ./Mask2CID/~{sn}/~{outfileprefix}.fq.gz
        perl /meta_script/getBarcode.SE.pl ./Mask2CID/~{sn}/~{outfileprefix}.fq.gz ~{mask2seqfile} |gzip > ./Mask2CID/~{sn}/~{outfile2name}
        rm -f ./Mask2CID/~{sn}/~{outfileprefix}.fq.gz
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_7ad570a7bc094699b557ebf9629bdc87_public:latest"
        req_cpu: 4
        req_memory: "100Gi"
    }
    output {
        #Array[File] barcodefiles=glob("./01.Mask/~{sn}/*_barcode.info.gz")
        File barcodefile="./Mask2CID/~{sn}/~{outfile2name}"
        #String outfileprefix = outfileprefix
    }
}

task mask2CID_PE{  #updated
    input {
        File mask
        String fqfile
        String fq2file
        String sn
        Int? barcodeStart
        String? umiStart
        String umiLen
        String umiRead
        String barcodeLen
    }
    #String outfileprefix = basename(fqfile,"_1.fq.gz")
    String outfileprefix1 = basename(fqfile)
    String outfileprefix = sub(outfileprefix1,"_1.fq.gz","")
    #File fq2 = sub(fq1,"_1.fq.gz","_2.fq.gz")
    String outfile1name = outfileprefix + "_combined.fq.gz"
    #File outfile2name = outfileprefix + "_barcode.info"
    command {
        if [ ! -d "./Mask2CID/~{sn}" ] ;then mkdir -p ./Mask2CID/~{sn};fi
        export LD_LIBRARY_PATH=/usr/lib64:/opt/conda/lib:/usr/local/lib
        /ST_BarcodeMap/ST_BarcodeMap-0.0.1 --in ~{mask} \
        --in1 ~{fqfile} --in2 ~{fq2file} --out ./Mask2CID/~{sn}/~{outfile1name} \
        --mismatch 1 --thread 4 --action 1 --barcodeLen ~{barcodeLen} --barcodeStart ~{barcodeStart} \
        --umiRead ~{umiRead} --umiStart ~{umiStart} --umiLen ~{umiLen}
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_c37b796d7b2a442385ed1f88fb5071e4_private:latest"
        req_cpu: 4
        req_memory:"50Gi"
    }
    output {
        File outfile1 = "./Mask2CID/~{sn}/~{outfile1name}"
        #File outfile2 = "./01.Mask/~{sn}/~{outfile2name}"
        #String outfileprefix = outfileprefix
    }
}

task getBarcode_PE{
    input {
        String combinedfq
        String sn
    }
    String outfileprefix = basename(combinedfq,"_combined.fq.gz")
    String outfile2name = outfileprefix + "_barcode.info.gz"
    command {
        if [ ! -d "./getBarcode/~{sn}" ] ;then mkdir -p ./getBarcode/~{sn};fi
        perl /meta_script/getBarcode.PE.pl ~{combinedfq} | gzip > ./getBarcode/~{sn}/~{outfile2name}
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_7ad570a7bc094699b557ebf9629bdc87_public:latest"
        req_cpu: 1
        req_memory:"10Gi"
    }
    output {
        File outfile2 = "./getBarcode/~{sn}/~{outfile2name}"
    }
}

task unmap_fq{         #updated
    input {
        File align_bam
        String sn
        #String fqfile
        #Boolean PE=false
    }
    #String unmap_fqprefix = if PE then basename(fqfile,"_1.fq.gz")
    #                    else basename(fqfile,".fq.gz")
    String unmap_fqprefix = basename(align_bam,".Aligned.out.bam")
    String unmap_fq_outdir = "./Unmapped_fq/" + sn
    String unmap_fq = unmap_fq_outdir + "/" + unmap_fqprefix + "_unmapped.fq.gz"
    command {
        if [ ! -d "~{unmap_fq_outdir}" ] ;then mkdir -p ~{unmap_fq_outdir};fi
        samtools view -@ 4 -b -f 4 ~{align_bam} | samtools fastq -@ 4 -0 ~{unmap_fq} -
        gzip -t ~{unmap_fq}
        if [ -s ~{unmap_fq} ] ;then rm -f ~{align_bam};fi
    }
    output {
        File out = unmap_fq
    }
    runtime {
        docker_url: "stereonote_hpc/qiaositan_6633eeaef1d6482a8463ed69a497dfe3_public:latest"
        req_cpu: 4
        req_memory: "16Gi"
    }
}

task kraken2{
    input {
        Array[File] unmap_fqs
        String sn
        String kraken2Database
    }
    String karken_outdir = "./Kraken2/" + sn
    String merge_fq = karken_outdir + "/" + sn + ".unmapped.merge.fq.gz"
    String kraken2_fq = karken_outdir + "/" + sn + ".kraken2.fq"
    String kraken2_table = karken_outdir + "/" + sn + ".kraken2.table.txt"
    String kraken2_report = karken_outdir + "/" + sn + ".kraken2.report.txt"
    #String kraken2_fq_gz = karken_outdir + "/" + sn + ".kraken2.fq.gz"
    #String kraken2_table_gz = karken_outdir + "/" + sn + ".kraken2.table.txt.gz"
    #String kraken2_report_gz = karken_outdir + "/" + sn + ".kraken2.report.txt.gz"
    command {
        if [ ! -d "~{karken_outdir}" ] ;then mkdir -p ~{karken_outdir};fi
        zcat ~{sep=" " unmap_fqs} | gzip > ~{merge_fq}
        kraken2 -db ~{kraken2Database} --threads 12 --use-names \
        --report-minimizer-data \
        --classified-out ~{kraken2_fq} \
        -output ~{kraken2_table} \
        --report ~{kraken2_report} \
        --gzip-compressed ~{merge_fq}
        gzip -9 ~{kraken2_fq}
        gzip -9 ~{kraken2_report}
        gzip -9 ~{kraken2_table}
        rm ~{merge_fq}
    }
    runtime {
        docker_url: "stereonote_hpc/qiaositan_6633eeaef1d6482a8463ed69a497dfe3_public:latest"
        req_cpu: 12
        req_memory: "160Gi"
    }
    output {
        File kraken2tablegz = "~{kraken2_table}.gz"
        File kraken2reportgz = "~{kraken2_report}.gz"
        File kraken2fqgz = "~{kraken2_fq}.gz"
    }
}

task kraken2CID{
    input {
        File kraken2tablegz
        String sn
        File kraken2reportgz
    }
    #String readtax = sub(kraken2tablegz, "kraken2.table.txt.gz", "readsTax.txt.gz")
    String readtaxprefix = basename(kraken2tablegz,"kraken2.table.txt.gz")
    String karken2CID_outdir = "./Kraken2CID/" + sn
    String readtax = karken2CID_outdir + "/" + readtaxprefix + "readsTax.txt.gz"
    command {
        if [ ! -d "~{karken2CID_outdir}" ] ;then mkdir -p ~{karken2CID_outdir};fi
        perl /meta_script/getReads.pl ~{kraken2reportgz} ~{kraken2tablegz} | gzip > ~{readtax}
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_7ad570a7bc094699b557ebf9629bdc87_public:latest"
        req_cpu:8
        req_memory:"20Gi"
    }
    output {
        File readTax = readtax
    }
}

task getUMI{
    input {
        String fqfile
        File? barcodeinfo
        File readTax
        Boolean PE=false
    }
    String prefix = if PE then basename(fqfile,"_1.fq.gz")
                    else basename(fqfile,".fq.gz")
    String kraken2prefix = "./getUMI/" + prefix
    #String barcodeinfo = "./01.Mask/" + prefix + "_barcode.info"
    String Kraken2umi = kraken2prefix + ".kraken2.umi.txt.gz"
    command {
        if [ ! -d "./getUMI/" ] ;then mkdir -p ./getUMI ;fi
        perl /meta_script/getUMI.pl ~{readTax} ~{barcodeinfo} | gzip > ~{Kraken2umi}
    }
    output {
        File kraken2umi = Kraken2umi
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_7ad570a7bc094699b557ebf9629bdc87_public:latest"
        req_cpu:1
        req_memory:"8Gi"
    }
}

task catumi{   #updated
    input {
        Array[File] kraken2umifiles
        File readTax
    }
    String prefix = basename(readTax,"readsTax.txt.gz")
    String Krakenumi = "./CatUMI/" +prefix + "kraken2.umi.txt.gz"
    command {
        if [ ! -d "./CatUMI/" ] ;then mkdir -p ./CatUMI ;fi
        zcat ~{sep=" " kraken2umifiles} | gzip > ~{Krakenumi}
    }
    output {
        File krakenumi = Krakenumi
    }
    runtime {
        docker_url: "stereonote_hpc/qiaositan_6633eeaef1d6482a8463ed69a497dfe3_public:latest"
        req_cpu:1
        req_memory:"8Gi"
    }
}

task kraken2gem{   #updated
    input {
        Int offset_x
        Int offset_y
        Int binsize
        String kraken2umi
    }
    String Kraken2gemprefix = basename(kraken2umi, "kraken2.umi.txt.gz")
    String Kraken2gem = "Kraken2gem/" + Kraken2gemprefix + "kraken2.gem.gz"
    command {
        if [ ! -d "./Kraken2gem/" ] ;then mkdir -p ./Kraken2gem ;fi
        perl /meta_script/kraken.spatial.matrix.pl ~{kraken2umi} \
        ~{offset_x} ~{offset_y} ~{binsize} | gzip > ~{Kraken2gem}
    }
    runtime {
        docker_url: "stereonote_hpc/caoshuhuan_7ad570a7bc094699b557ebf9629bdc87_public:latest"
        req_cpu:1
        req_memory:"8Gi"
    }
    output {
        File kraken2gem = Kraken2gem
    }
}