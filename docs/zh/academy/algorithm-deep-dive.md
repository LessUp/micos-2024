# 算法深潜

本文档深入探讨 MICOS-2024 中使用的核心算法和数学原理，面向需要理解实现细节的高级用户和研究人员。

## 序列复杂度计算

MICOS-2024 的增强质量控制模块使用 **4-mer 多样性** 结合 **Shannon 熵** 来评估序列复杂度。

### 算法原理

对于一个长度为 $L$ 的序列 $S$，我们计算所有可能的 4-mer 频率：

$$
\text{entropy}(S) = -\sum_{k \in K} \frac{c_k}{N} \log_2 \frac{c_k}{N}
$$

其中：
- $K$ 是所有可能的 4-mer 集合
- $c_k$ 是 4-mer $k$ 的出现次数
- $N$ 是总 4-mer 数量 ($L - 3$)

### 实现代码

<AlgorithmCard
  title="序列复杂度计算"
  description="使用 4-mer 多样性和 Shannon 熵计算序列复杂度，标准化到 [0, 1] 区间。"
  complexity="O(n)"
  language="python"
  codeSnippet="def calculate_sequence_complexity(sequence):
    kmers = {}
    for i in range(len(sequence) - 3):
        kmer = sequence[i:i+4]
        kmers[kmer] = kmers.get(kmer, 0) + 1
    total = sum(kmers.values())
    entropy = -sum((c/total) * np.log2(c/total) for c in kmers.values())
    return entropy / np.log2(min(4**4, total))"
/>

### 阈值建议

| 序列类型 | 推荐阈值 | 说明 |
|---------|---------|------|
| 高质量基因组 | > 0.85 | 复杂度接近理论最大值 |
| 宏基因组 | > 0.75 | 考虑物种多样性 |
| 低复杂度过滤 | < 0.5 | 可能是重复序列或污染 |

---

## GC 含量分析

GC 含量（Guanine-Cytosine content）是基因组特征的重要指标。

### 计算方法

$$
\text{GC\%} = \frac{|G| + |C|}{|A| + |T| + |G| + |C|} \times 100
$$

### 应用场景

1. **物种鉴定**：不同物种具有特征性的 GC 含量分布
2. **污染检测**：异常的 GC 含量峰值可能指示污染
3. **引物设计**：GC 含量影响 PCR 效率

---

## 质量评分解读

FastQC 生成的质量评分基于 Phred 评分系统：

$$
Q = -10 \log_{10}(P)
$$

其中 $P$ 是碱基识别错误概率。

| Phred 分数 | 错误率 | 准确率 | 质量等级 |
|-----------|--------|--------|---------|
| Q10 | 10% | 90% | 低 |
| Q20 | 1% | 99% | 中 |
| Q30 | 0.1% | 99.9% | 高 |
| Q40 | 0.01% | 99.99% | 极高 |

---

## 下一步阅读

- [质量控制算法详解](/zh/algorithms/quality-control) - FastQC 和 KneadData 参数优化
- [物种分类算法](/zh/algorithms/taxonomic-classification) - Kraken2 k-mer 算法原理
- [多样性度量](/zh/algorithms/diversity-metrics) - Alpha/Beta 多样性指数
