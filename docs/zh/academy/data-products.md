---
title: 数据产物与解释
---

# 数据产物与解释

MICOS-2024 输出一组不同成熟度的分析产物。理解这些产物及其位置，有助于判断分析结果。

## 输出类型

| 产物类型 | 典型位置 | 代表什么 |
| --- | --- | --- |
| 清洗读段 | `results/quality_control/` | 经过过滤后的输入数据 |
| 分类报告 | `results/taxonomic_profiling/` | 每个样本的分类学证据摘要 |
| BIOM 表 | `results/taxonomic_profiling/feature-table.biom` | 结构化丰度矩阵 |
| 多样性产物 | `results/diversity_analysis/` | Shannon / Bray-Curtis 指标 |
| 功能表 | `results/functional_annotation/` | 通路和功能丰度 |
| 汇总报告 | `results/micos_summary_report.html` | 综合结果索引 |

## results 目录结构

```text
results/
├── quality_control/
├── taxonomic_profiling/
├── diversity_analysis/
├── functional_annotation/
└── micos_summary_report.html
```

这个结构本身就是流程依赖图：越靠后的目录，越依赖上游结果的质量。

## 稳定接口与扩展脚本

- **稳定 CLI**：`micos/cli.py` 中定义的命令及其对应输出目录
- **扩展脚本**：`scripts/` 下的分析脚本（网络分析、系统发育、扩增子、宏转录组）不属于稳定公共接口，输出位置由脚本自身决定

## 需要谨慎的地方

1. 把分类结果当成无污染、无偏差的结论
2. 把多样性指标当成无需上下文解释的证据
3. 把 `scripts/` 里的每个脚本都当成同等稳定的接口
