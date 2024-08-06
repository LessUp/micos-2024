# 安装必要的R包
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("fbreitwieser/pavian")

# 安装 webshot 包
if (!requireNamespace("webshot", quietly = TRUE)) {
  install.packages("webshot")
}

# 手动配置 PhantomJS 路径，如果 PhantomJS 已手动安装
webshot::install_phantomjs()  # 如果已经手动安装，则不需要这行

# 加载必要的库
library(pavian)
library(ggplot2)
library(htmlwidgets)
library(webshot)

# 设置 PhantomJS 路径，如果 PhantomJS 已手动安装
webshot::phantomjs()
Sys.setenv(PATH = paste(Sys.getenv("PATH"), "/usr/local/bin", sep = ":"))

# 设置 Kraken2 报告文件的路径
kraken_report_file <- "kraken_taxonomy_m11213.report"

# 读取 Kraken2 报告文件
kraken_report <- read_report(kraken_report_file)

# 打印 Kraken2 报告文件的前几行用于调试
print(head(kraken_report))

# 生成 Sankey 图
sankey_plot <- pavian::plotly_sankey(
  kraken_report,
  top_n = 50  # 可视化前50个分类单元
)

# 保存 Sankey 图为 HTML 文件
html_file <- "sankey_diagram.html"
saveWidget(sankey_plot, file = html_file)

# 保存 Sankey 图为 PNG 文件
png_file <- "sankey_diagram.png"
webshot::webshot(html_file, file = png_file, vwidth = 1200, vheight = 800)
