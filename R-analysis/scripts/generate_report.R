
# generate_report.R

# 加载必要的R包
library(rmarkdown)
library(ggplot2)
library(knitr)

# 读取输入数据
args <- commandArgs(trailingOnly = TRUE)
krona_plot <- args[1]
alpha_diversity <- read.csv(args[2])
beta_diversity_plot <- args[3]
diff_abundance <- read.csv(args[4])

# 创建一个临时的R Markdown文件内容
report_content <- '
---
title: "Metagenomic Analysis Report"
output: html_document
---

## Alpha Diversity (Shannon Index)
```{r alpha_diversity, echo=FALSE}
alpha_div <- read.csv("alpha_diversity.csv")
ggplot(alpha_div, aes(x = Sample, y = Shannon)) +
    geom_bar(stat = "identity") +
    theme_minimal() +
    labs(title = "Alpha Diversity (Shannon Index)", x = "Sample", y = "Shannon Index")
```

## Beta Diversity (PCA Plot)
```{r beta_diversity, echo=FALSE}
beta_plot <- knitr::include_graphics("beta_diversity_plot.png")
plot(beta_plot)
```

## Differential Abundance Analysis
```{r diff_abundance, echo=FALSE}
diff_ab <- read.csv("diff_abundance.csv")
ggplot(diff_ab, aes(x = Gene, y = log2FoldChange)) +
    geom_bar(stat = "identity") +
    theme_minimal() +
    labs(title = "Differential Abundance Analysis", x = "Gene", y = "Log2 Fold Change")
```

## Krona Plot
```{r krona_plot, echo=FALSE, results="asis"}
krona_iframe <- paste0("<iframe src=\"", "krona_plot.html", "\" width=\"100%\" height=\"600\"></iframe>")
cat(krona_iframe)
```
'

# 保存R Markdown文件
write(report_content, file = "report.Rmd")

# 渲染报告
rmarkdown::render("report.Rmd", output_file = "metagenomic_report.html")
