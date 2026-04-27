# 多样性分析

MICOS-2024 微生物群落多样性分析完整指南。

---

## 目录

- [概述](#概述)
- [多样性类型](#多样性类型)
- [输入要求](#输入要求)
- [运行分析](#运行分析)
- [Alpha 多样性](#alpha-多样性)
- [Beta 多样性](#beta-多样性)
- [统计检验](#统计检验)
- [可视化](#可视化)
- [解读指南](#解读指南)
- [高级主题](#高级主题)

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

测量单个样本内的多样性：

| 指标 | 测量内容 | 最佳用途 |
|:---|:---|:---|
| **丰富度** | 类群数量 | 群落复杂性 |
| **Shannon** | 丰富度 + 均匀度 | 通用多样性 |
| **Simpson** | 优势度 | 检测优势类群 |
| **Faith's PD** | 系统发育多样性 | 进化广度 |

### Beta 多样性 (样本间)

测量样本间差异：

| 指标 | 加权方式 | 最佳用途 |
|:---|:---|:---|
| **Bray-Curtis** | 丰度 | 群落组成 |
| **Jaccard** | 存在/缺失 | 物种重叠 |
| **UniFrac** | 系统发育 | 进化周转 |
| **Aitchison** | 组分 | 零膨胀数据 |

---

## 输入要求

### 数据格式

| 格式 | 描述 | 来源 |
|:---|:---|:---|
| BIOM | 微生物组数据标准格式 | Kraken-biom, QIIME2 |
| TSV | 制表符分隔特征表 | 自定义表格 |
| QZA | QIIME2 制品 | QIIME2 导出 |

### 元数据要求

| 列 | 描述 | 所需分析 |
|:---|:---|:---|
| sample-id | 唯一标识符 | 所有分析 |
| group | 实验分组 | 组间比较 |
| subject-id | 受试者标识符 | 配对/纵向 |
| time-point | 采集时间 | 纵向 |

---

## 运行分析

### 方式 1: MICOS CLI

```bash
# 从 BIOM 文件进行多样性分析
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis \
  --metadata metadata.tsv

# 作为完整流程一部分
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16
```

### 方式 2: 直接 QIIME2

```bash
# 导入 BIOM 到 QIIME2
qiime tools import \
  --input-path feature-table.biom \
  --type 'FeatureTable[Frequency]' \
  --output-path table.qza

# 稀释表格
qiime feature-table rarefy \
  --i-table table.qza \
  --p-sampling-depth 10000 \
  --o-rarefied-table table-rarefied.qza
```

---

## Alpha 多样性

### 指标概述

#### 1. 丰富度估计器

| 指标 | 描述 | 解读 |
|:---|:---|:---|
| **观察特征数** | 原始类群计数 | 简单丰富度 |
| **Chao1** | 估计总丰富度 | 考虑未观察类群 |
| **ACE** | 基于丰度的覆盖 | 替代丰富度估计 |

#### 2. 多样性指数

| 指标 | 公式 | 范围 | 说明 |
|:---|:---|:---:|:---|
| **Shannon** | -Σ(pᵢ × ln(pᵢ)) | 0 到 ~7 | 考虑丰富度和均匀度 |
| **Simpson** | 1 - Σ(pᵢ²) | 0 到 1 | 两个随机 reads 不同的概率 |
| **逆 Simpson** | 1 / Σ(pᵢ²) | 1 到 N | 越高越多样 |

### 实现

```bash
# 计算 alpha 多样性
qiime diversity alpha \
  --i-table table.qza \
  --p-metric shannon \
  --o-alpha-diversity shannon.qza

# 多指标一次计算
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --p-metrics shannon \
  --p-metrics chao1 \
  --p-metrics observed_features \
  --p-min-depth 1000 \
  --p-max-depth 50000 \
  --m-metadata-file metadata.tsv \
  --o-visualization alpha-rarefaction.qzv
```

### 统计检验

```bash
# 组间比较
qiime diversity alpha-group-significance \
  --i-alpha-diversity shannon.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --o-visualization shannon-significance.qzv
```

**常用检验**:
- **Kruskal-Wallis**: 非参数组间比较
- **成对 Wilcoxon**: 事后比较
- **线性混合效应**: 纵向数据

---

## Beta 多样性

### 距离指标

#### 1. 组分指标

| 指标 | 类型 | 公式特征 |
|:---|:---|:---|
| **Bray-Curtis** | 基于丰度 | D = Σ\|Aᵢ - Bᵢ\| / Σ(Aᵢ + Bᵢ) |
| **Jaccard** | 二元 | D = 1 - (\|A ∩ B\| / \|A ∪ B\|) |

#### 2. 系统发育指标

| 指标 | 加权方式 | 敏感于 |
|:---|:---|:---|
| **未加权 UniFrac** | 存在/缺失 | 系统发育新颖性 |
| **加权 UniFrac** | 丰度 | 系统发育周转 |

### 实现

```bash
# 计算 beta 多样性
qiime diversity beta \
  --i-table table.qza \
  --p-metric braycurtis \
  --o-distance-matrix braycurtis.qza

# 系统发育多样性（需要树）
qiime diversity beta-phylogenetic \
  --i-table table.qza \
  --i-phylogeny tree.qza \
  --p-metric unweighted_unifrac \
  --o-distance-matrix unweighted-unifrac.qza
```

### 降维

```bash
# PCoA
qiime diversity pcoa \
  --i-distance-matrix braycurtis.qza \
  --o-pcoa braycurtis-pcoa.qza

# Emperor 可视化
qiime emperor plot \
  --i-pcoa braycurtis-pcoa.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization braycurtis-emperor.qzv
```

### 统计检验

#### PERMANOVA

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

## 可视化

### Alpha 多样性图

```python
import seaborn as sns
import matplotlib.pyplot as plt

# 箱线图
data = pd.read_csv('alpha_diversity.tsv', sep='\t')
sns.boxplot(data=data, x='group', y='shannon')
plt.title('各组 Shannon 多样性')
plt.savefig('shannon_boxplot.pdf')
```

### Beta 多样性图

```python
from skbio.stats.ordination import pcoa
from skbio import DistanceMatrix
import matplotlib.pyplot as plt

# 加载距离矩阵
dm = DistanceMatrix.read('braycurtis.tsv')

# PCoA
pcoa_results = pcoa(dm)

# 绘图
fig, ax = plt.subplots(figsize=(8, 6))
for group in metadata['group'].unique():
    mask = metadata['group'] == group
    ax.scatter(pcoa_results.samples.loc[mask, 'PC1'],
               pcoa_results.samples.loc[mask, 'PC2'],
               label=group)
ax.set_xlabel(f'PC1 ({pcoa_results.proportion_explained[0]:.1%})')
ax.set_ylabel(f'PC2 ({pcoa_results.proportion_explained[1]:.1%})')
ax.legend()
plt.savefig('pcoa_plot.pdf')
```

---

## 解读指南

### Alpha 多样性

#### 典型值（人类肠道）

| 指标 | 范围 | 说明 |
|:---|:---:|:---|
| 观察特征数 | 50-200 | 随测序深度变化 |
| Shannon | 2.5-4.5 | >4 表示高多样性 |
| Chao1 | 100-400 | 总丰富度估计 |
| Pielou's J | 0.6-0.9 | >0.8 表示均匀分布 |

#### 生态解读

| 情景 | 解读 |
|:---|:---|
| 低丰富度，高均匀度 | 少数优势种，平衡良好 |
| 高丰富度，低均匀度 | 多数稀有物种，少数优势 |
| 处理组低 alpha | 潜在菌群失调或应激 |
| 健康组高 alpha | 多样、有韧性的群落 |

### Beta 多样性

#### PCoA 解读

| 模式 | 解读 |
|:---|:---|
| 按组紧密聚类 | 强组效应 |
| 聚类重叠 | 相似群落 |
| 梯度模式 | 连续环境驱动因子 |
| 离群点 | 独特群落组成 |

---

## 高级主题

### 稀释与测序深度

```yaml
# 稀释配置
diversity_analysis:
  qiime2:
    sampling_depth: "auto"    # 自动检测
    # 或手动指定
    # sampling_depth: 10000
```

**选择测序深度**:
1. 检查稀释曲线
2. 选择曲线平台期的深度
3. 尽可能包含最多样本
4. 排除低于最小深度的样本

### 纵向分析

```python
# 纵向数据混合效应模型
from statsmodels.regression.mixed_linear_model import MixedLM

# 模型: alpha ~ time * treatment + (1|subject)
model = MixedLM.from_formula(
    'shannon ~ time_point * treatment',
    groups='subject_id',
    data=metadata
)
result = model.fit()
print(result.summary())
```

### 核心微生物组分析

```python
# 识别核心特征
# 定义核心（在 >50% 样本中存在，>0.1% 丰度）
core_features = table.view(pd.DataFrame)
core_features = core_features[
    (core_features > 0).sum(axis=1) / len(core_features.columns) > 0.5
]
core_features = core_features[core_features.sum(axis=1) > 0.001]
```

---

## 相关文档

- [物种分类](taxonomic-profiling.md) - 物种分类
- [功能注释](functional-profiling.md) - 功能分析
- [配置指南](configuration.md) - 参数设置
- [QIIME2 文档](https://docs.qiime2.org/) - 详细 QIIME2 指南
