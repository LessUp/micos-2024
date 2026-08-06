---
title: 多样性度量
---

# 多样性度量

MICOS-2024 通过 QIIME2 计算两种多样性指标：

- **Alpha 多样性**（Shannon 指数）：度量单个样本内的物种多样性
- **Beta 多样性**（Bray-Curtis 相异度）：度量样本间的群落组成差异

## Alpha 多样性：Shannon 指数

Shannon 指数同时考虑丰富度（类群数量）和均匀度（丰度分布）：

$$
H' = -\sum_{i=1}^{S} p_i \ln p_i
$$

其中 $p_i$ 是物种 $i$ 的相对丰度，$S$ 是物种总数。值域为 $[0, \ln S]$，越高表示多样性越高。

**特点**：

- 对稀有物种敏感
- 是微生物组分析中最常用的 Alpha 多样性指标
- 值域：$[0, \ln S]$

## Beta 多样性：Bray-Curtis 相异度

Bray-Curtis 相异度度量两个样本在物种组成上的差异：

$$
BC = \frac{\sum_{i=1}^{S} |x_i - y_i|}{\sum_{i=1}^{S} (x_i + y_i)}
$$

其中 $x_i$ 和 $y_i$ 是物种 $i$ 在样本 A 和 B 中的丰度。

**特点**：

- 基于丰度信息，不考虑系统发育关系
- 值域：$[0, 1]$，0 表示完全相同，1 表示完全不同
- 对丰度差异敏感，是群落组成比较的常用指标

## QIIME2 集成

MICOS-2024 的 `diversity_analysis.py` 实际执行以下 QIIME2 命令：

```bash
# 1. 导入 BIOM 表
qiime tools import \
  --input-path feature-table.biom \
  --type 'FeatureTable[Frequency]' \
  --output-path feature-table.qza

# 2. Alpha 多样性 (Shannon)
qiime diversity alpha \
  --i-table feature-table.qza \
  --p-metric shannon \
  --o-alpha-diversity shannon.qza

# 3. Beta 多样性 (Bray-Curtis)
qiime diversity beta \
  --i-table feature-table.qza \
  --p-metric braycurtis \
  --o-distance-matrix bray-curtis.qza
```

## 扩展指标

QIIME2 支持更多多样性指标（如 Simpson、Chao1、UniFrac、PCoA 等），MICOS-2024 当前未集成。如需使用，可直接通过 QIIME2 命令行操作生成的 `.qza` 文件，或在 `scripts/` 中编写扩展分析脚本。

---

<CitationBlock
  :citation="{
    id: 'alpha-diversity',
    authors: 'Hill MO',
    title: 'Diversity and evenness: a unifying notation and its consequences',
    venue: 'Ecology',
    year: 1973,
    doi: '10.2307/1934352'
  }"
/>
