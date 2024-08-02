version 1.0

workflow SpatialMetabo_v1{
    input{
    String pid_param
    String sid_param
    String species_param
    String mode_param
    File HEpng_param
    File dataTxt_param
    String resolution_param
    String comparegroup_param
    File slist_param
    }
    String dockerUrl="public-library/sunwan_04456cbb970b40979d3814b1ac41ec3f_public:latest"
    call RUNpip as task1{
        input:
            pid=pid_param,
            sid=sid_param,
            species=species_param,
            mode=mode_param,
            HEpng=HEpng_param,
            dataTxt=dataTxt_param,
            resolution=resolution_param,
            comparegroup=comparegroup_param,
            slist=slist_param,
            dockerUrl=dockerUrl
    }
    output{
        File Out=task1.OutFile
    }
}

task RUNpip{
    input{
        String pid
        String sid
        String species
        String mode
        File dataTxt
        File HEpng
        String resolution
        String comparegroup
        String slist
        String dockerUrl
        Int cpu = 1
        Int mem = 8
    }
    command{
        export NUMBA_CACHE_DIR=`pwd`
        export MPLCONFIGDIR=`pwd`
        outdir=`pwd`
        sh /mnt/pipline/SpatialMetabo/main_program/Initialization_diff.sh '${pid}_${sid}' DESI '${species}' '${comparegroup}' '1.2' p 1 '${HEpng}' '${dataTxt}' 1 '${mode}' '${slist}' ${resolution}
        cd $outdir/${pid}_${sid}/Submit
        cp -r BGIResult $outdir
        cd $outdir/${pid}_${sid}/Submit/BGIResult
        rm -r cluster
        tar -zcf BGIResult.tar.gz *
        cp -r BGIResult.tar.gz $outdir/BGIResult
        cd $outdir/${pid}_${sid}
        rm -r Submit Input_files Pathway Run_me MetaX Project_Information DiffStat
    }
    runtime{
        req_cpu:1
        req_memory:"${mem}Gi"
        docker_url:"${dockerUrl}"
    }
    output{
        File OutFile = "./BGIResult"
    }
}