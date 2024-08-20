# 设置CRAN镜像
options(repos = c(CRAN = "https://cran.r-project.org"))

# 安装必要的R包（如果尚未安装）
install.packages(c("phyloseq", "ggplot2", "vegan", "dplyr"))
BiocManager::install(c("biomformat", "DESeq2", "microbiome", "microbiomeSeq"))

# 加载R包
library(phyloseq)
library(ggplot2)
library(vegan)
library(dplyr)
library(biomformat)
library(DESeq2)
library(microbiome)
library(microbiomeSeq)

# 导入OTU表（这里假设OTU表已经是biom格式）
otu_file <- "path_to_your_otu_table.biom"
otu_table <- import_biom(otu_file)

# 导入样本数据（metadata）
sample_data_file <- "path_to_your_sample_metadata.txt"
sample_metadata <- read.table(sample_data_file, header = TRUE, sep = "\t", row.names = 1)

# 导入分类信息（taxonomy）
tax_file <- "path_to_your_taxonomy_file.txt"
taxonomy <- read.table(tax_file, header = TRUE, sep = "\t", row.names = 1)
taxonomy <- as.matrix(taxonomy)

# 构建phyloseq对象
physeq <- phyloseq(otu_table(otu_table, taxa_are_rows = TRUE),
                   sample_data(sample_metadata),
                   tax_table(taxonomy))
# 移除丰度小于某个阈值的OTU（例如10）
physeq_filtered <- filter_taxa(physeq, function(x) sum(x) > 10, TRUE)

# 去除只在少数样本中存在的OTU（例如5个样本）
physeq_filtered <- filter_taxa(physeq_filtered, function(x) sum(x > 0) > 5, TRUE)

# 计算alpha多样性
alpha_diversity <- estimate_richness(physeq_filtered, measures = c("Chao1", "Shannon"))

# 将多样性数据添加到样本数据中
sample_data(physeq_filtered)$Chao1 <- alpha_diversity$Chao1
sample_data(physeq_filtered)$Shannon <- alpha_diversity$Shannon

# 可视化Chao1指数
p1 <- plot_richness(physeq_filtered, x = "SampleType", measures = "Chao1") +
  geom_boxplot() + theme_bw()

# 可视化Shannon指数
p2 <- plot_richness(physeq_filtered, x = "SampleType", measures = "Shannon") +
  geom_boxplot() + theme_bw()

print(p1)
print(p2)

# 计算Bray-Curtis距离矩阵
bray_dist <- distance(physeq_filtered, method = "bray")

# PCA分析
pca_res <- ordinate(physeq_filtered, method = "PCA", distance = "bray")

# 可视化PCA
p3 <- plot_ordination(physeq_filtered, pca_res, color = "SampleType") +
  geom_point(size = 4) + theme_bw() + ggtitle("PCA of Bray-Curtis distance")
print(p3)

# NMDS分析
nmds_res <- ordinate(physeq_filtered, method = "NMDS", distance = "bray")

# 可视化NMDS
p4 <- plot_ordination(physeq_filtered, nmds_res, color = "SampleType") +
  geom_point(size = 4) + theme_bw() + ggtitle("NMDS of Bray-Curtis distance")
print(p4)

# 转换phyloseq对象为DESeq2对象
dds <- phyloseq_to_deseq2(physeq_filtered, ~ SampleType)

# 运行DESeq2分析
dds <- DESeq(dds)

# 获取差异分析结果
res <- results(dds)

# 筛选显著差异的分类单元
sig_res <- res[which(res$padj < 0.05), ]

# 可视化差异丰度（Volcano plot）
volcano_plot <- ggplot(sig_res, aes(x = log2FoldChange, y = -log10(pvalue))) +
  geom_point(alpha = 0.5) + theme_bw() + ggtitle("Differential Abundance Volcano Plot")
print(volcano_plot)

# 堆积条形图显示不同样本组的微生物分类组成
p5 <- plot_bar(physeq_filtered, fill = "Phylum") +
  geom_bar(stat = "identity", position = "stack") + theme_bw() +
  ggtitle("Microbial Composition at Phylum Level")
print(p5)

# 保存phyloseq对象
saveRDS(physeq_filtered, file = "physeq_filtered.rds")

# 保存差异丰度分析结果
write.csv(as.data.frame(sig_res), file = "differential_abundance_results.csv")

# 保存图像
ggsave("alpha_diversity_Chao1.png", plot = p1)
ggsave("alpha_diversity_Shannon.png", plot = p2)
ggsave("PCA_Bray_Curtis.png", plot = p3)
ggsave("NMDS_Bray_Curtis.png", plot = p4)
ggsave("Volcano_Plot.png", plot = volcano_plot)
ggsave("Microbial_Composition.png", plot = p5)
