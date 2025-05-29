#!/usr/bin/env Rscript

# MICOS-2024 差异丰度分析脚本
# 作者: MICOS-2024 团队
# 版本: 1.0.0

# 加载必需的库
suppressPackageStartupMessages({
  library(phyloseq)
  library(DESeq2)
  library(ALDEx2)
  library(ANCOMBC)
  library(microbiome)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(ComplexHeatmap)
  library(RColorBrewer)
  library(viridis)
})

# 命令行参数解析
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 4) {
  cat("用法: Rscript differential_abundance_analysis.R <biom_file> <metadata_file> <output_dir> <group_column> [method]\n")
  cat("方法选项: deseq2, aldex2, ancombc, all (默认: all)\n")
  quit(status = 1)
}

biom_file <- args[1]
metadata_file <- args[2]
output_dir <- args[3]
group_column <- args[4]
method <- ifelse(length(args) >= 5, args[5], "all")

# 创建输出目录
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# 日志函数
log_info <- function(msg) {
  cat(paste0("[INFO] ", Sys.time(), " - ", msg, "\n"))
}

log_error <- function(msg) {
  cat(paste0("[ERROR] ", Sys.time(), " - ", msg, "\n"))
}

# 数据加载和预处理
load_and_preprocess_data <- function(biom_file, metadata_file, group_column) {
  log_info("加载数据...")
  
  # 加载BIOM文件
  if (file.exists(biom_file)) {
    ps <- import_biom(biom_file)
  } else {
    log_error(paste("BIOM文件不存在:", biom_file))
    quit(status = 1)
  }
  
  # 加载元数据
  if (file.exists(metadata_file)) {
    metadata <- read.table(metadata_file, header = TRUE, sep = "\t", row.names = 1)
  } else {
    log_error(paste("元数据文件不存在:", metadata_file))
    quit(status = 1)
  }
  
  # 检查分组列是否存在
  if (!group_column %in% colnames(metadata)) {
    log_error(paste("分组列不存在:", group_column))
    quit(status = 1)
  }
  
  # 合并phyloseq对象
  sample_data(ps) <- sample_data(metadata)
  
  # 过滤低丰度特征
  ps_filtered <- filter_taxa(ps, function(x) sum(x > 0) > (0.1 * length(x)), TRUE)
  ps_filtered <- prune_samples(sample_sums(ps_filtered) > 1000, ps_filtered)
  
  log_info(paste("过滤后保留", ntaxa(ps_filtered), "个特征和", nsamples(ps_filtered), "个样本"))
  
  return(ps_filtered)
}

# DESeq2差异分析
run_deseq2_analysis <- function(ps, group_column, output_dir) {
  log_info("运行DESeq2差异分析...")
  
  # 转换为DESeq2对象
  dds <- phyloseq_to_deseq2(ps, as.formula(paste("~", group_column)))
  
  # 估计大小因子和离散度
  dds <- estimateSizeFactors(dds)
  dds <- estimateDispersions(dds)
  
  # 差异表达分析
  dds <- DESeq(dds, fitType = "local")
  
  # 提取结果
  res <- results(dds, alpha = 0.05)
  res_df <- as.data.frame(res)
  res_df$taxa <- rownames(res_df)
  res_df <- res_df[order(res_df$padj), ]
  
  # 保存结果
  write.csv(res_df, file.path(output_dir, "deseq2_results.csv"), row.names = FALSE)
  
  # 生成火山图
  volcano_plot <- ggplot(res_df, aes(x = log2FoldChange, y = -log10(padj))) +
    geom_point(aes(color = padj < 0.05 & abs(log2FoldChange) > 1), alpha = 0.6) +
    scale_color_manual(values = c("grey", "red")) +
    labs(title = "DESeq2 Volcano Plot",
         x = "Log2 Fold Change",
         y = "-Log10 Adjusted P-value") +
    theme_minimal() +
    geom_hline(yintercept = -log10(0.05), linetype = "dashed") +
    geom_vline(xintercept = c(-1, 1), linetype = "dashed")
  
  ggsave(file.path(output_dir, "deseq2_volcano_plot.png"), volcano_plot, 
         width = 10, height = 8, dpi = 300)
  
  return(res_df)
}

