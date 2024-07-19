version 1.0

# 主工作流：宏基因组分析
workflow metagenomic_analysis {
    input {
        File kraken2_db          # Kraken2数据库文件
        File reads               # 输入的测序数据文件
        File krona_db            # Krona数据库文件
    }

    # Kraken2分类任务
    call kraken2_classification {
        input:
            kraken2_db = kraken2_db,
            reads = reads
    }

    # Krona可视化任务
    call krona_visualization {
        input:
            kraken_report = kraken2_classification.kraken_report,
            krona_db = krona_db
    }

    # 多样性分析和差异丰度分析任务
    call diversity_and_differential_analysis {
        input:
            kraken_report = kraken2_classification.kraken_report
    }

    # 生成最终报告任务
    call report_generation {
        input:
            krona_plot = krona_visualization.krona_plot,
            alpha_diversity = diversity_and_differential_analysis.alpha_diversity,
            beta_diversity = diversity_and_differential_analysis.beta_diversity,
            diff_abundance = diversity_and_differential_analysis.diff_abundance
    }
}

# Kraken2分类任务定义
task kraken2_classification {
    input {
        File kraken2_db  # Kraken2数据库文件
        File reads       # 输入的测序数据文件
    }

    command {
        kraken2 --db ~{kraken2_db} --output kraken_output --report kraken_report ~{reads}
    }

    output {
        File kraken_output = "kraken_output"
        File kraken_report = "kraken_report"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_77780bcb8b504a61a96058e5383412d4_private:latest"  # 使用kraken2的Docker镜像
    }
}

# Krona可视化任务定义
task krona_visualization {
    input {
        File kraken_report  # Kraken2生成的报告文件
        File krona_db       # Krona数据库文件
    }

    command {
        ktImportTaxonomy -o krona_plot.html -db ~{krona_db} ~{kraken_report}
    }

    output {
        File krona_plot = "krona_plot.html"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_77780bcb8b504a61a96058e5383412d4_private:latest"  # 使用Krona的Docker镜像
    }
}

# 多样性分析和差异丰度分析任务定义
task diversity_and_differential_analysis {
    input {
        File kraken_report  # Kraken2生成的报告文件
    }

    command {
        Rscript /scripts/diversity_analysis.R ~{kraken_report}
        Rscript /scripts/differential_abundance_analysis.R ~{kraken_report}
    }

    output {
        File alpha_diversity = "alpha_diversity.csv"
        File beta_diversity = "beta_diversity_plot.png"
        File diff_abundance = "diff_abundance.csv"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_77780bcb8b504a61a96058e5383412d4_private:latest"  # 使用多样性和差异丰度分析的综合Docker镜像
    }
}

# 报告生成任务定义
task report_generation {
    input {
        File krona_plot       # Krona生成的可视化文件
        File alpha_diversity  # α多样性分析结果
        File beta_diversity   # β多样性分析结果
        File diff_abundance   # 差异丰度分析结果
    }

    command {
        Rscript /scripts/generate_report.R ~{krona_plot} ~{alpha_diversity} ~{beta_diversity} ~{diff_abundance}
    }

    output {
        File report = "metagenomic_report.html"
    }

    runtime {
        docker_url: "stereonote_ali_hpc_external/jiashuai.shi_77780bcb8b504a61a96058e5383412d4_private:latest"  # 使用多样性和差异丰度分析的综合Docker镜像
    }
}
