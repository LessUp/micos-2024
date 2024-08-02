version 1.0

workflow spatialRNAvisualization_v6_sif{
    input{
    String sampleid
    Array[Array[File]] FASTQ
    File mask
    File? imageTAR
    File? imageIPR
    Int splitNum
    String Tissue
    # String ReadLength
    String CIDStart
    String CIDLength
    # Int UMI_Start_Pos
    # String UMILength
    # String UMIRead
    # Int Cellbin=1
    # Int RMrRNA=0
    # Int SlideArea
    String referenceIndex
    Int Micro=0
    File? hostref
    File? kraken_database
    }
    Int SlideArea=64
    Int UMI_Start_Pos=25
    String UMILength="6"
    String UMIRead="1"
    String ReadLength="100"
    Int Cellbin=0
    Int RMrRNA=0
    Int jobn=length(FASTQ)
    Boolean whetherPE=if length(FASTQ[0]) > 1 then true else false
    Boolean DoCellbin=if Cellbin > 0 then true else false
    String dockerUrl="public-library/lizhaoxun_34109279275c4469af175a03b583a9c5_public:latest"

    String indexid=referenceIndex
    String UMIon=if UMI_Start_Pos>=0 then "true" else "false"

    call RefRead{
        input:
            dockerUrl=dockerUrl,
            referenceFile="/jdfssz2/ST_BIGDATA/Stomics/warehouse/prd/ods/STOmics/Reference_Sequencing/spatialRNAreference.json",
            sampleid=sampleid,
            ref=indexid
    }

    String starRef=RefRead.referenceMap[indexid][0]
    if(!whetherPE){
        call SplitBarcodeBin{
            input:
                barcodeBin=mask,
                sampleid=sampleid,
                bcPos=if CIDStart=="1" && CIDLength=="24" then "2_25" else "1_24",
                sNum=splitNum,
                dockerUrl=dockerUrl
        }
    }

    scatter(index in range(jobn)){
        Array[File] DataLine1 = FASTQ[index]
        File SEfq = DataLine1[0]
    }
    call GetFQlist{
        input:
            sampleid=sampleid,
            SEfq=SEfq,
            dockerUrl=dockerUrl
    }
    Int SEn = GetFQlist.SEn


    Int jobN = if whetherPE then length(FASTQ) else SEn

    String refPath=starRef+"/Genome"
    File genomeFile=refPath
    Float genomeSize=size(genomeFile,"GB")

    if(whetherPE){
        call BcNumCountPE{
           input:
                mask=mask,
                species=indexid,
                genomesize=genomeSize,
                dockerUrl=dockerUrl
        }
        Float PEmem = BcNumCountPE.mem*1.8
    }


    scatter(index in range(jobN)){
        Array[File] DataLine = FASTQ[index]
        File raw_fq1  = if whetherPE then DataLine[0] else GetFQlist.SEfqlist[index]
        File raw_fq2 = if whetherPE then DataLine[1] else ""
        String base=basename(raw_fq1)
        String slide=if whetherPE then sub(base,"_1\\..*","")+"_"+index else base+"_"+index
        File fq2File=if whetherPE then raw_fq2 else raw_fq1
        #Float fq2Size=if whetherPE then size(fq2File,"GB") else 0
        Float fq2Size=160

        if(!whetherPE){
            call BcNumCountSE{
                input:
                    infq=raw_fq1,
                    bindir=SplitBarcodeBin.bindir,
                    sampleid=sampleid,
                    species=indexid,
                    genomesize=genomeSize,
                    dockerUrl=dockerUrl
            }
            Float SEmem = BcNumCountSE.mem*1.5
        }

        call BarcodeMappingAndStar_v2 as BarcodeMappingAndStar{
            input:
                RMrRNA=RMrRNA,
                Micro=Micro,
                sampleid=sampleid,
                index=index, #the index of data #
                binfile=if whetherPE then BcNumCountPE.binfile else BcNumCountSE.binfile,
                binfile1=if whetherPE then mask else BcNumCountSE.binfile,
                fqfile=raw_fq1,
                fq2file=if whetherPE then raw_fq2 else "",

                mismatch=1,
                pe=whetherPE,
                fqbase=slide,
                ref=starRef,
                refIndex=indexid,

                umiStart=UMI_Start_Pos,
                umiLen=UMILength,
                umiRead=UMIRead,
                barcodeStart=if whetherPE then CIDStart else 0,
                barcodeLen=CIDLength,

                outputBins=if fq2Size>150 then 100 else 50,
                #mem=if whetherPE then BcNumCountPE.mem*1.5 else BcNumCountSE.mem*1.5,
                mem=if whetherPE then PEmem else SEmem,
                bcNum=if whetherPE then BcNumCountPE.bcnum else BcNumCountSE.bcnum,
                dockerUrl=dockerUrl
        }
    }

    Array[File?] unmappedreads=BarcodeMappingAndStar.readsUnmapped

    #Array[File] getExpSeExp=select_all(GetExpSE.exp)  # SE run getexp tasks for splits in parallel
    if(!whetherPE){
        call GetExp as GetExpSE{
            input:
                index="1",
                starBam=BarcodeMappingAndStar.bam,
                #starBai=BarcodeMappingAndStar.bamBai,
                annotation=RefRead.referenceMap[indexid][1],
                sampleid=sampleid,
                umiOn=UMIon,
                dockerUrl=dockerUrl
        }
    }

    if(whetherPE){
        call GetExp as GetExpPE{
            input:
                index="1",
                starBam=BarcodeMappingAndStar.bam,
                #starBai=BarcodeMappingAndStar.bamBai,
                annotation=RefRead.referenceMap[indexid][1],
                sampleid=sampleid,
                umiOn=UMIon,
                dockerUrl=dockerUrl
            }
    }

    Array[String?] bcStarStat = BarcodeMappingAndStar.bcStat
    String? annoSummary = if whetherPE then GetExpPE.summary else GetExpSE.summary
    Array[String?] starStat = BarcodeMappingAndStar.starStat

    call MergeBarcodeReadsCount{
        input:
            SlideArea=SlideArea,
            barcodeReadsCountArr=BarcodeMappingAndStar.barcodeReadsCount,
            sampleid=sampleid,
            barcodeBin=mask,
            barcodeBin1=mask,
            dockerUrl=dockerUrl
    }

    call Register_vea{
        input:
            SlideArea=SlideArea,
            imagetar=imageTAR,
            sampleid=sampleid,
            validcidpass=1,
            imageipr=imageIPR,
            dockerUrl=dockerUrl
        }

    call TissueCut_vea{
        input:
            SlideArea=SlideArea,
            rawExp=if whetherPE then GetExpPE.exp else GetExpSE.exp,
            barcodeReadsCount=MergeBarcodeReadsCount.barcodeReadsCount,
            sampleid=sampleid,
            register_7_result=Register_vea.register_7_result,
            validcidpass=1,
            dockerUrl=dockerUrl
        }

    if(Micro == 1){
        scatter(index in range(jobN)){
            Array[String] DataLine3 = FASTQ[index]
            File raw_fq1_2  = if whetherPE then DataLine3[0] else GetFQlist.SEfqlist[index]
            File raw_fq2_2 = if whetherPE then DataLine3[1] else ""
            String base2=basename(raw_fq1_2)
            String slide2=if whetherPE then sub(base2,"_1\\..*","")+"_"+index else base2+"_"+index
            String? readsunmapped=unmappedreads[index]
            call ReadsUnmappedRmHost{
                input:
                    sampleid=sampleid,
                    fqbase=slide2,
                    dockerUrl=dockerUrl,
                    hostref=hostref,
                    Unmappedreads=readsunmapped
            }
        }
        
        Array[File?] unmappedreadsRmhost=ReadsUnmappedRmHost.unmappedreadsRmhost
        Array[File?] rmhostStat=ReadsUnmappedRmHost.rmhostStat
        call MicrobiomeAnalysis{
        input:
            sampleid=sampleid,
            dockerUrl=dockerUrl,
            hostref=hostref,
            kraken_database=kraken_database,
            unmappedreadsRmhost=select_all(unmappedreadsRmhost),
            rmhostStat=select_all(rmhostStat),
            visgem=TissueCut_vea.visGem
        }
    }

    call SpatialCluster{
        input:
            tissueGef=TissueCut_vea.tissueGef,
            sampleid=sampleid,
            dockerUrl=dockerUrl
        }

    if(DoCellbin){
        call CellCut{
            input:
                # image=imagePath,
                rawExp=if whetherPE then GetExpPE.exp else GetExpSE.exp,
                sampleid=sampleid,
                cellMask=Register_vea.cellMask,
                validcidpass=1,
                dockerUrl=dockerUrl
            }

        call CellCluster{
            input:
                # image=imagePath,
                sampleid=sampleid,
                validcidpass=1,
                cellbinGef=CellCut.cellbinGef,
                dockerUrl=dockerUrl
        }
    }

    call Saturation{
        input:
            satFile=if whetherPE then GetExpPE.sat else GetExpSE.sat,
            #satFiles=select_all(GetExpSE.sat),
            #whetherPE=if whetherPE then "PE" else "SE",
            tissueGef=TissueCut_vea.tissueGef,
            anno_summary=annoSummary,
            bcstat=select_all(bcStarStat),
            dockerUrl=dockerUrl
    }

    call Report_v2{
        input:
            ref=referenceIndex,
            tissue=Tissue,
            SlideArea=SlideArea,
            ipr=Register_vea.ipr,
            bcStat=select_all(bcStarStat),
            starStat=select_all(starStat),
            annoSummary=annoSummary,
            tissuecutStat=TissueCut_vea.report,
            visGef=TissueCut_vea.visGef,
            spatialClusterFile=SpatialCluster.spatialClusterFile,
            bin200SatPlot=Saturation.bin200SatPlot,
            tissueRpi=TissueCut_vea.rpi,
            tissueFigDir=TissueCut_vea.tissueFigDir,
            sampleid=sampleid,
            bin1SatPlot=Saturation.bin1SatPlot,
            cellFigDir=CellCut.cellFigDir,
            cellClusterFile=CellCluster.cellClusterFile,
            register_registration=Register_vea.register_registration,
            dockerUrl=dockerUrl
    }

    output{
        # 00.mapping
        #Array[File]? out00_mapping_bamBai=BarcodeMappingAndStar.bamBai
        Array[File]? out00_mapping_runStat=BarcodeMappingAndStar.bcStat
        Array[File]? out00_mapping_bcPara=BarcodeMappingAndStar.bcPara
        Array[File]? out00_mapping_starStat=BarcodeMappingAndStar.starStat
        # Array[File]? out00_mapping_fqLog=BarcodeMappingAndStar.fqLog
        # Array[File]? out00_mapping_progressLog=BarcodeMappingAndStar.progressLog
        # Array[File]? out00_mapping_starSJ=BarcodeMappingAndStar.starSJ

        # 01.merge
        #Array[File]? out01_merge_BCbarcodeReadsCount=BarcodeMappingAndStar.barcodeReadsCount
        File? out01_merge_barcodeReadsCount=MergeBarcodeReadsCount.barcodeReadsCount

        # 02.count
        File? out02_count_summary=if whetherPE then GetExpPE.summary else GetExpSE.summary
        File? out02_count_raw_gene_exp=if whetherPE then GetExpPE.sat else GetExpSE.sat
        File? out02_count_raw_gef=if whetherPE then GetExpPE.exp else GetExpSE.exp
        File? out02_count_bam=if whetherPE then GetExpPE.bam else GetExpSE.bam
        File? out02_count_mergedBarcodeGeneExp=if whetherPE then GetExpPE.exp else GetExpSE.exp
#        Array[File]? out02_count_summary_stat=if whetherPE then GetExpPE.summary else GetExpSE.summary

        # 021.microbiome_analysis
        File? out021_micro_complete_dedup_info = MicrobiomeAnalysis.micro_complete_dedup_info
        File? out021_micro_report = MicrobiomeAnalysis.micro_report
        File? out021_kraken_report = MicrobiomeAnalysis.kraken_report
        File? out021_host_micro_gem = MicrobiomeAnalysis.micro_host_micro_gem
        File? out021_host_micro_gef = MicrobiomeAnalysis.micro_host_micro_gef
        File? out021_micro_phylum_gef = MicrobiomeAnalysis.micro_phylum_gef
        File? out021_micro_phylum_gem = MicrobiomeAnalysis.micro_phylum_gem
        File? out021_micro_class_gef = MicrobiomeAnalysis.micro_class_gef
        File? out021_micro_class_gem = MicrobiomeAnalysis.micro_class_gem
        File? out021_micro_order_gef = MicrobiomeAnalysis.micro_order_gef
        File? out021_micro_order_gem = MicrobiomeAnalysis.micro_order_gem
        File? out021_micro_family_gef = MicrobiomeAnalysis.micro_family_gef
        File? out021_micro_family_gem = MicrobiomeAnalysis.micro_family_gem
        File? out021_micro_genus_gef = MicrobiomeAnalysis.micro_genus_gef
        File? out021_micro_genus_gem = MicrobiomeAnalysis.micro_genus_gem
        File? out021_micro_species_gef = MicrobiomeAnalysis.micro_species_gef
        File? out021_micro_species_gem = MicrobiomeAnalysis.micro_species_gem

        # 03.register
        File? out03_register_early_access_register_Ipr = Register_vea.outIpr
        File? out03_register_early_access_register_Tar = Register_vea.outTar
        File? out03_register_early_access_register_Tif = Register_vea.outTif
        File? out03_register_early_access_register_Rpi = Register_vea.outRpi
        File? out03_register_transformTif = Register_vea.transformTif
        File? out03_register_transformRpi = Register_vea.transformRpi
        #File? out03_register_rawTif = Register_v3.rawTif
        #File? out03_register_json = Register_v3.json
        File? out03_register_ipr = Register_vea.ipr
        File? out03_register_rpi = Register_vea.SNrpi
        File? out03_register_tif = Register_vea.imageResult
        File? out03_register_tissueTif = Register_vea.tissuecuttif
        File? out03_register_cellMask = Register_vea.cellMask
        # sampleID.tif?
        File? out03_register_transAttrs = Register_vea.transAttrs
        File? out03_register_transThumb = Register_vea.transThumb
        # Array[File]? out03_register_cellMaskAll = Register_vea.cellMaskAll
        # Array[File]? out03_register_tissuecuttifAll = Register_vea.tissuecuttifAll
        # Array[File]? out03_register_imageResultAll = Register_vea.imageResultAll
        # Array[File]? out03_register_transformTifAll = Register_vea.transformTifAll
        # Array[File]? out03_register_transformRpiAll = Register_vea.transformRpiAll

        # 04.tissuecut
        # File? out04_tissuecut_binThumb = TissueCut_vea.binThumb #bin200 png
        File? out04_tissuecut_visGef = TissueCut_vea.visGef
        File? out04_tissuecut_visGem = TissueCut_vea.visGem
        File? out04_tissuecut_tissueGef = TissueCut_vea.tissueGef
        File? out04_tissuecut_tissueGem = TissueCut_vea.tissueGem
        File? out04_tissuecut_report = TissueCut_vea.report
        # File? out04_tissuecut_tissueFigDir = TissueCut_vea.tissueFigDir

        # 041.cellcut
        File? out041_cellcut_cellbinGef = CellCut.cellbinGef
        File? out041_cellcut_cellcutStat = CellCut.cellcutStat
        File? out041_cellcut_cellFigDir = CellCut.cellFigDir
        #File? out041_cellcut_cellbinblocks = CellCut.cellbinblocks

        # 05.spatialcluster
        File? out05_spatialcluster_spatialClusterFile=SpatialCluster.spatialClusterFile

        # 051.cellcluster
        File? out051_cellcluster_cellClusterFile=CellCluster.cellClusterFile
        File? out051_cellcluster_cellbinblocks=CellCluster.cellbinblocks

        # 06.saturation
        # File? out06_saturation_bin200SatPlot = Saturation.bin200SatPlot
        # File? out06_saturation_bin1SatPlot = Saturation.bin1SatPlot
        File? out06_saturation_sequenceTxt = Saturation.seqSat

        # 07.report
        File? out07_report_reportJson = Report_v2.reportJson
        File? out07_report_htmlReport = Report_v2.htmlReport

    }
    parameter_meta{
        Data:{
            description:"SampleID\tfq1\tfq2\tbin\tImage\tsplitNum\tTissue\tReadLength\tCIDStart\tBarcodeLength\tUMI_Start_Pos\tUMILength\tUMIRead\tSlideArea\tReferenceIndex\n,if there are multiple fq pairs for one sample, write each fq pair a line sorted by fq index\n"
            }
        SampleID: "sample id is used to identify data"
    }
}

