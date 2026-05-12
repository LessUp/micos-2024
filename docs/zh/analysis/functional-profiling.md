---
title: 功能注释分析
---

# 功能注释分析

MICOS-2024 功能注释与通路分析完整指南。

---

## 概述

功能注释通过定量基因家族和代谢通路来表征微生物群落的代谢潜力。物种分类回答"谁在那里？"，而功能注释回答"它们能做什么？"

### 核心特性

- **基因家族定量**: UniRef90 蛋白簇
- **通路分析**: MetaCyc 代谢通路
- **物种分层**: 将功能归属到特定分类群
- **多样本整合**: 比较样本间功能谱

---

## 方法论

### HUMAnN 分析流程

```
输入 Reads
    │
    ▼
[MetaPhlAn] → 物种谱
    │
    ▼
[Mapping] → 按物种分割 reads
    │
    ▼
[ChocoPhlAn] → 比对到泛基因组 (核酸)
    │
    ▼
[UniRef90] → 未比对序列比对到蛋白质
    │
    ▼
[通路重构] → MinPath + gap filling
    │
    ▼
基因家族 + 通路丰度 + 覆盖度
```

---

## 输入要求

### 数据库要求

| 数据库 | 大小 | 描述 |
|:---|:---:|:---|
| ChocoPhlAn | ~10 GB | 核酸泛基因组数据库 |
| UniRef90 | ~20 GB | 蛋白家族 (>90% 一致性) |
| MetaCyc | 内置 | 代谢通路定义 |

---

## 运行分析

### 方式 1: MICOS CLI

```bash
# 仅功能注释
python -m micos.cli run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 16
```

### 方式 2: 直接 HUMAnN

```bash
humann --input sample.fastq \
  --output output_dir/ \
  --nucleotide-database /db/chocophlan \
  --protein-database /db/uniref90 \
  --threads 16
```

---

## 参数配置

```yaml
functional_annotation:
  enabled: true

  humann:
    enabled: true
    threads: 16
    search_mode: "diamond"
    diamond_options: "--mid-sensitive"
    pathway_coverage: true
    gap_fill: true
    minpath: true
```

---

## 输出文件

```
results/functional_annotation/
├── sample_genefamilies.tsv
├── sample_genefamilies-cpm.tsv
├── sample_pathabundance.tsv
├── sample_pathcoverage.tsv
└── sample.log
```

---

## 结果解读

### 比对率

| 比对率 | 解读 | 操作 |
|:---:|:---|:---|
| < 20% | 差 | 检查数据质量和数据库 |
| 20-50% | 中等 | 新颖群落可接受 |
| 50-70% | 良好 | 标准性能 |
| > 70% | 优秀 | 高质量参考基因组 |

---

## 故障排除

### 问题: 运行太慢

```yaml
functional_annotation:
  humann:
    diamond_options: "--fast"
    threads: 32
    protein_database: "/db/uniref50"
```

---

## 相关文档

- [物种分类](./taxonomic-profiling.md) - 物种分类
- [多样性分析](./diversity-analysis.md) - 群落结构
- [配置指南](../configuration.md) - 参数详情
