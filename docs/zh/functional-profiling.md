# 功能注释分析

MICOS-2024 功能注释与通路分析完整指南。

---

## 目录

- [概述](#概述)
- [方法论](#方法论)
- [输入要求](#输入要求)
- [运行分析](#运行分析)
- [参数配置](#参数配置)
- [输出文件](#输出文件)
- [结果解读](#结果解读)
- [下游分析](#下游分析)
- [高级主题](#高级主题)
- [故障排除](#故障排除)

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

### 功能本体论

| 层级 | 数据库 | 描述 |
|:---|:---|:---|
| 基因家族 | UniRef90 | 蛋白序列组 (>90% 相同) |
| 通路 | MetaCyc | 精选代谢通路 |
| 模块 | KEGG | 代谢功能单元 |

---

## 输入要求

### 输入数据

| 来源 | 格式 | 描述 |
|:---|:---|:---|
| KneadData 输出 | FASTQ | 质控后、去除宿主的 reads |
| 任何清洗后 reads | FASTQ/FASTA | 去接头、质量过滤 |

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

# 作为完整流程一部分
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16
```

### 方式 2: 直接 HUMAnN

```bash
# 基本运行
humann --input sample.fastq \
  --output output_dir/ \
  --nucleotide-database /db/chocophlan \
  --protein-database /db/uniref90 \
  --threads 16
```

---

## 参数配置

### HUMAnN 配置

```yaml
functional_annotation:
  enabled: true
  
  humann:
    enabled: true
    threads: 16
    
    # 数据库路径
    nucleotide_database: "${paths.databases}/humann/chocophlan"
    protein_database: "${paths.databases}/humann/uniref90"
    
    # 搜索选项
    search_mode: "diamond"    # diamond 或 usearch
    
    # 灵敏度与速度权衡
    diamond_options: "--mid-sensitive"
    
    # 通路选项
    pathway_coverage: true
    gap_fill: true            # 填补通路缺口
    minpath: true             # 使用 MinPath 选择通路
```

---

## 输出文件

### 目录结构

```
results/functional_annotation/
├── sample_genefamilies.tsv         # 基因家族丰度
├── sample_genefamilies-cpm.tsv     # CPM 标准化
├── sample_pathabundance.tsv        # 通路丰度
├── sample_pathcoverage.tsv         # 通路覆盖度
└── sample.log                      # 运行日志
```

### 基因家族文件

| 列 | 描述 | 示例 |
|:---|:---|:---|
| # Gene Family | UniRef90 簇 | UniRef90_A0A0A0MQD6 |
| Sample1 | 丰度 (RPK) | 45.23 |

### 通路丰度文件

分层格式: `PATHWAY|Species` 显示物种贡献

示例:
```
GLYCOLYSIS|g__Bacteroides.s__Bacteroides_thetaiotaomicron    45.2
GLYCOLYSIS|g__Faecalibacterium.s__Faecalibacterium_prausnitzii    32.1
GLYCOLYSIS|unclassified    12.5
```

---

## 结果解读

### 质量指标

#### 比对率

| 比对率 | 解读 | 操作 |
|:---:|:---|:---|
| < 20% | 差 | 检查数据质量和数据库 |
| 20-50% | 中等 | 新颖群落可接受 |
| 50-70% | 良好 | 标准性能 |
| > 70% | 优秀 | 高质量参考基因组 |

### 功能丰富度

人类肠道典型范围:
- 基因家族: 100,000-500,000
- 通路: 200-400

---

## 下游分析

### 标准化

```bash
# CPM (每百万拷贝) 标准化
humann_renorm_table \
  -i sample_genefamilies.tsv \
  -o sample_genefamilies-cpm.tsv \
  --units cpm
```

### 转换到其他本体论

```bash
# 到 KEGG 正交群 (KO)
humann_regroup_table \
  -i sample_genefamilies.tsv \
  -g uniref90_ko \
  -o sample_ko.tsv

# 到 GO terms
humann_regroup_table \
  -i sample_genefamilies.tsv \
  -g uniref90_go \
  -o sample_go.tsv
```

### 多样本分析

```bash
# 合并多样本
humann_join_tables \
  -i results/functional_annotation/ \
  -o merged_genefamilies.tsv \
  --file_name genefamilies
```

---

## 高级主题

### 自定义基因家族

```bash
# 创建自定义数据库
humann_databases --download chocophlan full /custom/path

# 添加自定义序列
cat custom_genes.fa >> /custom/path/chocophlan/*.ffn
```

### 宏转录组整合

```bash
# 使用 HUMAnN 处理转录组数据
humann --input sample_rna.fastq \
  --output rnaseq_output/ \
  --bypass-prescreen  # 不跳过蛋白搜索
```

---

## 故障排除

### 问题: 运行太慢

**解决方案**:
```yaml
functional_annotation:
  humann:
    diamond_options: "--fast"
    threads: 32
    # 或使用 UniRef50 代替 UniRef90
    protein_database: "/db/uniref50"
```

### 问题: 内存错误

**解决方案**:
```bash
# 减少线程
humann --threads 8 ...

# 使用内存高效模式
humann --memory-use minimum ...

# 顺序处理样本而非并行
```

### 问题: 大部分 reads 未比对

**诊断步骤**:
```bash
# 1. 检查输入质量
fastqc sample.fastq

# 2. 验证数据库安装
ls -lh /db/humann/chocophlan/
ls -lh /db/humann/uniref90/

# 3. 检查 MetaPhlAn 输出中的物种覆盖度
# 如果未知物种占主导，需要更广泛的数据库
```

---

## 相关文档

- [物种分类](taxonomic-profiling.md) - 物种分类
- [多样性分析](diversity-analysis.md) - 群落结构
- [配置指南](configuration.md) - 参数详情
- [HUMAnN 文档](https://huttenhower.sph.harvard.edu/humann) - 官方 HUMAnN 文档