task RefRead{
    input{
        String dockerUrl
        String referenceFile
        String sampleid
        String ref
    }
    command{
        echo "Read reference configure file of ${ref}"
        echo "Workflow Version: Develop"
    }
    output{
        Map[String, Array[String]] referenceMap = read_json("${referenceFile}")
    }
    runtime{
        req_cpu:1
        req_memory:"1Gi"
        docker_url:"${dockerUrl}"
    }
}

task GetFQlist{
    input{
        Array[String] SEfq
        String sampleid
        String dockerUrl
        String python3 = "/jdfssz3/ST_STOMICS/P20Z10200N0039_pipeline/AutoAnalysis/software/Python-3.8.12/bin/python3.8"
        Int cpu = 1
        Int mem = 1
    }
    command{
mkdir -p ./output
echo "${sep='\n' SEfq}" > ./Total.fastq
outDir=`realpath ../../../../`
export SINGULARITY_BIND=$outDir
export PATH=/share/app/singularity/3.8.1/bin:$PATH
python3 << CODE
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

sleep 10
    }
    runtime{
        req_cpu:1
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        Array[File] SEfqlist=glob("./output/*.list")
        Int SEn = read_int(stdout())
        File Output = "./output"
    }    
}

task SplitBarcodeBin{
    input{
        String dockerUrl
        String barcodeBin
        String sampleid
        String bcPos="1_24"
        Int mem = 2
        Int sNum
        Int threadsNum=if sNum>16 then 16 else sNum
    }
    command{
        echo "BIOC START:SplitBarcodeBin at `date`"
        export HDF5_USE_FILE_LOCKING=FALSE
        binFileBasename=$(basename ${barcodeBin})
        mkdir -p splitBin
        outDir=`realpath ../../../../`
        barcodeBinDir=`dirname ${barcodeBin}`
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        export SINGULARITY_BIND=$barcodeBinDir,$outDir
        splitMask ${barcodeBin} splitBin/ ${threadsNum} ${sNum} ${bcPos}
    }
    runtime{
        req_cpu:threadsNum
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        Array[File] smallBins=glob("./splitBin/*.bin")
        String? bindir=glob("./splitBin/*.bin")[0]
    }
}

task BcNumCountSE{
    input{
        String dockerUrl
        File infq
        #String mask
        String? bindir
        String species
        Float genomesize
        String sampleid
        Int cpu = 1
        Int memory = 1
    }
    command{
        echo "BIOC START:BcNumCount at `date`"
        export HDF5_USE_FILE_LOCKING=FALSE
        outDir=`realpath ../../../../`
        infqDir=`dirname ${infq}`
        export SINGULARITY_BIND=$outDir,$infqDir,${bindir}
        export HDF5_USE_FILE_LOCKING=FALSE
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        python3 << CODE
        import os
        fq = "${infq}"
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
            -s ${species} \
            -g ${genomesize} > './BcNumCount'

        echo "BIOC DONE:BcNumCount at `date`"
        sleep 10

    }
    runtime{
        req_cpu:cpu
        req_memory:"${memory}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        String? bcnum = read_lines("./BcNumCount")[0]
        Float mem = read_lines("./BcNumCount")[1]
        File? binfile = read_lines("./CidIndex")[1]
    }
}

task BcNumCountPE{
    input{
        String dockerUrl
        File mask
        String species
        Float genomesize
        Int cpu = 1
        Int memory = 1
    }
    command{
        echo "BIOC START:BcNumCount at `date`"
        export HDF5_USE_FILE_LOCKING=FALSE
        outDir=`realpath ../../../../`
        maskDir=`dirname ${mask}`
        export SINGULARITY_BIND=$outDir,$maskDir
        export HDF5_USE_FILE_LOCKING=FALSE
        export PATH=/share/app/singularity/3.8.1/bin:$PATH

        CIDCount \
            -i ${mask} \
            -s ${species} \
            -g ${genomesize} >'./BcNumCount'

        echo "BIOC DONE:BcNumCount at `date`"
        sleep 10

    }
    runtime{
        req_cpu:cpu
        req_memory:"${memory}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        String? bcnum = read_lines("./BcNumCount")[0]
        Float mem = read_lines("./BcNumCount")[1]
        File? binfile = "${mask}"
    }
}