# ALDEx2差异分析
run_aldex2_analysis <- function(ps, group_column, output_dir) {
  log_info("运行ALDEx2差异分析...")
  
  # 提取OTU表和元数据
  otu_table <- as.matrix(otu_table(ps))
  metadata <- as.data.frame(sample_data(ps))
  
  # 运行ALDEx2
  aldex_result <- aldex(otu_table, metadata[[group_column]], 
                       mc.samples = 128, test = "t", effect = TRUE)
  
  # 添加显著性标记
  aldex_result$significant <- aldex_result$wi.eBH < 0.05
  
  # 保存结果
  write.csv(aldex_result, file.path(output_dir, "aldex2_results.csv"))
  
  # 生成效应大小图
  effect_plot <- ggplot(aldex_result, aes(x = effect, y = wi.eBH)) +
    geom_point(aes(color = significant), alpha = 0.6) +
    scale_color_manual(values = c("grey", "red")) +
    labs(title = "ALDEx2 Effect Size Plot",
         x = "Effect Size",
         y = "Benjamini-Hochberg P-value") +
    theme_minimal() +
    geom_hline(yintercept = 0.05, linetype = "dashed")
  
  ggsave(file.path(output_dir, "aldex2_effect_plot.png"), effect_plot,
         width = 10, height = 8, dpi = 300)
  
  return(aldex_result)
}

# ANCOM-BC差异分析
run_ancombc_analysis <- function(ps, group_column, output_dir) {
  log_info("运行ANCOM-BC差异分析...")
  
  tryCatch({
    # 运行ANCOM-BC
    ancombc_result <- ancombc(phyloseq = ps, 
                             formula = group_column,
                             p_adj_method = "BH",
                             zero_cut = 0.90,
                             lib_cut = 1000,
                             group = group_column,
                             struc_zero = TRUE,
                             neg_lb = TRUE,
                             tol = 1e-5,
                             max_iter = 100,
                             conserve = TRUE,
                             alpha = 0.05,
                             global = TRUE)
    
    # 提取结果
    res_df <- ancombc_result$res
    
    # 保存结果
    write.csv(res_df, file.path(output_dir, "ancombc_results.csv"))
    
    return(res_df)
  }, error = function(e) {
    log_error(paste("ANCOM-BC分析失败:", e$message))
    return(NULL)
  })
}

# 生成差异丰度热图
generate_heatmap <- function(ps, significant_taxa, group_column, output_dir) {
  log_info("生成差异丰度热图...")
  
  # 提取显著差异的taxa
  ps_sig <- prune_taxa(significant_taxa, ps)
  
  # 转换为相对丰度
  ps_rel <- transform_sample_counts(ps_sig, function(x) x / sum(x))
  
  # 提取数据
  otu_mat <- as.matrix(otu_table(ps_rel))
  metadata <- as.data.frame(sample_data(ps_rel))
  
  # 按组排序样本
  sample_order <- order(metadata[[group_column]])
  otu_mat <- otu_mat[, sample_order]
  metadata <- metadata[sample_order, ]
  
  # 创建注释
  col_annotation <- HeatmapAnnotation(
    Group = metadata[[group_column]],
    col = list(Group = rainbow(length(unique(metadata[[group_column]]))))
  )
  
  # 生成热图
  ht <- Heatmap(log10(otu_mat + 1e-6),
                name = "Log10(Relative Abundance)",
                top_annotation = col_annotation,
                cluster_rows = TRUE,
                cluster_columns = FALSE,
                show_column_names = FALSE,
                row_names_gp = gpar(fontsize = 8),
                column_title = "Differential Abundance Heatmap")
  
  # 保存热图
  png(file.path(output_dir, "differential_abundance_heatmap.png"), 
      width = 12, height = 10, units = "in", res = 300)
  draw(ht)
  dev.off()
}

