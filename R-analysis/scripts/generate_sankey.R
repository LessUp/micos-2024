# 加载library
library(networkD3)
library(dplyr)

# 读取Kraken2报告文件
kraken_report <- read.table("/ResultData/kraken_taxonomy_m11213.report", header = TRUE, sep = "\t")

# 检查kraken_report数据框的内容
print(head(kraken_report))
print(names(kraken_report))

# 假设rank列实际上是U列，name列实际上是unclassified列
kraken_report$rank <- as.character(kraken_report$U)
kraken_report$name <- as.character(kraken_report$unclassified)

# 过滤无效行（例如 rank 为 'U' 的行）
kraken_report <- kraken_report %>% filter(rank != "U")

# 创建节点列表
nodes <- data.frame(name = unique(c(kraken_report$rank, kraken_report$name)))

# 创建链接列表
links <- data.frame(
  source = match(kraken_report$rank, nodes$name) - 1,
  target = match(kraken_report$name, nodes$name) - 1,
  value = kraken_report$X0
)

# 生成Sankey图
sankey <- sankeyNetwork(
  Links = links,
  Nodes = nodes,
  Source = "source",
  Target = "target",
  Value = "value",
  NodeID = "name",
  units = "Reads",
  fontSize = 12,
  nodeWidth = 30
)

# 保存Sankey图为HTML文件
saveNetwork(sankey, "sankey_diagram.html", selfcontained = FALSE)

# 或者显示Sankey图
sankey