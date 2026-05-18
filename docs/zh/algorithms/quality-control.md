# 质量控制算法

深入了解 MICOS-2024 质量控制模块背后的算法和参数优化策略。

## 概述

质量控制是宏基因组分析流程的第一道关卡。MICOS-2024 集成 FastQC 和 KneadData，构建了一条完整的质量保障链路：

```
原始 FASTQ → FastQC 评估 → KneadData 去宿主 → 清洗后 FASTQ
```

## FastQC 评估指标

### Per-base 序列质量

FastQC 使用 Phred 质量评分系统量化每个碱基的可信度：

$$
Q = -10 \log_{10}(P_{error})
$$

**MICOS-2024 推荐阈值**：
- 整体平均质量 ≥ Q20（1% 错误率）
- 3' 端允许适度下降，但不应低于 Q15
- 单碱基质量低于 Q10 的比例不应超过 5%

### 序列重复水平

高重复水平可能表明：
- PCR 扩增偏倚
- 文库复杂性不足
- 测序深度过剩

**建议**：去重后重复率应低于 30%。

### Adapter 含量

Adapter 序列残留会影响下游比对和定量。MICOS-2024 在 KneadData 步骤中自动处理 adapter 去除。

## KneadData 参数优化

### 宿主去除策略

KneadData 使用 Bowtie2 进行宿主序列比对和去除：

<AlgorithmCard
  title="宿主去除算法"
  description="基于 Bowtie2 的宿主序列比对，使用 --very-sensitive 参数确保高召回率。"
  complexity="O(n·m) 建图"
  language="bash"
  codeSnippet="kneaddata --input R1.fastq.gz --input R2.fastq.gz --reference-db /path/to/human_genome --output /path/to/output --threads 16 --bowtie2-params '--very-sensitive'"
/>

### 关键参数

| 参数 | 默认值 | 推荐范围 | 说明 |
|------|--------|---------|------|
| `--threads` | 1 | 8-32 | 并行线程数 |
| `--bowtie2-params` | --sensitive | --very-sensitive | 比对灵敏度 |
| `--trimmomatic-params` | 默认 | SLIDINGWINDOW:4:20 | 质量修剪参数 |
| `--remove-intermediate` | False | True | 清理中间文件 |

### 参考数据库选择

| 宿主 | 数据库 | 大小 | 来源 |
|------|--------|------|------|
| 人类 | human_genome | ~6GB | KneadData 官方 |
| 小鼠 | mouse_genome | ~3GB | KneadData 官方 |
| 大鼠 | rat_genome | ~3GB | 自定义构建 |

## 增强质量控制

MICOS-2024 的 `enhanced_qc.py` 模块提供额外的质量控制指标：

### 序列复杂度过滤

使用 4-mer 多样性和 Shannon 熵评估序列复杂度（详见 [算法深潜](/zh/academy/algorithm-deep-dive)）。

### GC 含量偏差检测

GC 含量的异常分布可能指示：
- 宿主 DNA 污染
- PCR 扩增偏倚
- 测序系统误差

### 多阈值质量过滤

同时计算 Q10/Q20/Q30/Q40 阈值下的碱基通过率，提供全面的质量画像。

## 质量控制最佳实践

1. **始终先运行 FastQC**：在处理前了解数据质量概况
2. **选择正确的宿主数据库**：不匹配的数据库会导致低去除率
3. **保留质量报告**：FastQC 报告应存档用于追溯
4. **验证去宿主效率**：去宿主后应重新运行 FastQC 确认效果
5. **注意内存需求**：KneadData 的 Bowtie2 索引需要足够内存

---

<CitationBlock
  :citation="{
    id: 'kneaddata',
    authors: 'McIver LJ, Abu-Ali G, Franzosa EA, et al.',
    title: 'bioBakery: a meta-omic analysis environment',
    venue: 'Bioinformatics',
    year: 2018,
    doi: '10.1093/bioinformatics/btx261'
  }"
/>
