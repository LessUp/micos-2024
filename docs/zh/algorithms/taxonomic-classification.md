# 物种分类算法

深入了解 MICOS-2024 物种分类模块使用的 Kraken2 算法原理和参数优化策略。

## 概述

MICOS-2024 使用 Kraken2 进行快速准确的物种分类，结合 kraken-biom 和 Krona 生成多格式的分类报告。

## Kraken2 k-mer 分类算法

### 算法原理

Kraken2 使用 **精确 k-mer 匹配** 进行快速分类：

1. **数据库构建**：将参考基因组分割为 35-mer，建立 k-mer 到分类单元的映射
2. **查询分类**：将查询序列的 k-mer 与数据库匹配，计算 LCA（最低共同祖先）
3. **置信度过滤**：根据匹配 k-mer 的比例确定分类置信度

### LCA 算法

当 k-mer 匹配到多个分类单元时，Kraken2 使用 LCA 算法确定最精确的分类层级：

$$
\text{LCA}(S_1, S_2, ..., S_n) = \text{argmin}_{T} \{ d(T, S_i) \}
$$

其中 $d(T, S_i)$ 是从根节点到 $S_i$ 经过 $T$ 的距离。

<AlgorithmCard
  title="k-mer 分类算法"
  description="将序列分解为 k-mer，查找数据库匹配，计算分类权重和 LCA。"
  complexity="O(m) 查询"
  language="python"
  codeSnippet="def classify_sequence(kmers, db):
    hits = defaultdict(int)
    for kmer in kmers:
        if kmer in db:
            for taxon in db[kmer]: hits[taxon] += 1
    if not hits: return None
    lca = compute_lca(hits.keys())
    confidence = hits[lca] / len(kmers)
    return (lca, confidence)"
/>

## 参数优化

### 置信度阈值

Kraken2 的 `--confidence` 参数控制分类的严格程度：

| 阈值 | 特点 | 适用场景 |
|------|------|---------|
| 0.0 | 最宽松 | 最大灵敏度，高假阳性 |
| 0.1 | 默认 | 平衡灵敏度和准确性 |
| 0.3 | 较严格 | 减少假阳性，可能遗漏稀有物种 |
| 0.5 | 严格 | 高置信度分类，适合临床 |

### 推荐配置

<AlgorithmCard
  title="Kraken2 分类命令"
  description="推荐的 Kraken2 分类参数配置，平衡速度和准确性。"
  language="bash"
  codeSnippet="kraken2 --db /path/to/db --threads 16 --confidence 0.1 --report sample.report --output sample.kraken --paired R1.fastq R2.fastq"
/>

## 数据库选择

### 标准数据库

| 数据库 | 大小 | 分类单元 | 适用场景 |
|--------|------|---------|---------|
| Standard | 16GB | RefSeq 细菌/病毒/真菌 | 通用分析 |
| Standard-8 | 8GB | 精简版 | 资源受限环境 |
| MiniKraken | 4GB | 子集 | 快速测试 |

### 自定义数据库

对于特定研究场景，可以构建自定义数据库：

```bash
kraken2-build --download-taxonomy --db custom_db
kraken2-build --add-to-library genome1.fna --db custom_db
kraken2-build --build --db custom_db
```

## Bracken 丰度估计

Bracken（Bayesian Reestimation of Abundance with KrakEN）通过贝叶斯方法重新估计物种丰度：

$$
P(S_i | R) \propto P(R | S_i) \cdot P(S_i)
$$

其中：
- $R$ 是观察到的读长分配
- $S_i$ 是物种 $i$ 的真实丰度
- $P(R | S_i)$ 是似然函数

### 使用 Bracken

```bash
bracken -d kraken2_db -i sample.report -o sample.bracken -l S
```

## 输出格式

### Kraken 报告格式

| 列 | 说明 |
|---|------|
| 1 | 百分比 |
| 2 | 该节点读长数 |
| 3 | 该节点及子节点总读长数 |
| 4 | 分类等级代码 |
| 5 | NCBI 分类 ID |
| 6+ | 科学名称 |

### BIOM 格式转换

MICOS-2024 使用 kraken-biom 将 Kraken 报告转换为 BIOM 格式：

```bash
kraken-biom sample.report -o sample.biom
```

BIOM 格式支持与 QIIME2、phyloseq 等下游工具的无缝集成。

## 质量控制

### 分类率监控

- **高分类率** (>70%)：数据库覆盖良好
- **中等分类率** (40-70%)：可能有未知物种
- **低分类率** (<40%)：检查数据库匹配或样本质量

### 异常检测

- 意外的高丰度物种可能指示污染
- 分类分布的异常偏斜需要调查
- 交叉样本比较可识别批次效应

---

<CitationBlock
  :citation="{
    id: 'kraken2',
    authors: 'Wood DE, Lu J, Langmead B',
    title: 'Improved metagenomic analysis with Kraken 2',
    venue: 'Genome Biology',
    year: 2019,
    doi: '10.1186/s13059-019-1891-0'
  }"
/>
