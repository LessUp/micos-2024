---
title: 功能注释分析
---

# 功能注释分析

功能注释通过 HUMAnN 定量基因家族和代谢通路，回答"它们能做什么？"。

## 概述

模块为每个样本合并清洗后的读段，运行 HUMAnN 生成基因家族和通路丰度。

## HUMAnN 分析流程

```
清洗读段
    │
    ▼
合并 reads -> concatenated.fastq.gz
    │
    ▼
HUMAnN
    │
    ├── 基因家族丰度 (UniRef90)
    ├── 通路丰度 (MetaCyc)
    └── 通路覆盖度
```

模块会自动合并每个样本的配对读段和 unmatched 读段到一个 gzip 文件中作为 HUMAnN 输入。

## 运行分析

### 完整流程

在 `full-run` 中，功能注释在多样性分析之后执行，输入为 `results/quality_control/kneaddata/`。

### 仅功能注释

```bash
micos run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 16
```

## 数据库要求

HUMAnN 运行需要以下数据库（由 HUMAnN 自身管理，不在 MICOS-2024 配置中）：

| 数据库 | 大小 | 描述 |
|:---|:---:|:---|
| ChocoPhlAn | ~10 GB | 核酸泛基因组数据库 |
| UniRef90 | ~20 GB | 蛋白家族 (>90% 一致性) |

## 输出文件

```
results/functional_annotation/
├── sample_genefamilies.tsv        # 基因家族丰度
├── sample_pathabundance.tsv       # 通路丰度
└── sample_pathcoverage.tsv        # 通路覆盖度
```

## 结果解读

### 比对率

| 比对率 | 解读 | 操作 |
|:---:|:---|:---|
| < 20% | 差 | 检查数据质量和数据库 |
| 20-50% | 中等 | 新颖群落可接受 |
| 50-70% | 良好 | 标准性能 |
| > 70% | 优秀 | 高质量参考基因组 |

HUMAnN 运行较慢，大型数据集建议增加线程数。如需更快速度，可在 HUMAnN 层面使用 `--protein-database uniref50`（精度略低但更快）。

## 相关文档

- [物种分类](./taxonomic-profiling.md) - 物种分类
- [多样性分析](./diversity-analysis.md) - 群落结构
- [配置系统](../configuration.md) - 参数参考
