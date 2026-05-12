---
title: 多样性分析
---

# 多样性分析

MICOS-2024 微生物群落多样性分析完整指南。

---

## 概述

多样性分析测量微生物群落的**丰富度**（类群数量）和**均匀度**（丰度分布）。这些指标提供以下洞察：

- **群落健康**: 较高多样性通常与稳定性相关
- **处理效应**: 不同条件下多样性的变化
- **生态模式**: 空间和时间变异
- **比较研究**: 生态系统间差异

---

## 多样性类型

### Alpha 多样性 (样本内)

| 指标 | 测量内容 | 最佳用途 |
|:---|:---|:---|
| 丰富度 | 类群数量 | 群落复杂性 |
| Shannon | 丰富度 + 均匀度 | 通用多样性 |
| Simpson | 优势度 | 检测优势类群 |

### Beta 多样性 (样本间)

| 指标 | 加权方式 | 最佳用途 |
|:---|:---|:---|
| Bray-Curtis | 丰度 | 群落组成 |
| Jaccard | 存在/缺失 | 物种重叠 |
| UniFrac | 系统发育 | 进化周转 |

---

## 运行分析

### 方式 1: MICOS CLI

```bash
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis \
  --metadata metadata.tsv
```

### 方式 2: 直接 QIIME2

```bash
qiime tools import \
  --input-path feature-table.biom \
  --type 'FeatureTable[Frequency]' \
  --output-path table.qza

qiime feature-table rarefy \
  --i-table table.qza \
  --p-sampling-depth 10000 \
  --o-rarefied-table table-rarefied.qza
```

---

## Alpha 多样性

### 指标概述

| 指标 | 描述 | 解读 |
|:---|:---|:---|
| 观察特征数 | 原始类群计数 | 简单丰富度 |
| Chao1 | 估计总丰富度 | 考虑未观察类群 |
| Shannon | -Σ(pᵢ × ln(pᵢ)) | 越高越多样 |
| Simpson | 1 - Σ(pᵢ²) | 越低越均匀 |

### 典型值（人类肠道）

| 指标 | 范围 | 说明 |
|:---|:---:|:---|
| 观察特征数 | 50-200 | 随测序深度变化 |
| Shannon | 2.5-4.5 | >4 表示高多样性 |
| Chao1 | 100-400 | 总丰富度估计 |

---

## Beta 多样性

### PERMANOVA

检验组间是否在多维空间存在差异：

```bash
qiime diversity beta-group-significance \
  --i-distance-matrix braycurtis.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --p-method permanova \
  --o-visualization braycurtis-permanova.qzv
```

**解读**:
- **p < 0.05**: 组间显著差异
- **R²**: 分组解释的方差比例

---

## 解读指南

### PCoA 解读

| 模式 | 解读 |
|:---|:---|
| 按组紧密聚类 | 强组效应 |
| 聚类重叠 | 相似群落 |
| 梯度模式 | 连续环境驱动因子 |
| 离群点 | 独特群落组成 |

---

## 相关文档

- [物种分类](./taxonomic-profiling.md) - 物种分类
- [功能注释](./functional-profiling.md) - 功能分析
- [配置指南](../configuration.md) - 参数设置
