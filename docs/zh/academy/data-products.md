---
title: 数据产物与解释
---

# 数据产物与解释

MICOS-2024 输出的不只是文件夹，而是一组不同成熟度、不同解释力度的分析证据。理解这些产物，才能真正理解平台。

## 输出类型

| 产物类型 | 典型位置 | 它代表什么 | 应该怎样看 |
| --- | --- | --- | --- |
| 清洗读段 | `results/quality_control/` | 经过过滤后的输入数据 | 后续所有分析的可信边界 |
| 分类报告 | `results/taxonomic_profiling/` | 每个样本的分类学证据摘要 | 适合组成浏览与丰度排序 |
| BIOM 表 | `results/taxonomic_profiling/feature-table.biom` | 结构化丰度矩阵 | 多样性分析的输入基础 |
| 多样性产物 | `results/diversity_analysis/` | 生态学比较视图 | 用于群落差异和组间解释 |
| 功能表 | `results/functional_annotation/` | 通路或功能特征读出 | 适合做功能假设生成 |
| 汇总报告 | 最终 HTML 结果 | 面向审阅者的综合输出 | 非开发读者最容易进入的入口 |

## 如何阅读 results 目录

```text
results/
├── quality_control/
├── taxonomic_profiling/
├── diversity_analysis/
├── functional_annotation/
└── micos_summary_report.html
```

这个结构重要，因为它本身就是流程依赖图。越靠后的目录，越依赖上游结果的质量。

## 哪些算强证据

### 当前最强信号

- `micos/cli.py` 中明确定义的命令，
- CLI 参考页能对应到的目录契约，
- `tests/test_shell_wrappers.py` 中的包装层回归测试，
- 与这些运行面相匹配的配置模板。

### 较弱但仍重要的信号

- `scripts/` 下的扩展分析，
- 比稳定 CLI 范围更广的模板配置，
- 容器与 WDL 资产所描述的目标执行生态。

## 需要谨慎的地方

宏基因组项目里最常见的三类误判是：

1. 把分类结果当成无污染、无偏差的结论，
2. 把多样性图当成无需上下文解释的证据，
3. 把仓库里的每个脚本都当成同等稳定的公共接口。

MICOS-2024 越能明确这些边界，就越显得专业。