# 生成综合报告
generate_summary_report <- function(results_list, output_dir) {
  log_info("生成综合分析报告...")
  
  # 创建汇总表
  summary_data <- data.frame(
    Method = character(),
    Significant_Taxa = integer(),
    Total_Taxa = integer(),
    Percentage = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (method_name in names(results_list)) {
    result <- results_list[[method_name]]
    if (!is.null(result)) {
      if (method_name == "deseq2") {
        sig_count <- sum(result$padj < 0.05 & abs(result$log2FoldChange) > 1, na.rm = TRUE)
        total_count <- nrow(result)
      } else if (method_name == "aldex2") {
        sig_count <- sum(result$significant, na.rm = TRUE)
        total_count <- nrow(result)
      } else if (method_name == "ancombc") {
        # ANCOM-BC结果处理
        sig_count <- sum(result$q_val < 0.05, na.rm = TRUE)
        total_count <- nrow(result)
      }
      
      summary_data <- rbind(summary_data, data.frame(
        Method = method_name,
        Significant_Taxa = sig_count,
        Total_Taxa = total_count,
        Percentage = round(sig_count / total_count * 100, 2)
      ))
    }
  }
  
  # 保存汇总表
  write.csv(summary_data, file.path(output_dir, "differential_analysis_summary.csv"), 
            row.names = FALSE)
  
  # 生成汇总图
  summary_plot <- ggplot(summary_data, aes(x = Method, y = Significant_Taxa, fill = Method)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = paste0(Significant_Taxa, " (", Percentage, "%)")), 
              vjust = -0.5) +
    labs(title = "Differential Abundance Analysis Summary",
         x = "Analysis Method",
         y = "Number of Significant Taxa") +
    theme_minimal() +
    theme(legend.position = "none")
  
  ggsave(file.path(output_dir, "analysis_summary_plot.png"), summary_plot,
         width = 10, height = 6, dpi = 300)
  
  return(summary_data)
}

# 主函数
main <- function() {
  log_info("开始差异丰度分析...")
  
  # 加载和预处理数据
  ps <- load_and_preprocess_data(biom_file, metadata_file, group_column)
  
  # 存储结果
  results_list <- list()
  
  # 根据指定方法运行分析
  if (method %in% c("deseq2", "all")) {
    results_list[["deseq2"]] <- run_deseq2_analysis(ps, group_column, output_dir)
  }
  
  if (method %in% c("aldex2", "all")) {
    results_list[["aldex2"]] <- run_aldex2_analysis(ps, group_column, output_dir)
  }
  
  if (method %in% c("ancombc", "all")) {
    results_list[["ancombc"]] <- run_ancombc_analysis(ps, group_column, output_dir)
  }
  
  # 生成综合报告
  summary_data <- generate_summary_report(results_list, output_dir)
  
  # 如果有显著结果，生成热图
  if (any(summary_data$Significant_Taxa > 0)) {
    # 获取所有方法的显著taxa
    all_sig_taxa <- c()
    
    if (!is.null(results_list[["deseq2"]])) {
      deseq2_sig <- results_list[["deseq2"]]$taxa[
        results_list[["deseq2"]]$padj < 0.05 & 
        abs(results_list[["deseq2"]]$log2FoldChange) > 1
      ]
      all_sig_taxa <- c(all_sig_taxa, deseq2_sig)
    }
    
    if (!is.null(results_list[["aldex2"]])) {
      aldex2_sig <- rownames(results_list[["aldex2"]])[results_list[["aldex2"]]$significant]
      all_sig_taxa <- c(all_sig_taxa, aldex2_sig)
    }
    
    # 去重
    all_sig_taxa <- unique(all_sig_taxa[!is.na(all_sig_taxa)])
    
    if (length(all_sig_taxa) > 0) {
      generate_heatmap(ps, all_sig_taxa, group_column, output_dir)
    }
  }
  
  log_info("差异丰度分析完成！")
  log_info(paste("结果保存在:", output_dir))
}

# 运行主函数
main()
