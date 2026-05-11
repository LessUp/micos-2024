# 物种分类分析

MICOS-2024 物种分类与多样性分析完整指南。

---

## 目录

- [概述](#概述)
- [方法论](#方法论)
- [工作流程](#工作流程)
- [输入要求](#输入要求)
- [运行分析](#运行分析)
- [参数配置](#参数配置)
- [输出文件](#输出文件)
- [结果解读](#结果解读)
- [高级主题](#高级主题)
- [故障排除](#故障排除)

---

## 概述

物种分类模块识别并定量分析宏基因组样本中的微生物种类。它将质量控制、序列分类和多样性分析整合为一个完整的分析流程。

### 核心特性

- **高速分类**: Kraken2 处理速度约 1000 万 reads/分钟
- **精确丰度估计**: Bracken 改善种水平定量
- **交互式可视化**: Krona 图表探索分类组成
- **多样性指标**: 通过 QIIME2 计算 Alpha 和 Beta 多样性
- **统计分析**: 差异丰度检验

---

## 方法论

### 分类算法 (Kraken2)

Kraken2 使用 k-mer 进行分类：

1. **数据库构建**: 参考基因组被分解为 k-mers（默认 k=35）
2. **最小化索引**: 仅存储最小化子以减少内存使用
3. **分类**: 使用 **LCA（最近公共祖先）** 算法将输入 reads 与数据库匹配
4. **置信度评分**: 基于 k-mer 覆盖度计算分类置信度

### 丰度校正 (Bracken)

Bracken 校正以下偏差：
- **基因组大小偏差**: 较大基因组贡献更多 reads
- **数据库覆盖度**: 不完整的参考数据库
- **菌株变异**: 同一物种的多个菌株

### 分类层级

| 层级 | 代码 | 示例 |
|:---|:---:|:---|
| 域 | D | Bacteria |
| 门 | P | Proteobacteria |
| 纲 | C | Gammaproteobacteria |
| 目 | O | Enterobacterales |
| 科 | F | Enterobacteriaceae |
| 属 | G | Escherichia |
| 种 | S | Escherichia coli |

---

## 工作流程

```
原始 FASTQ
    │
    ▼
质量控制 (KneadData)
    │
    ▼
物种分类 (Kraken2)
    │
    ├─► 丰度校正 (Bracken)
    │
    └─► Krona 可视化
         │
         ▼
    BIOM 格式转换
         │
         ▼
    多样性分析 (QIIME2)
```

---

## 输入要求

### 数据格式

| 格式 | 扩展名 | 配对/单端 |
|:---|:---|:---:|
| FASTQ (gzip) | `.fastq.gz` | 配对或单端 |
| FASTQ | `.fastq` | 配对或单端 |

### 命名规范

```
双端测序:
  Sample1_R1.fastq.gz
  Sample1_R2.fastq.gz

单端测序:
  Sample1.fastq.gz
```

### 质量要求

| 指标 | 最低值 | 推荐值 |
|:---|:---:|:---:|
| 读长 | ≥ 50 bp | ≥ 100 bp |
| 质量分数 (Q30) | > 70% | > 85% |
| 每样本测序深度 | 100 万 reads | 1000 万+ reads |

---

## 运行分析

### 方式 1: 完整流程

```bash
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

### 方式 2: 仅物种分类

```bash
python -m micos.cli run taxonomic-profiling \
  --input-dir data/cleaned_reads \
  --output-dir results/taxonomy \
  --threads 16 \
  --kraken2-db /path/to/kraken2_db \
  --confidence 0.1
```

### 方式 3: 手动步骤

```bash
# 步骤 1: 运行 Kraken2
kraken2 --db /path/to/kraken2_db \
  --paired sample_R1.fastq sample_R2.fastq \
  --output sample.kraken \
  --report sample.report \
  --confidence 0.1 \
  --threads 16

# 步骤 2: 运行 Bracken
bracken -d /path/to/kraken2_db \
  -i sample.report \
  -o sample.bracken \
  -r 150 \
  -l S

# 步骤 3: 转换为 BIOM
kraken-biom *.report --fmt hdf5 -o feature-table.biom

# 步骤 4: 生成 Krona
ktImportTaxonomy -o sample.krona.html sample.report
```

---

## 参数配置

### Kraken2 参数

```yaml
taxonomic_profiling:
  kraken2:
    # 分类置信度 (0.0 - 1.0)
    # 越高越严格，分类的 reads 越少
    confidence: 0.1
    
    # k-mer 匹配的最低碱基质量
    min_base_quality: 20
    
    # 是否使用内存映射数据库（更快，更多内存）
    memory_mapping: true
    
    # 在输出中包含学名
    use_names: true
```

### 置信度阈值选择

| 值 | 灵敏度 | 精确度 | 适用场景 |
|:---:|:---:|:---:|:---|
| 0.0 | 很高 | 较低 | 探索性分析 |
| 0.1 | 高 | 良好 | **默认，平衡** |
| 0.3 | 中等 | 高 | 保守分析 |
| 0.5 | 低 | 很高 | 仅高置信度 |

---

## 输出文件

### 目录结构

```
results/taxonomic_profiling/
├── raw/
│   ├── sample1.kraken      # 原始分类输出
│   └── sample1.report      # 分类报告
├── bracken/
│   └── sample1.bracken     # 校正后丰度
├── krona/
│   └── sample1.krona.html  # 交互式可视化
└── biom/
    └── feature-table.biom  # QIIME2 兼容表格
```

### Kraken2 报告格式

| 列 | 描述 | 示例 |
|:---:|:---|:---|
| 1 | reads 百分比 | 56.32 |
| 2 | reads 数量 (分支) | 563200 |
| 3 | reads 数量 (直接) | 10000 |
| 4 | 层级代码 | S |
| 5 | NCBI TaxID | 562 |
| 6 | 学名 | Escherichia coli |

---

## 结果解读

### 分类率

| 分类率 | 解读 | 操作 |
|:---:|:---|:---|
| < 50% | 高未分类率 | 检查数据库覆盖度，考虑降低置信度 |
| 50-70% | 中等 | 大多数分析可接受 |
| 70-90% | 良好 | 标准性能 |
| > 90% | 优秀 | 高质量数据和良好数据库覆盖 |

### 多样性指标

#### Alpha 多样性 (样本内)

| 指标 | 测量内容 | 范围 | 说明 |
|:---|:---|:---:|:---|
| Shannon | 多样性 (丰富度 + 均匀度) | 0 - ~7 | 越高越多样 |
| Chao1 | 丰富度估计器 | 0+ | 对稀有类群敏感 |
| Simpson | 均匀度 | 0-1 | 越低越均匀 |

**人类肠道典型值**:
- Shannon: 2.5-4.5
- 观察物种数: 50-200

---

## 高级主题

### 自定义数据库创建

```bash
# 构建自定义 Kraken2 数据库
kraken2-build --download-taxonomy --db custom_db
kraken2-build --add-to-library custom_genome.fa --db custom_db
kraken2-build --build --threads 16 --db custom_db
```

### 菌株水平分析

```yaml
# 使用更高置信度阈值进行菌株分析
taxonomic_profiling:
  kraken2:
    confidence: 0.3
    use_names: true
```

---

## 故障排除

### 问题: 分类率低

**症状**: <50% reads 被分类

**解决方案**:
```yaml
# 1. 降低置信度阈值
taxonomic_profiling:
  kraken2:
    confidence: 0.05

# 2. 使用更大的数据库
# 从 MiniKraken 切换到 Standard

# 3. 检查数据质量
# 对输入 reads 运行 FastQC
```

### 问题: 数据库加载慢

**解决方案**:
```yaml
# 使用内存映射
taxonomic_profiling:
  kraken2:
    memory_mapping: true

# 或使用 SSD 存储数据库
```

---

## 相关文档

- [多样性分析](diversity-analysis.md) - 详细多样性指标
- [功能注释](functional-profiling.md) - 功能分析
- [配置指南](configuration.md) - 参数参考
