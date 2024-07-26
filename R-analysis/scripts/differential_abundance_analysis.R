# differential_abundance_analysis.R

# 加载必要的R包
library(DESeq2)
library(edgeR)

# 读取输入数据
args <- commandArgs(trailingOnly = TRUE)
kraken_report <- args[1]
output_path <- args[2]
data <- read.csv(kraken_report, sep = "\t")

# 假设输入数据中每一行为一个样本，每一列为一个物种的丰度
# 创建分组信息，假设前半部分为组A，后半部分为组B
group <- factor(c(rep("A", nrow(data)/2), rep("B", nrow(data)/2)))

# 使用DESeq2进行差异丰度分析
dds <- DESeqDataSetFromMatrix(countData = data, colData = data.frame(group), design = ~ group)
dds <- DESeq(dds)
res <- results(dds)

# 保存差异丰度分析结果
write.csv(as.data.frame(res), file.path(output_path, "diff_abundance.csv"))