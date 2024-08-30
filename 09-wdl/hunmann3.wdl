version 1.0

workflow MetaGenomeAny {
    input {
    String SEQ = "/Files/RawData/te_data/seq_input2"
    String outdir = "tmp"
    String humann_executable = "/opt/conda/bin//humann"
    String metaphlan_db = "/Files/ReferenceData/metaPhlAnDB"
    String metaphlan_index = "mpa_vJun23_CHOCOPhlAnSGB_202307"
    Int threads = 10
    String conda_path = "/root/anaconda3/bin/conda"
    String humann_regroup_table = "/opt/conda/bin/humann_regroup_table"
    String humann_join_tables = "/opt/conda/bin/humann_join_tables"
    String R_circle = "/Files/ManualData/Scripts/circle.R"
    String R_columnar = "/Files/ManualData/Scripts/columnar_stacking_diagram.R"
    String R_heatmap = "/Files/ManualData/Scripts/top50heatmap.R"
    String Rscpirt = "/opt/conda/envs/myenv/bin/Rscript"
    String py_script = "/Files/ManualData/Scripts/add_group_msg.py"
    String run_lefse = "/root/run_lefse.sh"
    String humann_config = "/opt/conda/bin/humann_config"
    String nucl_path = "/Files/ReferenceData/chocophlan/"
    String pro_path = "/Files/ReferenceData/uniref_90/"
    String uti_path = "/Files/ReferenceData/uniref_90/"
    String nucl_db = "/Files/ReferenceData/chocophlan/g__candidate_division_Zixibacteria_unclassified.s__candidate_division_Zixibacteria_bacterium.centroids.v201901_v31.ffn.gz"
    String prot_db = "/Files/ReferenceData/uniref_90/uniref90_201901b_full.dmnd"
    String mapping_file_dir = "/Files/ReferenceData/full_mapping/"
    }

    # Read seq input file
    Array[Array[String]] seq_list = read_tsv(SEQ)

    # merge fq data
    scatter (line in seq_list) {
        call MergeFqPairs {
            input: uid = line[0],
                fq1_path = line[2],
                fq2_path = line[3],
                outdir = outdir
        }
        call run_humann_task {
            input: outdir = outdir,
                uid = MergeFqPairs.UID,
                humann_executable = humann_executable,
                metaphlan_db = metaphlan_db,
                metaphlan_index = metaphlan_index,
                threads= threads,
                conda_path = conda_path,
                merge_fq_gz = MergeFqPairs.merged_file,
                humann_config = humann_config,
                nucl_path = nucl_path,
                pro_path = pro_path,
                uti_path = uti_path,
                nucl_db = nucl_db,
                prot_db = prot_db
        }
    }
    # run humann3 regroup
    call HumannRegroupTable {
        input: outdir = outdir,
            humann_regroup_table = humann_regroup_table,
            humann_join_tables = humann_join_tables,
            genef_arr = run_humann_task.genefanilyFile,
            patha_arr = run_humann_task.pathabunFile,
            pathc_arr = run_humann_task.pathcoverFile,
            mapping_file_dir = mapping_file_dir
    }
    # run pic
    output {
        Array[File] result_tsv_list = [HumannRegroupTable.output_metaCyc_genefamily, HumannRegroupTable.output_metaCyc_pathabun, HumannRegroupTable.output_metaCyc_pathcover, HumannRegroupTable.output_eggnog, HumannRegroupTable.output_go, HumannRegroupTable.output_ko, HumannRegroupTable.output_ec, HumannRegroupTable.output_pfam]
    }
}

task MergeFqPairs {
    input {
        String uid
        String fq1_path
        String fq2_path
        String outdir
        String merge_data_dir = outdir + "/" + "merge_fq/"
    }
    command {
        mkdir -p ${merge_data_dir}
        cat ${fq1_path} ${fq2_path} > ${outdir}/${uid}.fq.gz
    }
    output {
        File merged_file = "${outdir}/${uid}.fq.gz"
        String UID = uid
    }
    runtime {
        cpu: 4
    }
}

