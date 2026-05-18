# 多样性度量

深入了解 MICOS-2024 多样性分析模块使用的生态学指标和计算方法。

## 概述

多样性分析将物种丰度数据转化为生态学可解释的指标，揭示微生物群落的结构和差异。

## Alpha 多样性

Alpha 多样性度量 **单个样本内** 的物种多样性。

### 常用指数

#### Shannon 指数

$$
H' = -\sum_{i=1}^{S} p_i \ln p_i
$$

其中 $p_i$ 是物种 $i$ 的相对丰度，$S$ 是物种总数。

**特点**：
- 同时考虑丰富度和均匀度
- 对稀有物种敏感
- 值域：$[0, \ln S]$

#### Simpson 指数

$$
D = 1 - \sum_{i=1}^{S} p_i^2
$$

**特点**：
- 对优势物种敏感
- 值域：$[0, 1]$
- 解释为随机抽取两个不同物种的概率

#### Chao1 估计量

$$
S_{chao1} = S_{obs} + \frac{f_1^2}{2f_2}
$$

其中 $f_1$ 是单次观测物种数，$f_2$ 是两次观测物种数。

**用途**：估计真实物种丰富度，考虑未观测到的稀有物种。

### Hill 数

Hill 数提供了多样性指数的统一框架：

$$
^qD = \left( \sum_{i=1}^{S} p_i^q \right)^{1/(1-q)}
$$

| q 值 | 对应指数 |
|------|---------|
| 0 | 物种丰富度 |
| 1 | Shannon 指数的指数形式 |
| 2 | Simpson 指数的倒数 |

## Beta 多样性

Beta 多样性度量 **样本间** 的群落差异。

### UniFrac 距离

UniFrac 考虑系统发育关系，是微生物组分析的核心指标。

#### 加权 UniFrac

$$
d_{WU} = \sum_{i=1}^{n} l_i \left| p_i^A - p_i^B \right|
$$

其中 $l_i$ 是分支 $i$ 的长度，$p_i^A$ 和 $p_i^B$ 是分支 $i$ 在样本 A 和 B 中的丰度。

#### 不加权 UniFrac

$$
d_{UU} = \frac{\sum_{i: \delta_i=1} l_i}{\sum_i l_i}
$$

其中 $\delta_i = 1$ 当且仅当分支 $i$ 仅被一个样本包含。

<AlgorithmCard
  title="UniFrac 计算"
  description="基于系统发育树计算样本间的 UniFrac 距离，考虑分支长度和丰度差异。"
  complexity="O(n·m)"
  language="python"
  codeSnippet="def weighted_unifrac(tree, sample_a, sample_b):
    distance, total_length = 0.0, 0.0
    for node in tree.traverse():
        branch_length = node.dist
        total_length += branch_length
        abundance_a = get_branch_abundance(node, sample_a)
        abundance_b = get_branch_abundance(node, sample_b)
        distance += branch_length * abs(abundance_a - abundance_b)
    return distance / total_length"
/>

### Bray-Curtis 相异度

$$
BC = \frac{\sum_{i=1}^{S} |x_i - y_i|}{\sum_{i=1}^{S} (x_i + y_i)}
$$

**特点**：
- 不考虑系统发育关系
- 值域：$[0, 1]$
- 对丰度差异敏感

### Jaccard 指数

$$
J = \frac{|A \cap B|}{|A \cup B|}
$$

**特点**：
- 仅考虑存在/不存在
- 忽略丰度信息
- 适用于稀有物种分析

## 排序分析

### 主坐标分析 (PCoA)

PCoA 将 Beta 多样性距离矩阵投影到低维空间：

1. 计算距离矩阵的中心化矩阵
2. 特征值分解
3. 选择前 k 个主坐标

### NMDS 分析

非度量多维尺度分析 (NMDS) 保持样本间的排序关系：

- 适用于非欧氏距离
- 通过迭代优化应力函数
- stress < 0.1 表示良好的拟合

## 稀疏化分析

稀疏化（Rarefaction）用于比较不同测序深度下的多样性：

<AlgorithmCard
  title="稀疏化曲线"
  description="逐步增加采样深度，计算每个深度下的 Alpha 多样性，评估测序充分性。"
  language="python"
  codeSnippet="def rarefaction_curve(abundance, depths, metric='shannon'):
    results = []
    for depth in depths:
        subsample = subsample_counts(abundance, depth)
        diversity = calculate_alpha(subsample, metric)
        results.append((depth, diversity))
    return results"
/>

### 解读指南

- **曲线趋于平稳**：测序深度充分
- **曲线持续上升**：可能存在未检测到的稀有物种
- **曲线快速饱和**：群落多样性较低

## QIIME2 集成

MICOS-2024 通过 QIIME2 计算多样性指标：

```bash
# Alpha 多样性
qiime diversity alpha \
  --i-table table.qza \
  --p-metric shannon \
  --o-alpha-diversity shannon.qza

# Beta 多样性
qiime diversity beta \
  --i-table table.qza \
  --p-metric weighted_unifrac \
  --o-distance-matrix distance.qza
```

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

<CitationBlock
  :citation="{
    id: 'beta-diversity',
    authors: 'Lozupone C, Knight R',
    title: 'UniFrac: a new phylogenetic method for comparing microbial communities',
    venue: 'Applied and Environmental Microbiology',
    year: 2005,
    doi: '10.1128/AEM.71.12.8228-8235.2005'
  }"
/>