task BarcodeMappingAndStar{
    input{
        String dockerUrl
        Int? RMrRNA
        Int? Micro
        String sampleid
        File? binfile
        String? binfile1
        File fqfile
        File? fq2file
        Int? barcodeStart
        String? umiStart
        String umiLen
        String umiRead
        String barcodeLen
        #String adapter
        #String dnb
        String ref 
        String refIndex
        String fqbase
        String? bcNum
        Int cpu = 16
        Float? mem = 76

        String index
        Boolean pe=false
        Int mismatch=1  
        Int outputBins=50
    }

    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        fastqPath=${fqfile}
        fastqdir=`dirname $fastqPath`
        if [ -e $fastqdir/*.summaryReport.html ]
        then
            cp $fastqdir/*.summaryReport.html ./
            echo "copy fastq report file successfully."
        else
            echo "there is no report file, or copy failed."
        fi
        fq2fileDir=`pwd`
        echo "in=${binfile}" > ${index}.bcPara
        echo "in1=${fqfile}" >> ${index}.bcPara
        if [ ${pe} = true ];then
            echo "in2=${fq2file}" >> ${index}.bcPara
            echo "encodeRule=ACTG" >> ${index}.bcPara
            fq2fileDir=`dirname ${fq2file}`
            export SINGULARITY_BIND=fq2fileDir
            fq2size=`stat -c %s ${fq2file}`
            OutputBins=`expr $(( $fq2size / 1073741824 / 500 + 1 )) \* 100`
        else
            for i in `cat ${fqfile}`;do fqd=`dirname $i`,$fqd;done
            OutputBins=${outputBins}
        fi

        echo "OutputBins: $OutputBins"

        echo "out=${sampleid}.bc.out${index}" >> ${index}.bcPara
        echo "action=4" >> ${index}.bcPara
        echo "barcodeReadsCount=${index}.barcodeReadsCount.txt" >> ${index}.bcPara
        echo "platform=T10" >> ${index}.bcPara
        
        echo "barcodeStart=${barcodeStart}" >> ${index}.bcPara
        echo "barcodeLen=${barcodeLen}" >> ${index}.bcPara
        echo "umiStart=${umiStart}" >> ${index}.bcPara
        echo "umiLen=${umiLen}" >> ${index}.bcPara
        echo "umiRead=${umiRead}" >> ${index}.bcPara
        if [ ${mismatch} = 1 ];then
            echo "mismatch=${mismatch}" >> ${index}.bcPara
        fi

        echo "useF14" >> ${index}.bcPara
        echo "bcNum=${bcNum}" >> ${index}.bcPara
        echo "polyAnum=15" >> ${index}.bcPara
        echo "mismatchInPolyA=2" >> ${index}.bcPara

        if [[ -n "${RMrRNA}" ]] && [[ ${RMrRNA} -eq 1 ]];then
            echo "rRNAremove" >> ${index}.bcPara
        fi
        
        if [[ -n "${Micro}" ]] && [[ ${Micro} -eq 1 ]];then
            echo "outUnMappedFq" >> ${index}.bcPara
        fi
        echo "chipVersion=chipN" >> ${index}.bcPara

        outDir=`realpath ../../../../`
        fastqDir=`dirname ${fqfile}`
        binDir=`dirname ${binfile1}`
        refDir=`dirname ${ref}`
        export SINGULARITY_BIND=$fqd$outDir,$refDir,$fastqDir,$binDir,$fq2fileDir
        #export SINGULARITY_BIND=$outDir,$refDir,$fastqDir,$binDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        mapping \
            --outSAMattributes spatial \
            --outSAMtype BAM SortedByCoordinate \
            --genomeDir ${ref} \
            --runThreadN ${cpu} \
            --outFileNamePrefix ${fqbase}. \
            --limitOutSJcollapsed 10000000 \
            --limitIObufferSize=480000000 \
            --limitBAMsortRAM 63168332971 \
            --outSAMmultNmax 1 \
            --sysShell /bin/bash \
            --stParaFile ${index}.bcPara \
            --readNameSeparator \" \" \
            --outBAMsortingBinsN $OutputBins > ${fqbase}_barcodeMap.stat
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{ 
        File bam="${fqbase}.Aligned.sortedByCoord.out.bam"
        #File bamBai="${fqbase}.Aligned.sortedByCoord.out.bam.csi"
        File barcodeReadsCount = "${index}.barcodeReadsCount.txt"
        File bcStat="${fqbase}_barcodeMap.stat"
        File starStat="${fqbase}.Log.final.out"
        #Array[File] starStat=glob("${fqbase}.Log.*")
        File starSJ="${fqbase}.SJ.out.tab"
        File bcPara="${index}.bcPara"
        File fqLog="${fqbase}.Log.out"
        File progressLog="${fqbase}.Log.progress.out"
    }
}

task BarcodeMappingAndStar_v2{
    input{
        String dockerUrl
        Int? RMrRNA
        Int? Micro
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
        Int cpu = 16
        Float? mem = 76

        String index
        Boolean pe=false
        Int mismatch=1
        Int outputBins=50
    }

    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        fastqPath=${fqfile}
        fastqdir=`dirname $fastqPath`
        fq2fileDir=`pwd`
        echo "in=${binfile}" > ${index}.bcPara
        echo "in1=${fqfile}" >> ${index}.bcPara
        if [ ${pe} = true ];then
            echo "in2=${fq2file}" >> ${index}.bcPara
            echo "encodeRule=ACTG" >> ${index}.bcPara
            fq2fileDir=`dirname ${fq2file}`
            export SINGULARITY_BIND=fq2fileDir
            fq2size=`stat -c %s ${fq2file}`
            OutputBins=`expr $(( $fq2size / 1073741824 / 500 + 1 )) \* 100`
        else
            for i in `cat ${fqfile}`;do fqd=`dirname $i`,$fqd;done
            OutputBins=${outputBins}
        fi

        echo "OutputBins: $OutputBins"

        echo "out=${sampleid}.bc.out${index}" >> ${index}.bcPara
        echo "action=4" >> ${index}.bcPara
        echo "barcodeReadsCount=${index}.barcodeReadsCount.txt" >> ${index}.bcPara
        echo "platform=T10" >> ${index}.bcPara

        echo "barcodeStart=${barcodeStart}" >> ${index}.bcPara
        echo "barcodeLen=${barcodeLen}" >> ${index}.bcPara
        echo "umiStart=${umiStart}" >> ${index}.bcPara
        echo "umiLen=${umiLen}" >> ${index}.bcPara
        echo "umiRead=${umiRead}" >> ${index}.bcPara
        if [ ${mismatch} = 1 ];then
            echo "mismatch=${mismatch}" >> ${index}.bcPara
        fi

        echo "useF14" >> ${index}.bcPara
        echo "bcNum=${bcNum}" >> ${index}.bcPara
        echo "polyAnum=15" >> ${index}.bcPara
        echo "mismatchInPolyA=2" >> ${index}.bcPara


        if [[ -n "${RMrRNA}" ]] && [[ ${RMrRNA} -eq 1 ]];then
            echo "rRNAremove" >> ${index}.bcPara
        fi

        if [[ -n "${Micro}" ]] && [[ ${Micro} -eq 1 ]];then
            echo "outUnMappedFq" >> ${index}.bcPara
        fi
        echo "chipVersion=chipN" >> ${index}.bcPara

        outDir=`realpath ../../../../`
        fastqDir=`dirname ${fqfile}`
        binDir=`dirname ${binfile1}`
        refDir=`dirname ${ref}`
        mapping \
            --outSAMattributes spatial \
            --outSAMtype BAM SortedByCoordinate \
            --genomeDir ${ref} \
            --runThreadN ${cpu} \
            --outFileNamePrefix ${fqbase}. \
            --limitOutSJcollapsed 10000000 \
            --limitIObufferSize=480000000 \
            --limitBAMsortRAM 63168332971 \
            --outSAMmultNmax 1 \
            --sysShell /bin/bash \
            --stParaFile ${index}.bcPara \
            --readNameSeparator \" \" \
            --outBAMsortingBinsN $OutputBins
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        File bam="${fqbase}.Aligned.sortedByCoord.out.bam"
        File barcodeReadsCount = "${index}.barcodeReadsCount.txt"
        File bcStat="${fqbase}.CIDMap.stat"
        File starStat="${fqbase}.Log.final.out"
        File starSJ="${fqbase}.SJ.out.tab"
        File bcPara="${index}.bcPara"
        File fqLog="${fqbase}.Log.out"
        File progressLog="${fqbase}.Log.progress.out"
        File? readsUnmapped="${fqbase}.unmapped_reads.fq"
    }
}

task ReadsUnmappedRmHost{
    input{
        String dockerUrl
        String sampleid
        String fqbase
        String? Unmappedreads
        Int cpu = 10
        Int mem = 20
        String? hostref
    }
    command{
        if [[ -n "${hostref}" ]] && [[ -e "${hostref}" ]];then
            outDir=`realpath ../../../../`
            hostgenomeDir=$(dirname ${hostref})
            export HDF5_USE_FILE_LOCKING=FALSE
            export SINGULARITY_BIND=$outDir,$hostgenomeDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            echo ${hostref} > ./hostdirfile
        python3 << CODE
        import glob
        import os
        import re
        with open("./hostdirfile","r") as f:
            for line in f:
                hostdir=line.strip()
        
        indexout=open("./indexfile","w")
        hostlist=glob.glob(hostdir+"/*3.bt2")
        host=os.path.basename(hostlist[0])
        tmp=re.search(r"(\S+).3.bt2",host)
        hostindex=tmp.group(1)
        indexout.write(hostdir + "/" + hostindex + "\n")
        indexout.close()
        CODE
            
            hostindex2=$(cat ./indexfile | head -n 1)
            Bowtie2 --very-sensitive-local --no-unal -p ${cpu} --phred33 -x $hostindex2 -U ${Unmappedreads} --un-gz ${fqbase}.unmapped_reads_rmhost.fq.gz 1> ${fqbase}.sam 2> ${fqbase}.stat
        else
            echo "### No hostref, skip RmHost and MicrobiomeAnalysis task."
        fi
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        File? unmappedreadsRmhost = "${fqbase}.unmapped_reads_rmhost.fq.gz"
        File? rmhostStat="${fqbase}.stat"
    }
}

task MicrobiomeAnalysis{
    input{
        String dockerUrl
        String sampleid
        Array[File] unmappedreadsRmhost
        Array[File] rmhostStat
        Int cpu = 20
        Int mem = 100
        String? kraken_database
        String? hostref
        String outdir = "."
        String visgem
    }
    command{
        if [[ -n "${hostref}" ]] && [[ -e "${hostref}" ]] && [[ -n "${kraken_database}" ]] && [[ -e "${kraken_database}" ]] 
        then
            if [[ ! -e ${outdir}/00.rmhost ]];then mkdir ${outdir}/00.rmhost;fi
            if [[ ! -e ${outdir}/01.micro_analysis ]];then mkdir ${outdir}/01.micro_analysis;fi
            if [[ ! -e ${outdir}/02.micro_report ]];then mkdir ${outdir}/02.micro_report;fi
            if [[ ! -e ${outdir}/03.micro_visualization ]];then mkdir ${outdir}/03.micro_visualization;fi
            echo "${sep='\n' rmhostStat}" > ${outdir}/00.rmhost/stat.list
            for i in `cat ./00.rmhost/stat.list`;do 
                /bin/cp -f $i ./00.rmhost/
            done

            outDir=`realpath ../../../../`
            kraken_databaseDir=$(dirname ${kraken_database})
            export HDF5_USE_FILE_LOCKING=FALSE
            export SINGULARITY_BIND=$outDir,$kraken_databaseDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH    
            cat ${sep=" " unmappedreadsRmhost} > ${outdir}/01.micro_analysis/${sampleid}.total.unmapped_reads_rmhost.fq.gz
            Kraken2 --db ${kraken_database} --threads ${cpu} --use-names --gzip-compressed --report-minimizer-data --report ${outdir}/01.micro_analysis/${sampleid}.report --output ${outdir}/01.micro_analysis/${sampleid}.output --classified-out ${outdir}/01.micro_analysis/${sampleid}.classified.fq ${outdir}/01.micro_analysis/${sampleid}.total.unmapped_reads_rmhost.fq.gz
            
            reportnum=`cat ${outdir}/01.micro_analysis/${sampleid}.report |wc -l`
            if [[ $reportnum == 1 ]];then
                echo `date` "WARN: This sample does not have microbiome."
                exit
            fi 
            
            kreport2krona --intermediate-ranks -r ${outdir}/01.micro_analysis/${sampleid}.report -o ${outdir}/01.micro_analysis/${sampleid}.krona.report
            combinedata -s ${sampleid} -r ${outdir}/01.micro_analysis/${sampleid}.report -kr ${outdir}/01.micro_analysis/${sampleid}.krona.report -i ${outdir}/01.micro_analysis/${sampleid}.classified.fq -o ${outdir}/01.micro_analysis/
            
            if [[ -n ${visgem} ]];then
                combinegem -s ${sampleid} -g ${visgem} -m ${outdir}/01.micro_analysis/${sampleid}_all_microbiome.gem -o ${outdir}/01.micro_analysis/
            else
                echo `date` "WARN: ${sampleid}.gem.gz does not exist, please double check the path."
            fi
            rm -f ${outdir}/01.micro_analysis/${sampleid}_all_microbiome.gem
        
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}_microbiome.phylum.label.gem -o ${outdir}/01.micro_analysis/${sampleid}_microbiome.phylum.label.gef -O Transcriptomics
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}_microbiome.class.label.gem -o ${outdir}/01.micro_analysis/${sampleid}_microbiome.class.label.gef -O Transcriptomics
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}_microbiome.order.label.gem -o ${outdir}/01.micro_analysis/${sampleid}_microbiome.order.label.gef -O Transcriptomics
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}_microbiome.family.label.gem -o ${outdir}/01.micro_analysis/${sampleid}_microbiome.family.label.gef -O Transcriptomics
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}_microbiome.genus.label.gem -o ${outdir}/01.micro_analysis/${sampleid}_microbiome.genus.label.gef -O Transcriptomics
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}_microbiome.species.label.gem -o ${outdir}/01.micro_analysis/${sampleid}_microbiome.species.label.gef -O Transcriptomics 
            cellCut bgef -i ${outdir}/01.micro_analysis/${sampleid}.host_micro.label.gem -o ${outdir}/01.micro_analysis/${sampleid}.host_micro.label.gef -O Transcriptomics
            gzip ${outdir}/01.micro_analysis/${sampleid}.host_micro.label.gem  
            micro_report -i ${outdir} -c ${sampleid}
            if [[ -n ${visgem} ]];then
                cp ${outdir}/01.micro_analysis/${sampleid}.host_micro.label.gef ${outdir}/03.micro_visualization
            fi
            rm -f ${outdir}/00.rmhost/*sam
        else
            echo "### No hostref or kraken_database, skip MicrobiomeAnalysis task."
        fi    
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        File? micro_complete_dedup_info = "${outdir}/01.micro_analysis/seq_complete_info_dedup.txt"
        File? micro_report = "${outdir}/02.micro_report/${sampleid}_micro_report.html"
        File? kraken_report = "${outdir}/01.micro_analysis/${sampleid}.report"
        File? micro_host_micro_gef = "${outdir}/01.micro_analysis/${sampleid}.host_micro.label.gef"
        File? micro_host_micro_gem = "${outdir}/01.micro_analysis/${sampleid}.host_micro.label.gem.gz"
        File? micro_phylum_gef = "${outdir}/01.micro_analysis/${sampleid}_microbiome.phylum.label.gef"
        File? micro_phylum_gem = "${outdir}/01.micro_analysis/${sampleid}_microbiome.phylum.label.gem"
        File? micro_class_gef = "${outdir}/01.micro_analysis/${sampleid}_microbiome.class.label.gef"
        File? micro_class_gem = "${outdir}/01.micro_analysis/${sampleid}_microbiome.class.label.gem"
        File? micro_order_gef = "${outdir}/01.micro_analysis/${sampleid}_microbiome.order.label.gef"
        File? micro_order_gem = "${outdir}/01.micro_analysis/${sampleid}_microbiome.order.label.gem"
        File? micro_family_gef = "${outdir}/01.micro_analysis/${sampleid}_microbiome.family.label.gef"
        File? micro_family_gem = "${outdir}/01.micro_analysis/${sampleid}_microbiome.family.label.gem"
        File? micro_genus_gef = "${outdir}/01.micro_analysis/${sampleid}_microbiome.genus.label.gef"
        File? micro_genus_gem = "${outdir}/01.micro_analysis/${sampleid}_microbiome.genus.label.gem"
        File? micro_species_gef = "${outdir}/01.micro_analysis/${sampleid}_microbiome.species.label.gef"
        File? micro_species_gem = "${outdir}/01.micro_analysis/${sampleid}_microbiome.species.label.gem"
    }
}

task GetExp{ #GetExp.wdl
    input{
        String dockerUrl
        Array[File] starBam
        String annotation
        String sampleid
        String umiOn
        Int cpu = 24  ## min cpu=8
        Int mem = 128
        String index
    }
    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        if [[ ${umiOn} = "false" ]]
        then
            outDir=`realpath ../../../../`
            annotationPath=`realpath ${annotation}`
            annotationDir=`dirname $annotationPath`
            export SINGULARITY_BIND=$outDir,$annotationDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            count \
                -i ${sep="," starBam} \
                -o ./${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam \
                -a ${annotation} \
                -s ./${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat \
                -e ./${sampleid}.raw.gef \
                --save_lq \
                --save_dup \
                -c ${cpu} \
                -m 80 \
                --sn ${sampleid}
        else
            outDir=`realpath ../../../../`
            annotationPath=`realpath ${annotation}`
            annotationDir=`dirname $annotationPath`
            export SINGULARITY_BIND=$outDir,$annotationDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            count \
                -i ${sep="," starBam} \
                -o ./${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam \
                -a ${annotation} \
                -s ./${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat \
                -e ./${sampleid}.raw.gef \
                --sat_file ./${sampleid}_raw_barcode_gene_exp.txt \
                --umi_on \
                --save_lq \
                --save_dup \
                -c ${cpu} \
                -m 80 \
                --sn ${sampleid}
        fi
        
        #echo "### truncate Star Bams..."
        if [[ -f ./${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat ]]
        then
       echo ${sep=" " starBam} | xargs truncate -s 0
        fi
        #echo "### truncate Star Bams DONE"
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
        jobs_name:"GetExp"
    }
    output{
        File bam = "${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam"
        File summary = "${sampleid}.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat"
        File exp = "${sampleid}.raw.gef"
        File sat="${sampleid}_raw_barcode_gene_exp.txt"
    }
}

task CalValidCidPass{
    input{
        String dockerUrl
        String sampleid
        Array[String] stat
    }
    command{
        outDir=`realpath ../../../../`
        export SINGULARITY_BIND=$outDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        export HDF5_USE_FILE_LOCKING=FALSE
        python3 << CODE
        import glob
        import numpy as np
        statfile = "${sep=',' stat}"
        cidpass=[]
        for file in statfile.split(","):
            with open(file, 'r', encoding='utf-8') as r:
                rows = r.read().splitlines()
            for i in rows:
                if i.startswith("mapped_reads") or i.startswith("umi_filter_reads"):
                    cidpass.append(i)
        mappingrate=[float(i.split('\t')[-1][:-1]) for i in cidpass[::2]]
        umifilteredrate=[float(i.split('\t')[-1][:-1]) for i in cidpass[1::2]]
        print(sum((np.array(mappingrate) - np.array(umifilteredrate)) > 10))
        CODE
    }
    runtime{
        req_cpu:1
        req_memory:"1Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        Int sum = read_int(stdout())
    }
}

task MergeBarcodeReadsCount{
    input{
        String dockerUrl
        Int SlideArea
        Array[File] barcodeReadsCountArr
        String sampleid
        File barcodeBin
        String barcodeBin1
        Int cpu = 1
        Int mem = if SlideArea <= 200 then 50 else 170
        
    }
    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        outDir=`realpath ../../../../`
        barcodeBinDir=`dirname ${barcodeBin1}`
        export SINGULARITY_BIND=$outDir,$barcodeBinDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        merge \
            ${barcodeBin} \
            ${sep="," barcodeReadsCountArr} \
            ${sampleid}.merge.barcodeReadsCount.txt
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        File barcodeReadsCount = "${sampleid}.merge.barcodeReadsCount.txt"
    }
}

task Register_v2{
    input{
        String dockerUrl
        String? image
        String? imagepre
        String? imageipr
        File? rawExp
        String outdir = "."
        String sampleid
        Int SlideArea
        Int validcidpass
        Int cpu = 8
        Int mem = if SlideArea <= 72 then 72 else 160
        String register = if SlideArea <= 72 then "register" else "rapidRegister"
    }
    command{
        export TMPDIR=""
        export HDF5_USE_FILE_LOCKING=FALSE
        if [[ ${validcidpass} -ne 0 ]] && [[ -n "${imagepre}" ]] && [[ -e "${imagepre}" ]]
        then
            echo "### Image exist and ${validcidpass} valid CID rate pass 10%."
            echo "### Image exist but have not stitched and segmented."
            echo "### Start stitching, segmenting, and registering..."
            attr=$(find ${imagepre} -name \*attrs.json | head -1)
            trans=$(find ${imagepre} -name \*transform_thumb.png | head -1)
            mkdir -p ./registration
            /bin/cp -f $attr ./registration/${sampleid}.transform.attrs.json
            /bin/cp -f $trans ./registration/${sampleid}.transform.thumbnail.png

            imageipr=$(find ${imageipr} -maxdepth 1 -name *.ipr | head -1)
            imageTar=${image}
            outDir=`realpath ../../../../`
            imageiprPath=`realpath ${imageipr}`
            imageiprDir=`dirname $imageiprPath`
            rawExpPath=`realpath ${rawExp}`
            rawExpDir=`dirname $rawExpPath`
            imageprePath=`realpath ${imagepre}`
            imagepreDir=`dirname $imageprePath`
            imageTarPath=`realpath $imageTar`
            imageTarDir=`dirname $imageTarPath`
            export SINGULARITY_BIND=$outDir,$imageiprDir,$rawExpDir,$imagepreDir,$imageTarDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            ${register} \
                    -i ${imagepre} \
                    -v ${rawExp} \
                    -c $imageipr \
                    -o ${outdir}/registration 
            outipr=$(find ${outdir}/registration -maxdepth 1 -name *.ipr | head -1)
            imageTools ipr2img \
                    -i $imageTar \
                    -c $outipr \
                    -d tissue cell \
                    -r True \
                    -o ${outdir}/registration
            imageTools ipr2img \
                    -i ${outdir}/registration/fov_stitched_transformed.tif \
                    -o ${outdir}/registration/fov_stitched_transformed.rpi \
                    -g ssDNA \
                    -b 1 10 50 100

            registTiff=$(find ${outdir}/registration -maxdepth 1 -name \*regist.tif | head -1)
            if [[ ! -e $registTiff ]]
            then
                >&2 echo "### Register error! Exit now!"
                exit 1
            else
                echo "### Image stitching, segmentation, and registration DONE."
            fi 

            attrs=$(find ${outdir}/registration -maxdepth 1 -name attrs.json | head -1)
            if [[ -e $attrs ]]
            then 
                mv ${outdir}/registration/attrs.json ${outdir}/registration/${sampleid}.transform.attrs.json
                mv ${outdir}/registration/transform_thumb.png ${outdir}/registration/${sampleid}.transform.thumbnail.png
            else
                echo "### Warning! You cannot perform manual register for this task! Necessary files do not exist!"
            fi
        
        else
            echo "### No image, skip Register task."
        fi
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        job_name:"register"
        docker_url:"${dockerUrl}"
    }

    output{
        File? register_registration = "${outdir}/registration"
        File? register_7_result = "${outdir}/registration"
        File? ipr = if length(glob("${outdir}/registration/*.ipr")) > 0 then glob("${outdir}/registration/*.ipr")[0] else "None"
        File? imageResult = "${outdir}/registration/${sampleid}_regist.tif"
        File? transAttrs = "${outdir}/registration/${sampleid}.transform.attrs.json"
        File? transThumb = "${outdir}/registration/${sampleid}.transform.thumbnail.png"
        File? transformTif = "${outdir}/registration/fov_stitched_transformed.tif"
        File? transformRpi = "${outdir}/registration/fov_stitched_transformed.rpi"
        File? cellMask = "${outdir}/registration/${sampleid}_mask.tif"
        File? bbox = "${outdir}/registration/${sampleid}_tissue_bbox.csv"
        File? tissuecuttif = "${outdir}/registration/${sampleid}_tissue_cut.tif"
        File? SNrpi = "${outdir}/registration/${sampleid}.rpi"
    }
}

task Register_v3{
    input{
        String dockerUrl
        File? image
        File? imagepre
        File? imageipr
        File? rawExp
        String outdir = "."
        String sampleid
        Int SlideArea
        Int validcidpass
        Int cpu = 8
        Int mem = if SlideArea <= 72 then 72 else 160
        String register = if SlideArea <= 72 then "register" else "rapidRegister"
    }
    command <<<
        export TMPDIR=""
        export HDF5_USE_FILE_LOCKING=FALSE
        if [[ ~{validcidpass} -ne 0 ]] && [[ -n "~{image}" ]] && [[ -e "~{image}" ]]
        then
            echo "### Image exist and ~{validcidpass} valid CID rate pass 10%."
            echo "### Image exist but have not stitched and segmented."
            echo "### Start stitching, segmenting, and registering..."
            attr=$(find ~{imagepre} -name \*attrs.json | head -1)
            trans=$(find ~{imagepre} -name \*transform_thumb.png | head -1)
            mkdir -p ./registration
            /bin/cp -f $attr ./registration/~{sampleid}.transform.attrs.json
            /bin/cp -f $trans ./registration/~{sampleid}.transform.thumbnail.png
            chmod 755 ~{outdir}/registration/~{sampleid}.transform.attrs.json ~{outdir}/registration/~{sampleid}.transform.thumbnail.png

            imageipr=$(find ~{imageipr} -maxdepth 1 -name *.ipr | head -1)
            imageTar=~{image}
            outDir=`realpath ../../../../`
            imageiprPath=`realpath ~{imageipr}`
            imageiprDir=`dirname $imageiprPath`
            rawExpPath=`realpath ~{rawExp}`
            rawExpDir=`dirname $rawExpPath`
            imageprePath=`realpath ~{imagepre}`
            imagepreDir=`dirname $imageprePath`
            imageTarPath=`realpath $imageTar`
            imageTarDir=`dirname $imageTarPath`

            ManualStateStitch=$(/usr/local/hdf5/bin/h5dump -a /ManualState/stitch $imageipr | grep "(0):" | awk '{print$2}')
            StereoResepSwitchStitch=$(/usr/local/hdf5/bin/h5dump -a /StereoResepSwitch/stitch $imageipr | grep "(0):" | awk '{print$2}')

            if [ $ManualStateStitch == "TRUE" ] && [ $StereoResepSwitchStitch == "TRUE" ] || [ -z "~{imagepre}" ]
            then
            echo "ManualStateStitch: TRUE"
            ~{register} \
                    -i $imageTar \
                    -v ~{rawExp} \
                    -c $imageipr \
                    -o ~{outdir}/registration
            else
            echo "ManualStateStitch: FALSE"
            ~{register} \
                    -i ~{imagepre} \
                    -v ~{rawExp} \
                    -c $imageipr \
                    -o ~{outdir}/registration
            fi

            outipr=$(find ~{outdir}/registration -maxdepth 1 -name *.ipr | head -1)
            imageTools ipr2img \
                    -i $imageTar \
                    -c $outipr \
                    -d tissue cell \
                    -r True \
                    -o ~{outdir}/registration


            if [[ -f "~{outdir}/registration/DAPI_fov_stitched_transformed.tif" ]]
            then
                tifAll=$(find -name \*fov_stitched_transformed.tif | awk 'BEGIN{ORS=","} {print $0}')
                groupAll=$(find -name \*fov_stitched_transformed.tif | awk -F '/' '{print$NF}' | awk -F '_' 'BEGIN{ORS=","} {print$1"/Image"}')
                imageTools img2rpi \
                        -i ${tifAll%?} \
                        -g ${groupAll%?} \
                        -b 1 10 50 100 \
                        -o ~{outdir}/registration/fov_stitched_transformed.rpi
            else
                imageTools img2rpi \
                        -i ~{outdir}/registration/ssDNA_fov_stitched_transformed.tif \
                        -o ~{outdir}/registration/ssDNA_fov_stitched_transformed.rpi \
                        -g ssDNA/Image \
                        -b 1 10 50 100
            fi

            registTiff=$(find ~{outdir}/registration -maxdepth 1 -name \*regist.tif | head -1)
            if [[ ! -e $registTiff ]]
            then
                >&2 echo "### Register error! Exit now!"
                exit 1
            else
                echo "### Image stitching, segmentation, and registration DONE."
            fi 
        
        else
            echo "### No image, skip Register task."
        fi
    >>>
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        job_name:"register"
        docker_url:"${dockerUrl}"
    }

    output{
        File? register_registration = "${outdir}/registration"
        File? register_7_result = "${outdir}/registration"
        File? ipr = if length(glob("${outdir}/registration/*.ipr")) > 0 then glob("${outdir}/registration/*.ipr")[0] else "None"
        File? imageResult = "${outdir}/registration/ssDNA_${sampleid}_regist.tif"
        File? transAttrs = "${outdir}/registration/${sampleid}.transform.attrs.json"
        File? transThumb = "${outdir}/registration/${sampleid}.transform.thumbnail.png"
        File? transformTif = "${outdir}/registration/ssDNA_fov_stitched_transformed.tif"
        File? transformRpi = "${outdir}/registration/ssDNA_fov_stitched_transformed.rpi"
        File? cellMask = if length(glob("${outdir}/registration/DAPI_*_mask.tif")) > 0 then glob("${outdir}/registration/DAPI_*_mask.tif")[0] else "${outdir}/registration/ssDNA_${sampleid}_mask.tif"
        File? bbox = "${outdir}/registration/${sampleid}_tissue_bbox.csv"
        File? tissuecuttif = if length(glob("${outdir}/registration/DAPI_*_tissue_cut.tif")) > 0 then glob("${outdir}/registration/DAPI_*_tissue_cut.tif")[0] else "${outdir}/registration/ssDNA_${sampleid}_tissue_cut.tif"
        File? SNrpi = "${outdir}/registration/${sampleid}.rpi"
        Array[File]? cellMaskAll = glob("${outdir}/registration/*mask.tif")
        Array[File]? tissuecuttifAll = glob("${outdir}/registration/*tissue_cut.tif")
        Array[File]? imageResultAll = glob("${outdir}/registration/*regist.tif")
        Array[File]? transformTifAll = glob("${outdir}/registration/*fov_stitched_transformed.tif")
        Array[File]? transformRpiAll = glob("${outdir}/registration/*fov_stitched_transformed.rpi")
    }
}

task Register_vea{
    input{
        String dockerUrl
        File? imagetar
        File? imageipr
        String outdir = "."
        String sampleid
        Int SlideArea
        Int validcidpass
        Int cpu = 5
        Int mem = 15
    }
    command <<<
        export TMPDIR=""
        export HDF5_USE_FILE_LOCKING=FALSE
        if [[ ~{validcidpass} -ne 0 ]] && [[ -n "~{imageipr}" ]] && [[ -e "~{imageipr}" ]] && [[ -n "~{imagetar}" ]] && [[ -e "~{imagetar}" ]]
        then
            mkdir -p ./registration/early_access_register
            imgTarDIR=`realpath ~{imagetar}`
            iprDIR=`realpath ~{imageipr}`
            outDir=`realpath ../../../../`
            export SINGULARITY_BIND=$outDir,$imgTarDIR,$iprDIR
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            /bin/cp -f ~{imageipr} ~{outdir}/registration/early_access_register/~{sampleid}.ipr
            /bin/cp -f ~{imagetar} ~{outdir}/registration/early_access_register/~{sampleid}.tar.gz

            chmod 755 ~{outdir}/registration/early_access_register/~{sampleid}.ipr ~{outdir}/registration/early_access_register/~{sampleid}.tar.gz

            imageTools ipr2img \
                -i ~{imagetar} \
                -c ~{imageipr} \
                -r False \
                -o ~{outdir}/registration/early_access_register
            imageTools img2rpi \
                -i ~{outdir}/registration/early_access_register/HE_fov_stitched.tif \
                -g HE/Image \
                -b 1 10 50 100 \
                -o ~{outdir}/registration/early_access_register/HE_fov_stitched.rpi
        
        else
            echo "### No image, skip Register task."
        fi
    >>>
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        job_name:"register"
        docker_url:"${dockerUrl}"
    }

    output{
        File? outIpr = "./registration/early_access_register/${sampleid}.ipr"
        File? outTar = "./registration/early_access_register/${sampleid}.tar.gz"
        File? outTif = "registration/early_access_register/HE_fov_stitched.tif"
        File? outRpi = "registration/early_access_register/HE_fov_stitched.rpi"
        File? register_registration = "${outdir}/registration"
        File? register_7_result = "${outdir}/registration"
        File? ipr = if length(glob("${outdir}/registration/*.ipr")) > 0 then glob("${outdir}/registration/*.ipr")[0] else "None"
        File? imageResult = "${outdir}/registration/ssDNA_${sampleid}_regist.tif"
        File? transAttrs = "${outdir}/registration/${sampleid}.transform.attrs.json"
        File? transThumb = "${outdir}/registration/${sampleid}.transform.thumbnail.png"
        File? transformTif = "${outdir}/registration/ssDNA_fov_stitched_transformed.tif"
        File? transformRpi = "${outdir}/registration/ssDNA_fov_stitched_transformed.rpi"
        File? cellMask = if length(glob("${outdir}/registration/DAPI_*_mask.tif")) > 0 then glob("${outdir}/registration/DAPI_*_mask.tif")[0] else "${outdir}/registration/ssDNA_${sampleid}_mask.tif"
        File? bbox = "${outdir}/registration/${sampleid}_tissue_bbox.csv"
        File? tissuecuttif = if length(glob("${outdir}/registration/DAPI_*_tissue_cut.tif")) > 0 then glob("${outdir}/registration/DAPI_*_tissue_cut.tif")[0] else "${outdir}/registration/ssDNA_${sampleid}_tissue_cut.tif"
        File? SNrpi = "${outdir}/registration/${sampleid}.rpi"
        # Array[File]? cellMaskAll = glob("${outdir}/registration/*mask.tif")
        # Array[File]? tissuecuttifAll = glob("${outdir}/registration/*tissue_cut.tif")
        # Array[File]? imageResultAll = glob("${outdir}/registration/*regist.tif")
        # Array[File]? transformTifAll = glob("${outdir}/registration/*fov_stitched_transformed.tif")
        # Array[File]? transformRpiAll = glob("${outdir}/registration/*fov_stitched_transformed.rpi")
    }
}

task TissueCut_vea{
    input{
        String dockerUrl
        Int SlideArea
        File? rawExp
        String barcodeReadsCount
        String outdir = "."
        String sampleid
        
        #String tissue
        #String platform
        File? image
        File? imageResult
        Int validcidpass
        File? register_7_result
        Int cpu = 10
        Int mem = if SlideArea <= 200 then 72 else 240
    }
    command{
        echo "BIOC START:TissueCut at `date`"
        export HDF5_USE_FILE_LOCKING=FALSE
        
        mkdir -p ${outdir}/04.tissuecut
        outDir=`realpath ../../../../`
        rawExpPath=`realpath ${rawExp}`
        rawExpDir=`dirname $rawExpPath`
        registerPath=`realpath ${register_7_result}`
        registerDir=`dirname $registerPath`
        barcodeReadsCountPath=`realpath ${barcodeReadsCount}`
        barcodeReadsCountDir=`dirname $barcodeReadsCountPath`
        export SINGULARITY_BIND=$outDir,$tissueDir,$registerDir,$rawExpDir,$barcodeReadsCountDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        cellCut bgef -i ${rawExp} -o ./04.tissuecut/${sampleid}.gef -O Transcriptomics

        echo "### Start extracting tissue-covered expression matrix, based on spatial gene expression distribution..."
        tissueCut \
                --dnbfile ${barcodeReadsCount} \
                -i ./04.tissuecut/${sampleid}.gef \
                -o ${outdir}/04.tissuecut \
                --sn ${sampleid} \
                -O Transcriptomics \
                -t 10 \
                --develop &&\
        echo "### Extracting tissue-covered expression matrix DONE."


        mkdir -p ./04.tissuecut/dnb_merge
        python3 << CODE
        from gefpy import plot
        plot.save_exp_heat_map_by_binsize('${outdir}/04.tissuecut/${sampleid}.gef', '${outdir}/04.tissuecut/dnb_merge/bin200.png',200)
        CODE

        cellCut view -s ${sampleid} -i ${outdir}/04.tissuecut/${sampleid}.gef -o ${outdir}/04.tissuecut/${sampleid}.gem && gzip ${outdir}/04.tissuecut/${sampleid}.gem
        cellCut view -s ${sampleid} -i ${outdir}/04.tissuecut/${sampleid}.tissue.gef -o ${outdir}/04.tissuecut/${sampleid}.tissue.gem && gzip ${outdir}/04.tissuecut/${sampleid}.tissue.gem

        /bin/cp -rf ${register_7_result}/${sampleid}.rpi ${outdir}/04.tissuecut/tissue_fig/${sampleid}.ssDNA.rpi

        if [[ ! -e ${outdir}/04.tissuecut/tissue_fig/scatter_200x200_MID_gene_counts.png ]]
        then
            >&2 echo "### Tissuecut Error! Exit now!"
            exit 1
        fi
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
#        sge_queue:"stereo.q"
        job_name:"tissueCut"
        docker_url:"${dockerUrl}"
    }
    output{
        File tissueGef = "${outdir}/04.tissuecut/${sampleid}.tissue.gef"
        File tissueGem = "${outdir}/04.tissuecut/${sampleid}.tissue.gem.gz"
        File report = "${outdir}/04.tissuecut/tissuecut.stat"
        File visGef = "${outdir}/04.tissuecut/${sampleid}.gef"
        File visGem = "${outdir}/04.tissuecut/${sampleid}.gem.gz"
        File? rpi = "${outdir}/04.tissuecut/tissue_fig/${sampleid}.ssDNA.rpi"
        File binThumb = "${outdir}/04.tissuecut/dnb_merge/bin200.png"
        File tissueFigDir = "${outdir}/04.tissuecut/tissue_fig"
    }
}

task TissueCut{
    input{
        String dockerUrl
        Int SlideArea
        File? rawExp
        String barcodeReadsCount
        String outdir = "."
        String sampleid
        
        #String tissue
        #String platform
        File? image
        File? imageResult
        Int validcidpass
        File? register_7_result
        Int cpu = 10
        Int mem = if SlideArea <= 200 then 72 else 240
    }
    command{
        echo "BIOC START:TissueCut at `date`"
        export HDF5_USE_FILE_LOCKING=FALSE
        
        mkdir -p ${outdir}/04.tissuecut
        outDir=`realpath ../../../../`
        rawExpPath=`realpath ${rawExp}`
        rawExpDir=`dirname $rawExpPath`
        registerPath=`realpath ${register_7_result}`
        registerDir=`dirname $registerPath`
        barcodeReadsCountPath=`realpath ${barcodeReadsCount}`
        barcodeReadsCountDir=`dirname $barcodeReadsCountPath`
        export SINGULARITY_BIND=$outDir,$tissueDir,$registerDir,$rawExpDir,$barcodeReadsCountDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        cellCut bgef -i ${rawExp} -o ./04.tissuecut/${sampleid}.gef -O Transcriptomics

        if [[ ${validcidpass} -ne 0 ]] && [[ -n "${image}" ]] && [[ -e "${image}" ]]
        then
            echo "### Start extracting tissue-covered expression matrix, based on staining image mask..."
            tissueCut \
                    --dnbfile ${barcodeReadsCount} \
                    -i ./04.tissuecut/${sampleid}.gef \
                    -o ${outdir}/04.tissuecut \
                    -s ${imageResult} \
                    --sn ${sampleid} \
                    -O Transcriptomics \
                    -t 10 \
                    --develop &&\

            echo "### Extracting tissue-covered expression matrix DONE."
            /bin/cp -rf ${register_7_result}/${sampleid}.rpi ${outdir}/04.tissuecut/tissue_fig/${sampleid}.ssDNA.rpi
        else
            echo "### Valid CID rate < 10% or no image."
            echo "### Start extracting tissue-covered expression matrix, based on spatial gene expression distribution..."
            tissueCut \
                    --dnbfile ${barcodeReadsCount} \
                    -i ./04.tissuecut/${sampleid}.gef \
                    -o ${outdir}/04.tissuecut \
                    --sn ${sampleid} \
                    -O Transcriptomics \
                    -t 10 \
                    --develop &&\
            echo "### Extracting tissue-covered expression matrix DONE."
        fi

        mkdir -p ./04.tissuecut/dnb_merge
        python3 << CODE
        from gefpy import plot
        plot.save_exp_heat_map_by_binsize('${outdir}/04.tissuecut/${sampleid}.gef', '${outdir}/04.tissuecut/dnb_merge/bin200.png',200)
        CODE

        cellCut view -s ${sampleid} -i ${outdir}/04.tissuecut/${sampleid}.gef -o ${outdir}/04.tissuecut/${sampleid}.gem && gzip ${outdir}/04.tissuecut/${sampleid}.gem
        cellCut view -s ${sampleid} -i ${outdir}/04.tissuecut/${sampleid}.tissue.gef -o ${outdir}/04.tissuecut/${sampleid}.tissue.gem && gzip ${outdir}/04.tissuecut/${sampleid}.tissue.gem

        /bin/cp -rf ${register_7_result}/${sampleid}.rpi ${outdir}/04.tissuecut/tissue_fig/${sampleid}.ssDNA.rpi

        if [[ ! -e ${outdir}/04.tissuecut/tissue_fig/scatter_200x200_MID_gene_counts.png ]]
        then
            >&2 echo "### Tissuecut Error! Exit now!"
            exit 1
        fi
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
#        sge_queue:"stereo.q"
        job_name:"tissueCut"
        docker_url:"${dockerUrl}"
    }
    output{
        File tissueGef = "${outdir}/04.tissuecut/${sampleid}.tissue.gef"
        File tissueGem = "${outdir}/04.tissuecut/${sampleid}.tissue.gem.gz"
        File report = "${outdir}/04.tissuecut/tissuecut.stat"
        File visGef = "${outdir}/04.tissuecut/${sampleid}.gef"
        File visGem = "${outdir}/04.tissuecut/${sampleid}.gem.gz"
        File? rpi = "${outdir}/04.tissuecut/tissue_fig/${sampleid}.ssDNA.rpi"
        File binThumb = "${outdir}/04.tissuecut/dnb_merge/bin200.png"
        File tissueFigDir = "${outdir}/04.tissuecut/tissue_fig"
    }
}

task SpatialCluster{
    input{
        String dockerUrl
        String tissueGef
        String outdir="."
        String sampleid
        
        Int binSize = 200
        Int cpu = 8
        Int mem = 72
    }
    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        export NUMBA_CACHE_DIR=`pwd`
        export MPLCONFIGDIR=`pwd`
        if [[ ! -e ${outdir}/05.spatialcluster ]];then mkdir ${outdir}/05.spatialcluster;fi
        outDir=`realpath ../../../../`
        tissueGefPath=`realpath ${tissueGef}`
        tissueGefDir=`dirname $tissueGefPath`
        export SINGULARITY_BIND=$outDir,$tissueGefDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        spatialCluster \
              -i ${tissueGef} \
              -o ${outdir}/05.spatialcluster/${sampleid}.spatial.cluster.h5ad \
              -s ${binSize}
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        jobs_name:"SpatialCluster"
        docker_url:"${dockerUrl}"
    }
    output{
        File spatialClusterFile = "${outdir}/05.spatialcluster/${sampleid}.spatial.cluster.h5ad"
    }
}

task CellCut{
    input{
        String dockerUrl
        File? image
        File? rawExp
        Int validcidpass
        String outdir = "."
        String sampleid
        File? cellMask
        Int cpu = 8
        Int mem = 72
    }
    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        if [[ ! -e ${outdir}/041.cellcut ]];then mkdir ${outdir}/041.cellcut;fi

        if [[ ${validcidpass} -ne 0 ]] && [[ -n "${image}" ]] && [[ -e "${image}" ]]
        then
            echo "### Image exist and ${validcidpass} valid CID rate pass 10%."
            echo "### Start making cell bin GEF..."
            outDir=`realpath ../../../../`
            rawExpPath=`realpath ${rawExp}`
            rawExpDir=`dirname $rawExpPath`
            cellMaskPath=`realpath ${cellMask}`
            cellMaskDir=`dirname $cellMaskPath`
            export SINGULARITY_BIND=$outDir,$rawExpDir,$cellMaskDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            cellCut bgef \
                -b 1 \
                -i ${rawExp} \
                -O Transcriptomics \
                -o ${outdir}/041.cellcut/raw_w_whole.gef

            cellCut cgef \
                -i ${outdir}/041.cellcut/raw_w_whole.gef \
                -m ${cellMask} \
                -o ${outdir}/041.cellcut/${sampleid}.cellbin.gef

            cellbinstat \
                -i ${outdir}/041.cellcut/${sampleid}.cellbin.gef \
                -o ${outdir}/041.cellcut

            if [[ -e ${outdir}/041.cellcut/cellcut.stat ]] && [[ -e ${outdir}/041.cellcut/${sampleid}.cellbin.gef ]]
            then
                echo "### Remove raw_w_whole gef files..."
                rm -rf ${outdir}/041.cellcut/raw_w_whole.gef
                echo "### Remove raw_w_whole gef files DONE"
            else
                >&2 echo "### Fail to generate cell bin GEF! Exit now!"
                exit 1 
            fi
        else
            echo "### No image, skip CellCut task."
        fi
        
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        job_name:"CellBin"
        docker_url:"${dockerUrl}"
    }
    output{
        File? cellbinGef = "${outdir}/041.cellcut/${sampleid}.cellbin.gef"
        File? cellcutStat = "${outdir}/041.cellcut/cellcut.stat"
        File cellFigDir = "${outdir}/041.cellcut"
        #File? cellbinblocks = "${outdir}/041.cellcut/cellbin_blocks"
    }
}

task CellCluster{
    input{
        String dockerUrl
        File? image
        Int validcidpass
        File? cellbinGef
        String outdir="."
        String sampleid

        Int binSize = 200
        Int cpu = 8
        Int mem = 72
        String python3 = "/jdfssz3/ST_STOMICS/P20Z10200N0039_pipeline/AutoAnalysis/software_dev/Python-3.8.12/bin/python3.8"
        String cellClusterProgram = "/jdfssz3/ST_STOMICS/P20Z10200N0039_pipeline/AutoAnalysis/software/cellcluster/v1.5.0/cell_cluster.py"
        String cellshape = "/jdfssz3/ST_STOMICS/P20Z10200N0039_pipeline/AutoAnalysis/software/CellShape/cellShape.py"
    }
    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        export NUMBA_CACHE_DIR=`pwd`
        export MPLCONFIGDIR=`pwd`
        if [[ ! -e ${outdir}/051.cellcluster ]];then mkdir ${outdir}/051.cellcluster;fi

        if [[ ${validcidpass} -ne 0 ]] && [[ -n "${image}" ]] && [[ -e "${image}" ]]
        then
            outDir=`realpath ../../../../`
            cellbinGefPath=`realpath ${cellbinGef}`
            cellbinGefDir=`dirname $cellbinGefPath`
            export SINGULARITY_BIND=$outDir,$cellbinGefDir
            export PATH=/share/app/singularity/3.8.1/bin:$PATH
            cellCluster \
                  -i ${cellbinGef} \
                  -o ${outdir}/051.cellcluster/${sampleid}.cell.cluster.h5ad

            cellshape \
                -i ${cellbinGef} \
                -o ${outdir}/051.cellcluster
        else
            echo "### No image, skip CellCluster task."
        fi
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        jobs_name:"CellCluster"
        docker_url:"${dockerUrl}"
    }
    output{
        File? cellClusterFile = "${outdir}/051.cellcluster/${sampleid}.cell.cluster.h5ad"
        File? cellbinblocks = "${outdir}/051.cellcluster/cellbin_blocks"
    }
}

task Saturation{
    input{
        String dockerUrl
        File? satFile
        #Array[File]? satFiles
        String tissueGef
        String? anno_summary
        Array[String] bcstat
        Int cpu = 4
        Int mem = 72
    }
    command{
        export HDF5_USE_FILE_LOCKING=FALSE
        echo "anno_summary"
        echo ${anno_summary}
        echo "bcstat"
        echo ${sep="," bcstat}
        bcstatDir=`realpath ${bcstat[0]} | xargs dirname`
        echo $bcstatDir
        outDir=`realpath ../../../../`
        satFilePath=`realpath ${satFile}`
        satFileDir=`dirname $satFilePath`
        tissueGefPath=`realpath ${tissueGef}`
        tissueGefDir=`dirname $tissueGefPath`
        export SINGULARITY_BIND=$outDir,$satFileDir,$tissueGefDir,$bcstatDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        saturation \
            -i ${satFile} \
            --tissue ${tissueGef} \
            -o . \
            --bcstat ${sep="," bcstat} \
            --summary ${anno_summary}
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        File seqSat = "sequence_saturation.tsv"
        File bin200SatPlot = "plot_200x200_saturation.png"
        File bin1SatPlot = "plot_1x1_saturation.png"
    }
}

task Report_v2{
    input{
        String dockerUrl
        String ref
        String tissue
        Array[String] bcStat
        Array[String] starStat
        String? annoSummary
        String tissuecutStat
        String visGef
        String spatialClusterFile
        String bin200SatPlot
        File? tissueRpi
        File tissueFigDir

        String outdir="."
        String sampleid

        String bin1SatPlot
        File? cellFigDir
        File? register_registration
        File? cellClusterFile
        #File? imageinfo
        File? ipr
        Int SlideArea

        Int cpu = 1
        Int mem = 10
    }
    command{
        bcstatDir=`realpath ${bcStat[0]} | xargs dirname`
        outDir=`realpath ../../../../`
        export SINGULARITY_BIND=$bcstatDir,$outDir
        export HDF5_USE_FILE_LOCKING=FALSE
        export PATH=/share/app/singularity/3.8.1/bin:$PATH
        if [[ ! -e ${outdir}/07.report ]];then mkdir ${outdir}/07.report;fi

        if [[ -n "${tissueRpi}" ]] && [[ -e "${tissueRpi}" ]];then
            if (( ${SlideArea} <= 72 ));then
            report  \
                    -m ${sep=',' bcStat} \
                    -a ${sep=',' starStat} \
                    -g ${annoSummary} \
                    -l ${tissuecutStat} \
                    -n ${visGef} \
                    -i ${tissueRpi} \
                    -d ${spatialClusterFile} \
                    -t ${bin200SatPlot} \
                    -b ${tissueFigDir}/scatter_200x200_MID_gene_counts.png \
                    -v ${tissueFigDir}/violin_200x200_MID_gene.png \
                    -c ${tissueFigDir}/statistic_200x200_MID_gene_DNB.png \
                    --bin1Saturation ${bin1SatPlot} \
                    --bin20Saturation ${tissueFigDir}/scatter_20x20_MID_gene_counts.png \
                    --bin20violin ${tissueFigDir}/violin_20x20_MID_gene.png \
                    --bin20MIDGeneDNB ${tissueFigDir}/statistic_20x20_MID_gene_DNB.png \
                    --bin50Saturation ${tissueFigDir}/scatter_50x50_MID_gene_counts.png \
                    --bin50violin ${tissueFigDir}/violin_50x50_MID_gene.png \
                    --bin50MIDGeneDNB ${tissueFigDir}/statistic_50x50_MID_gene_DNB.png \
                    --bin100Saturation ${tissueFigDir}/scatter_100x100_MID_gene_counts.png \
                    --bin100violin ${tissueFigDir}/violin_100x100_MID_gene.png \
                    --bin100MIDGeneDNB ${tissueFigDir}/statistic_100x100_MID_gene_DNB.png \
                    --bin150Saturation ${tissueFigDir}/scatter_150x150_MID_gene_counts.png \
                    --bin150violin ${tissueFigDir}/violin_150x150_MID_gene.png \
                    --bin150MIDGeneDNB ${tissueFigDir}/statistic_150x150_MID_gene_DNB.png \
                    --cellBinGef ${cellFigDir}/${sampleid}.cellbin.gef \
                    --cellCluster ${cellClusterFile} \
                    --iprFile ${ipr} \
                    --pipelineVersion spatialRNAvisualization_v6.1.0 \
                    -s ${sampleid} \
                    --qc_metrics /opt/saw_v6.1.0_software/pipeline/report/Metrics_default.xlsx \
                    --species ${ref} \
                    --tissue ${tissue} \
                    --reference ${ref} \
                    -o ${outdir}/07.report \
                    -r standard_version
            else
                report \
                    -m ${sep=',' bcStat} \
                    -a ${sep=',' starStat} \
                    -g ${annoSummary} \
                    -l ${tissuecutStat} \
                    -n ${visGef} \
                    -i ${tissueRpi} \
                    -d ${spatialClusterFile} \
                    -t ${bin200SatPlot} \
                    -b ${tissueFigDir}/scatter_200x200_MID_gene_counts.png \
                    -v ${tissueFigDir}/violin_200x200_MID_gene.png \
                    -c ${tissueFigDir}/statistic_200x200_MID_gene_DNB.png \
                    --bin1Saturation ${bin1SatPlot} \
                    --bin20Saturation ${tissueFigDir}/scatter_20x20_MID_gene_counts.png \
                    --bin20violin ${tissueFigDir}/violin_20x20_MID_gene.png \
                    --bin20MIDGeneDNB ${tissueFigDir}/statistic_20x20_MID_gene_DNB.png \
                    --bin50Saturation ${tissueFigDir}/scatter_50x50_MID_gene_counts.png \
                    --bin50violin ${tissueFigDir}/violin_50x50_MID_gene.png \
                    --bin50MIDGeneDNB ${tissueFigDir}/statistic_50x50_MID_gene_DNB.png \
                    --bin100Saturation ${tissueFigDir}/scatter_100x100_MID_gene_counts.png \
                    --bin100violin ${tissueFigDir}/violin_100x100_MID_gene.png \
                    --bin100MIDGeneDNB ${tissueFigDir}/statistic_100x100_MID_gene_DNB.png \
                    --bin150Saturation ${tissueFigDir}/scatter_150x150_MID_gene_counts.png \
                    --bin150violin ${tissueFigDir}/violin_150x150_MID_gene.png \
                    --bin150MIDGeneDNB ${tissueFigDir}/statistic_150x150_MID_gene_DNB.png \
                    --iprFile ${ipr} \
                    --pipelineVersion spatialRNAvisualization_v6.1.0 \
                    -s ${sampleid} \
                    --qc_metrics /opt/saw_v6.1.0_software/pipeline/report/Metrics_default.xlsx \
                    --species ${ref} \
                    --tissue ${tissue} \
                    --reference ${ref} \
                    -o ${outdir}/07.report \
                    -r standard_version
            fi
 
        else
            report \
                    -m ${sep=',' bcStat} \
                    -a ${sep=',' starStat} \
                    -g ${annoSummary} \
                    -l ${tissuecutStat} \
                    -n ${visGef} \
                    -d ${spatialClusterFile} \
                    -t ${bin200SatPlot} \
                    -b ${tissueFigDir}/scatter_200x200_MID_gene_counts.png \
                    -v ${tissueFigDir}/violin_200x200_MID_gene.png \
                    -c ${tissueFigDir}/statistic_200x200_MID_gene_DNB.png \
                    --bin1Saturation ${bin1SatPlot} \
                    --bin20Saturation ${tissueFigDir}/scatter_20x20_MID_gene_counts.png \
                    --bin20violin ${tissueFigDir}/violin_20x20_MID_gene.png \
                    --bin20MIDGeneDNB ${tissueFigDir}/statistic_20x20_MID_gene_DNB.png \
                    --bin50Saturation ${tissueFigDir}/scatter_50x50_MID_gene_counts.png \
                    --bin50violin ${tissueFigDir}/violin_50x50_MID_gene.png \
                    --bin50MIDGeneDNB ${tissueFigDir}/statistic_50x50_MID_gene_DNB.png \
                    --bin100Saturation ${tissueFigDir}/scatter_100x100_MID_gene_counts.png \
                    --bin100violin ${tissueFigDir}/violin_100x100_MID_gene.png \
                    --bin100MIDGeneDNB ${tissueFigDir}/statistic_100x100_MID_gene_DNB.png \
                    --bin150Saturation ${tissueFigDir}/scatter_150x150_MID_gene_counts.png \
                    --bin150violin ${tissueFigDir}/violin_150x150_MID_gene.png \
                    --bin150MIDGeneDNB ${tissueFigDir}/statistic_150x150_MID_gene_DNB.png \
                    -s ${sampleid} \
                    --qc_metrics /opt/saw_v6.1.0_software/pipeline/report/Metrics_default.xlsx \
                    --species ${ref} \
                    --tissue ${tissue} \
                    --reference ${ref} \
                    -o ${outdir}/07.report \
                    --pipelineVersion spatialRNAvisualization_v6.1.0 \
                    -r standard_version
        fi
    }
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        jobs_name:"report"
        docker_url:"${dockerUrl}"
    }
    output{
        #File reportJson = "${outdir}/07.report/new_final_result.json"
        File reportJson = "${outdir}/07.report/${sampleid}.statistics.json"
        File htmlReport = "${outdir}/07.report/${sampleid}.report.html"
    }
}

task GetPreVersion{
    input{
        String inputdir
        String outdir = '.'
        Int cpu = 1
        Int mem = 1
    }
    command{
        mkdir -p ${outdir}/result
        cell_mask=$(find ${inputdir} -name \*.cellbin.gef | head -1)
        if [[ -n $cell_mask ]] && [[ -e $cell_mask ]]
        then
            echo "true" > ${outdir}/result/whetherDev
        else
            echo "false" > ${outdir}/result/whetherDev
        fi
    }
    output{
        File whetherDev="${outdir}/result/whetherDev"
    }
}

task Link{
    input{
        String inputdir
        String sn
        String outdir = '.'
        Int cpu = 1
        Int mem = 1
    }
    command{
        mkdir -p ${outdir}/result/00.mapping
        mkdir -p ${outdir}/result/01.merge
        mkdir -p ${outdir}/result/02.count

        ln -sf ${inputdir}/00.mapping/* ${outdir}/result/00.mapping
        ln -sf ${inputdir}/01.merge/* ${outdir}/result/01.merge
        ln -sf ${inputdir}/02.count/* ${outdir}/result/02.count

        if [[ ! -n ${outdir}/result/02.count/${sn}_raw_barcode_gene_exp.txt ]]
        then
            echo "GEM doesn't exist!"
            echo "Exit now!"
            exit 1
        fi

        cell_mask=$(find ${inputdir} -name \*.cellbin.gef | head -1)
        if [[ -n $cell_mask ]] && [[ -e $cell_mask ]];then
        echo 50
        else
        echo 300
        fi
    }
    output{
        Array[String] BcStat1 = glob("${outdir}/result/00.mapping/*barcodeMap.stat")
        Array[File] BcStat = glob("${outdir}/result/00.mapping/*barcodeMap.stat")
        String AnnoSummary1 = glob("${outdir}/result/02.count/${sn}*.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat")[0]
        File AnnoSummary = glob("${outdir}/result/02.count/${sn}*.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat")[0]
        String BCReadsCount1 = glob("${outdir}/result/01.merge/${sn}*.merge.barcodeReadsCount.txt")[0]
        File BCReadsCount = glob("${outdir}/result/01.merge/${sn}*.merge.barcodeReadsCount.txt")[0]
        String BCGeneExp1 = "${outdir}/result/02.count/${sn}.raw.gef"
        File BCGeneExp = "${outdir}/result/02.count/${sn}.raw.gef"
        String SamplingFile1 = "${outdir}/result/02.count/${sn}_raw_barcode_gene_exp.txt"
        File SamplingFile = "${outdir}/result/02.count/${sn}_raw_barcode_gene_exp.txt"
        Array[File] starStat = glob("${outdir}/result/00.mapping/*.Log.final.out")
        Int Area = read_int(stdout())
    }
}

task ReRegister_v3{
    input{
        String dockerUrl
        String imagedir
        Int FT
        String sn
        String imagetar
        String inputdir
        Int offsetx=0
        Int offsety=0
        String flip="False"
        Float rotcnt=0
        Float scaleX=0
        Float scaleY=0
        String outdir="."
        Int cpu = 8
        Int mem = 72
    }
    command <<<
        echo "SN=~{sn}"
        echo "Flip=~{flip}"
        echo "CounterClockWiseRotate90=~{rotcnt}"
        echo "OffsetX=~{offsetx}"
        echo "OffsetY=~{offsety}"
        echo "Start redo register."
        cell_mask=$(find ~{inputdir} -name \*.cellbin.gef | head -1)
        ipr=$(find ~{inputdir} -name \*.ipr | head -1)
        attr=$(find ~{inputdir} -name \*.transform.attrs.json | head -1)
        trans=$(find ~{inputdir} -name \*.transform.thumbnail.png | head -1)
        rawgef=$(find ~{inputdir} -name \*.raw.gef | head -1)

        export HDF5_USE_FILE_LOCKING=FALSE
        export TMPDIR=""
        mkdir -p ./registration
        /bin/cp -f $ipr ./~{sn}.reregist.ipr
        /bin/cp -f $attr $trans ./registration
        local_ipr=$(find ./ -maxdepth 1 -name \*.ipr | head -n 1)
        imageprePath=`realpath ~{imagedir}`
        imagepreDir=`dirname $imageprePath`
        imageTarPath=`realpath ~{imagetar}`
        imageTarDir=`dirname $imageTarPath`
        outDir=`realpath ../../../../`
        export SINGULARITY_BIND=~{inputdir},$outDir,$imagepreDir,$imageTarDir
        export PATH=/share/app/singularity/3.8.1/bin:$PATH

        if [ ~{FT} = 1 ]
        then
        singularity exec ~{dockerUrl} manualRegister \
            -i ~{imagedir} \
            -c $local_ipr \
            -v $rawgef \
            -f ~{flip} \
            -r ~{rotcnt} \
            -o ~{offsetx} ~{offsety} \
            -s ~{scaleX} ~{scaleY} \
            -a True \
            -p ~{outdir}/registration
        else
        singularity exec ~{dockerUrl} manualRegister \
            -i ~{imagedir} \
            -c $local_ipr \
            -v $rawgef \
            -f ~{flip} \
            -r ~{rotcnt} \
            -o ~{offsetx} ~{offsety} \
            -s ~{scaleX} ~{scaleY} \
            -a False \
            -p ~{outdir}/registration
        fi

        if [[ -n $cell_mask ]] && [[ -e $cell_mask ]]
        then
            singularity exec ~{dockerUrl} imageTools ipr2img \
                    -i ~{imagetar} \
                    -c $local_ipr \
                    -d tissue cell \
                    -r True \
                    -o ~{outdir}/registration
        else
            singularity exec ~{dockerUrl} imageTools ipr2img \
                    -i ~{imagetar} \
                    -c $local_ipr \
                    -d tissue \
                    -r True \
                    -o ~{outdir}/registration
        fi

        if [[ -f "~{outdir}/registration/DAPI_fov_stitched_transformed.tif" ]]
        then
            tifAll=$(find -name \*fov_stitched_transformed.tif | awk 'BEGIN{ORS=","} {print $0}')
            groupAll=$(find -name \*fov_stitched_transformed.tif | awk -F '/' '{print$NF}' | awk -F '_' 'BEGIN{ORS=","} {print$1"/Image"}')
            singularity exec ~{dockerUrl} imageTools img2rpi \
                    -i ${tifAll%?} \
                    -g ${groupAll%?} \
                    -b 1 10 50 100 \
                    -o ~{outdir}/registration/fov_stitched_transformed.rpi
        else
            singularity exec ~{dockerUrl} imageTools img2rpi \
                    -i ~{outdir}/registration/ssDNA_fov_stitched_transformed.tif \
                    -o ~{outdir}/registration/ssDNA_fov_stitched_transformed.rpi \
                    -g ssDNA \
                    -b 1 10 50 100
        fi

        echo "Registration done."
    >>>
    runtime{
        req_cpu:cpu
        req_memory:"${mem}Gi"
        #sge_queue:"stereo.q"
        job_name:"ReRegister"
    }
    output{
        File? register_registration = "./registration"
        String UpdateImage="./registration/${sn}_regist.tif"
        File? UpdateImage1="./registration/${sn}_regist.tif"
        File? register_7_result = "./registration"
        File? imageResult = "./registration/ssDNA_${sn}_regist.tif"
        File? transAttrs = "./registration/${sn}.transform.attrs.json"
        File? transThumb = "./registration/${sn}.transform.thumbnail.png"
        File? transformTif = "./registration/ssDNA_fov_stitched_transformed.tif"
        File? transformRpi = "./registration/ssDNA_fov_stitched_transformed.rpi"
        #File? rawTC = "./registration/${sn}.raw_tc.txt" ## alert
        File? cellMask = if length(glob("${outdir}/registration/DAPI_*_mask.tif")) > 0 then glob("${outdir}/registration/DAPI_*_mask.tif")[0] else "${outdir}/registration/ssDNA_${sn}_mask.tif"
        File? bbox = "./registration/${sn}_tissue_bbox.csv"
        File? tissuecuttif = if length(glob("${outdir}/registration/DAPI_*_tissue_cut.tif")) > 0 then glob("${outdir}/registration/DAPI_*_tissue_cut.tif")[0] else "${outdir}/registration/ssDNA_${sn}_tissue_cut.tif"
        File? ipr = if length(glob("${outdir}/*.ipr")) > 0 then glob("${outdir}/*.ipr")[0] else "None"
        File? SNrpi = "${outdir}/registration/${sn}.rpi"
        Array[File]? cellMaskAll = glob("${outdir}/registration/*mask.tif")
        Array[File]? tissuecuttifAll = glob("${outdir}/registration/*tissue_cut.tif")
        Array[File]? imageResultAll = glob("${outdir}/registration/*regist.tif")
        Array[File]? transformTifAll = glob("${outdir}/registration/*fov_stitched_transformed.tif")
        Array[File]? transformRpiAll = glob("${outdir}/registration/*fov_stitched_transformed.rpi")
    }
}

task Link_ReTissueCut{
    input{
        String inputdir
        String sn
        String outdir = '.'
        Int cpu = 1
        Int mem = 1
    }
    command{
        # mkdir -p ${outdir}/result/00.mapping
        # mkdir -p ${outdir}/result/01.merge
        # mkdir -p ${outdir}/result/02.count
        mkdir -p ${outdir}/result/
        cp -r ${inputdir}/00.mapping/ ${outdir}/result
        cp -r ${inputdir}/01.merge/ ${outdir}/result
        mkdir -p ${outdir}/result/02.count
        cp ${inputdir}/02.count/*[^.bam] ${outdir}/result/02.count

        # ln -sf ${inputdir}/00.mapping/*.bam ${outdir}/result/00.mapping
        # ln -sf ${inputdir}/01.merge/* ${outdir}/result/01.merge
        # ln -sf ${inputdir}/02.count/* ${outdir}/result/02.count

        if [[ ! -n ${outdir}/result/02.count/${sn}_raw_barcode_gene_exp.txt ]]
        then
            echo "GEM doesn't exist!"
            echo "Exit now!"
            exit 1
        fi
    }
    output{
        Array[String] BcStat1 = glob("${outdir}/result/00.mapping/*barcodeMap.stat")
        Array[File] BcStat = glob("${outdir}/result/00.mapping/*barcodeMap.stat")
        Array[File] BcPara = glob("${outdir}/result/00.mapping/*.bcPara")
        Array[File] bamBai = glob("${outdir}/result/00.mapping/*.Aligned.sortedByCoord.out.bam.csi")
        Array[File] fqLog = glob("${outdir}/result/00.mapping/*.Log.out")
        Array[File] progressLog = glob("${outdir}/result/00.mapping/*.Log.progress.out")
        Array[File] starSJ = glob("${outdir}/result/00.mapping/*.SJ.out.tab")
        String AnnoSummary1 = glob("${outdir}/result/02.count/${sn}*.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat")[0]
        File AnnoSummary = glob("${outdir}/result/02.count/${sn}*.Aligned.sortedByCoord.out.merge.q10.dedup.target.bam.summary.stat")[0]
        String BCReadsCount1 = glob("${outdir}/result/01.merge/${sn}*.merge.barcodeReadsCount.txt")[0]
        File BCReadsCount = glob("${outdir}/result/01.merge/${sn}*.merge.barcodeReadsCount.txt")[0]
        String BCGeneExp1 = "${outdir}/result/02.count/${sn}.raw.gef"
        File BCGeneExp = "${outdir}/result/02.count/${sn}.raw.gef"
        String SamplingFile1 = "${outdir}/result/02.count/${sn}_raw_barcode_gene_exp.txt"
        File SamplingFile = "${outdir}/result/02.count/${sn}_raw_barcode_gene_exp.txt"
        Array[File] starStat = glob("${outdir}/result/00.mapping/*.Log.final.out")
        #String Gef = "${outdir}/result/${sampleid}/${sn}.gef"
        #File Gef1 = "${outdir}/result/${sampleid}/${sn}.gef"
        #String attrs = "${outdir}/result/${sampleid}/transform/attrs.json"
        #File attrs1 = "${outdir}/result/${sampleid}/transform/attrs.json"
        #String thumb = "${outdir}/result/${sampleid}/transform/transform_thumb.png"
        #File thumb1 = "${outdir}/result/${sampleid}/transform/transform_thumb.png"
    }
}
