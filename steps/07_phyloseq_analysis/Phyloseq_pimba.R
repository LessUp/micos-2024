#!/usr/bin/env Rscript

# Phyloseq_pimba.R
#
# PIMBA 流程的 phyloseq 分析脚本。
# 读入 kraken-biom 生成的 BIOM 特征表与样本元数据，
# 构建 phyloseq 对象并计算 alpha/beta 多样性，输出结果图表。
#
# 用法: Rscript Phyloseq_pimba.R <biom_file> <metadata_file> <output_dir>

suppressPackageStartupMessages({
    library(phyloseq)
    library(ggplot2)
})

#' 解析命令行参数
#'
#' @return 包含 biom_path、metadata_path、output_dir 的列表
parse_args <- function() {
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) < 3) {
        stop("用法: Rscript Phyloseq_pimba.R <biom_file> <metadata_file> <output_dir>")
    }
    list(
        biom_path = args[1],
        metadata_path = args[2],
        output_dir = args[3]
    )
}

#' 构建 phyloseq 对象
#'
#' @param biom_path BIOM 文件路径
#' @param metadata_path 样本元数据文件路径
#' @return phyloseq 对象
build_phyloseq <- function(biom_path, metadata_path) {
    biom <- import_biom(BIOMfilename = biom_path)
    sd <- read.table(metadata_path, header = TRUE, sep = "\t", row.names = 1, check.names = FALSE)
    sample_data(biom) <- sample_data(sd)
    biom
}

#' 计算 alpha 多样性并输出图表
#'
#' @param physeq phyloseq 对象
#' @param output_dir 输出目录
calculate_alpha_diversity <- function(physeq, output_dir) {
    plot_richness(physeq, measures = c("Shannon", "Simpson")) +
        theme_bw()
    ggsave(file.path(output_dir, "alpha_diversity.png"), width = 8, height = 6)
}

#' 计算 beta 多样性并输出 PCoA 图
#'
#' @param physeq phyloseq 对象
#' @param output_dir 输出目录
calculate_beta_diversity <- function(physeq, output_dir) {
    ord <- ordinate(physeq, method = "PCoA", distance = "bray")
    plot_ordination(physeq, ord) +
        theme_bw()
    ggsave(file.path(output_dir, "beta_diversity_pcoa.png"), width = 8, height = 6)
}

main <- function() {
    args <- parse_args()
    dir.create(args$output_dir, showWarnings = FALSE, recursive = TRUE)
    physeq <- build_phyloseq(args$biom_path, args$metadata_path)
    calculate_alpha_diversity(physeq, args$output_dir)
    calculate_beta_diversity(physeq, args$output_dir)
    cat("Phyloseq 分析完成，结果已保存至:", args$output_dir, "\n")
}

main()
