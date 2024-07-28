# differential_abundance_analysis.R

# 加载必要的R包
library(edgeR)

# 读取输入数据
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript differential_abundance_analysis.R <kraken_report> <output_path>")
}

kraken_report <- args[1]
output_path <- args[2]

# 检查输入文件是否存在
if (!file.exists(kraken_report)) {
  stop("Input file not found: ", kraken_report)
}

# 假设输入数据中每一行为一个样本，每一列为一个物种的丰度
data <- read.csv(kraken_report, sep = "\t", row.names = 1)

# 检查数据格式
if (ncol(data) %% 2 != 0) {
  stop("Data column number must be even to create two equal groups.")
}

# 创建分组信息，假设前半部分为组A，后半部分为组B
group <- factor(c(rep("A", ncol(data)/2), rep("B", ncol(data)/2)))

# 创建DGEList对象
y <- DGEList(counts = data, group = group)

# 过滤低丰度的基因（物种）
keep <- filterByExpr(y)
y <- y[keep, , keep.lib.sizes=FALSE]

# 规范化库尺寸
y <- calcNormFactors(y)

# 估计离散度
y <- estimateDisp
