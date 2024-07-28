# 加载所需的 R 包
library(vegan)
library(ggplot2)

# 读取输入数据和输出路径
args <- commandArgs(trailingOnly = TRUE)
kraken_report <- args[1]
output_path <- args[2]
data <- read.csv(kraken_report, sep = "\t", header = FALSE)

# 打印数据结构以进行调试
print(str(data))

# 预处理数据：移除非数值型数据行
data <- data[grepl("^[0-9.]+$", data$V1) & grepl("^[0-9.]+$", data$V2), ]

# 将需要的列转换为数值型数据
data$V1 <- as.numeric(data$V1)
data$V2 <- as.numeric(data$V2)

# 再次检查是否存在NA值
if (any(is.na(data$V1)) || any(is.na(data$V2))) {
  stop("输入数据包含非数值型数据，请检查输入文件。")
}

# 检查是否存在至少两列数值型列
if (ncol(data) < 2) {
  stop("输入数据至少需要包含两列数值型数据，请检查输入文件。")
}

# 计算α多样性（Shannon指数）
alpha_div <- diversity(data[, c("V1", "V2")], index = "shannon")

# 保存α多样性结果
write.csv(alpha_div, file.path(output_path, "alpha_diversity.csv"))

# 计算β多样性（Bray-Curtis距离）
beta_div <- vegdist(data[, c("V1", "V2")], method = "bray")

# 进行PCA分析
pca <- prcomp(beta_div)
pca_df <- as.data.frame(pca$x)

# 绘制PCA图
pca_plot <- ggplot(pca_df, aes(x = PC1, y = PC2)) +
    geom_point() +
    theme_minimal() +
    labs(title = "PCA of Beta Diversity", x = "PC1", y = "PC2")

# 保存PCA图
ggsave(file.path(output_path, "beta_diversity_plot.png"), pca_plot)