task run_humann_task {
    input {
        String outdir
        String uid
        String output_dir = outdir + "/" + "fuc_anno/"
        String humann_executable
        String metaphlan_db
        String metaphlan_index
        Int threads
        String conda_path
        String merge_fq_gz
        String humann_config
        String nucl_path
        String pro_path
        String uti_path
        File nucl_db
        File prot_db
    }
    command {
        echo "realpath of db:"
        realpath ${nucl_db}
        realpath ${prot_db}
        mkdir -p ${output_dir}/${uid}
        ${humann_config} --update database_folders nucleotide ${nucl_path}
        ${humann_config} --update database_folders protein ${pro_path}
        ${humann_config} --update database_folders utility_mapping ${uti_path}
        ${humann_executable} --threads ${threads} \
        --input ${merge_fq_gz} \
        --metaphlan-options="--bowtie2db ${metaphlan_db} --index ${metaphlan_index}" \
        --output ${output_dir}/${uid}
    }
    runtime {
        req_cpu: threads
        docker_url: "stereonote_ali_hpc_external/zc_liu_a6b1596da9c84eb29ce2563c8770f70a_private:latest"
        req_memory: "100Gi"
    }
    output {
        File genefanilyFile = "${output_dir}/${uid}/${uid}_genefamilies.tsv"
        File pathabunFile = "${output_dir}/${uid}/${uid}_pathabundance.tsv"
        File pathcoverFile = "${output_dir}/${uid}/${uid}_pathcoverage.tsv"
    }
}

task HumannRegroupTable {
  input {
    String outdir
    String mapping_file_dir
    String outdir_result = outdir + "/result"
    String humann_regroup_table
    String humann_join_tables
    String anno_dir = outdir + "/" + "fuc_anno/"
    Array[File] genef_arr
    Array[File] patha_arr
    Array[File] pathc_arr
  }

  command {
    mkdir -p ${anno_dir}
    for gFile in ~{sep=' ' genef_arr}
        do
        cp "$gFile" ${anno_dir}
        done
    for paFile in ~{sep=' ' patha_arr}
        do
        cp "$paFile" ${anno_dir}
        done
    for pcFile in ~{sep=' ' pathc_arr}
        do
        cp "$pcFile" ${anno_dir}
        done
    
    mkdir -p ${outdir_result}
    mkdir -p ${outdir_result}/metaCyc
    ${humann_join_tables} --input ${anno_dir} --output ${outdir_result}/metaCyc/metaCyc.pathAbun.tsv --file_name pathabundance
    ${humann_join_tables} --input ${anno_dir} --output ${outdir_result}/metaCyc/metaCyc.geneFamily.tsv --file_name genefamilies
    ${humann_join_tables} --input ${anno_dir} --output ${outdir_result}/metaCyc/metaCyc.pathCoverage.tsv --file_name pathcoverage
    # set outdir_result
    mkdir -p ${outdir_result}/eggnog
    mkdir -p ${outdir_result}/go
    mkdir -p ${outdir_result}/ko
    mkdir -p ${outdir_result}/ec
    mkdir -p ${outdir_result}/pfam
    # trans result
    ${humann_regroup_table} -i ${outdir_result}/metaCyc/metaCyc.geneFamily.tsv -c ${mapping_file_dir}/map_eggnog_name.txt.gz -o ${outdir_result}/eggnog/eggnog.tsv
    ${humann_regroup_table} -i ${outdir_result}/metaCyc/metaCyc.geneFamily.tsv -c ${mapping_file_dir}/map_go_uniref90.txt.gz -o ${outdir_result}/go/go.tsv
    ${humann_regroup_table} -i ${outdir_result}/metaCyc/metaCyc.geneFamily.tsv -c ${mapping_file_dir}/map_ko_uniref90.txt.gz -o ${outdir_result}/ko/ko.tsv
    ${humann_regroup_table} -i ${outdir_result}/metaCyc/metaCyc.geneFamily.tsv -c ${mapping_file_dir}/map_level4ec_uniref90.txt.gz -o ${outdir_result}/ec/ec.tsv
    ${humann_regroup_table} -i ${outdir_result}/metaCyc/metaCyc.geneFamily.tsv -c ${mapping_file_dir}/map_pfam_uniref90.txt.gz -o ${outdir_result}/pfam/pfam.tsv
  }

  output {
    File output_metaCyc_genefamily = "${outdir_result}/metaCyc/metaCyc.geneFamily.tsv"
    File output_metaCyc_pathabun = "${outdir_result}/metaCyc/metaCyc.pathAbun.tsv"
    File output_metaCyc_pathcover = "${outdir_result}/metaCyc/metaCyc.pathCoverage.tsv"
    File output_eggnog = "${outdir_result}/eggnog/eggnog.tsv"
    File output_go = "${outdir_result}/go/go.tsv"
    File output_ko = "${outdir_result}/ko/ko.tsv"
    File output_ec = "${outdir_result}/ec/ec.tsv"
    File output_pfam = "${outdir_result}/pfam/pfam.tsv"
  }

  runtime {
    docker_url: "stereonote_ali_hpc_external/zc_liu_a6b1596da9c84eb29ce2563c8770f70a_private:latest"
    cpu: 4
  }
}