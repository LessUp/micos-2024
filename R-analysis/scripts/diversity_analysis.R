# diversity_analysis.R

# 加载必要的R包
library(vegan)
library(ggplot2)

# 读取输入数据
args <- commandArgs(trailingOnly = TRUE)
kraken_report <- args[1]
data <- read.csv(kraken_report, sep = "\t")

# 假设输入数据中每一行为一个样本，每一列为一个物种的丰度
# 计算α多样性（Shannon指数）
alpha_div <- diversity(data, index = "shannon")

# 保存α多样性结果
write.csv(alpha_div, "alpha_diversity.csv")

# 计算β多样性（Bray-Curtis距离）
beta_div <- vegdist(data, method = "bray")

# 进行PCA分析
pca <- prcomp(beta_div)
pca_df <- as.data.frame(pca$x)

# 绘制PCA图
pca_plot <- ggplot(pca_df, aes(x = PC1, y = PC2)) +
    geom_point() +
    theme_minimal() +
    labs(title = "PCA of Beta Diversity", x = "PC1", y = "PC2")

# 保存PCA图
ggsave("beta_diversity_plot.png", pca_plot)
