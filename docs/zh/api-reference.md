# API 参考

MICOS-2024 命令行接口完整参考。

---

## 目录

- [概述](#概述)
- [全局选项](#全局选项)
- [命令](#命令)
  - [full-run](#full-run)
  - [run](#run)
  - [validate-config](#validate-config)

---

## 概述

MICOS-2024 提供统一的命令行接口 (CLI) 用于宏基因组分析。所有命令遵循以下模式：

```bash
python -m micos.cli [全局选项] <命令> [命令选项]
```

### 获取帮助

```bash
# 通用帮助
python -m micos.cli --help

# 命令特定帮助
python -m micos.cli full-run --help
python -m micos.cli run quality-control --help
```

---

## 全局选项

| 选项 | 简写 | 描述 | 默认值 |
|:---|:---:|:---|:---|
| `--config` | `-c` | 配置文件路径 | `config/analysis.yaml` |
| `--verbose` | `-v` | 启用详细输出 | `false` |
| `--log-file` | `-l` | 日志文件路径 | `logs/micos.log` |
| `--threads` | `-t` | 并行线程数 | `16` |
| `--dry-run` | `-n` | 显示将执行的操作 | `false` |
| `--version` | `-V` | 显示版本信息 | - |

### 示例

```bash
# 使用自定义配置
python -m micos.cli --config my_config.yaml full-run --input-dir data/

# 详细输出与自定义日志
python -m micos.cli --verbose --log-file analysis.log full-run ...

# 试运行（仅预览）
python -m micos.cli --dry-run full-run --input-dir data/
```

---

## 命令

### full-run

从原始 reads 到最终报告执行完整分析流程。

#### 语法

```bash
python -m micos.cli full-run [选项]
```

#### 必需参数

| 参数 | 描述 | 示例 |
|:---|:---|:---|
| `--input-dir` | 原始 FASTQ 文件目录 | `--input-dir data/raw` |
| `--results-dir` | 输出文件目录 | `--results-dir results` |

#### 数据库参数

| 参数 | 描述 | 示例 |
|:---|:---|:---|
| `--kneaddata-db` | KneadData 数据库路径 | `--kneaddata-db /db/human_genome` |
| `--kraken2-db` | Kraken2 数据库路径 | `--kraken2-db /db/kraken2_standard` |

#### 可选参数

| 参数 | 描述 | 默认值 |
|:---|:---|:---|
| `--threads` | 最大并行线程 | `16` |
| `--samples` | 逗号分隔样本列表 | 所有样本 |
| `--skip-qc` | 跳过质量控制 | `false` |
| `--skip-taxonomy` | 跳过物种分类 | `false` |
| `--skip-functional` | 跳过功能注释 | `false` |
| `--skip-diversity` | 跳过多样性分析 | `false` |

#### 示例

```bash
# 基本用法
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /db/human_genome \
  --kraken2-db /db/kraken2_standard

# 仅分析特定样本
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --samples SampleA,SampleB,SampleC

# 跳过功能分析（仅分类）
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --skip-functional
```

#### 输出结构

```
results/
├── quality_control/
│   ├── fastqc_reports/
│   └── kneaddata/
├── taxonomic_profiling/
│   ├── *.kraken
│   ├── *.report
│   ├── *.krona.html
│   └── feature-table.biom
├── functional_annotation/
│   ├── *_genefamilies.tsv
│   └── *_pathabundance.tsv
├── diversity_analysis/
│   ├── alpha_diversity/
│   └── beta_diversity/
└── report.html
```

---

### run

执行单独的分析模块。

#### 语法

```bash
python -m micos.cli run <模块> [选项]
```

#### 可用模块

| 模块 | 描述 |
|:---|:---|
| `quality-control` | FastQC 和 KneadData 处理 |
| `taxonomic-profiling` | Kraken2 分类 |
| `diversity-analysis` | QIIME2 多样性指标 |
| `functional-annotation` | HUMAnN 功能注释 |
| `summarize-results` | 生成 HTML 报告 |

---

#### quality-control

```bash
python -m micos.cli run quality-control [选项]
```

**参数**:

| 参数 | 必需 | 描述 |
|:---|:---:|:---|
| `--input-dir` | ✓ | 原始 FASTQ 目录 |
| `--output-dir` | ✓ | QC 结果目录 |
| `--kneaddata-db` | ✓ | 宿主基因组数据库 |
| `--threads` | | 并行线程 |

**示例**:
```bash
python -m micos.cli run quality-control \
  --input-dir data/raw_input \
  --output-dir results/quality_control \
  --kneaddata-db /db/human_genome \
  --threads 8
```

---

#### taxonomic-profiling

```bash
python -m micos.cli run taxonomic-profiling [选项]
```

**参数**:

| 参数 | 必需 | 描述 |
|:---|:---:|:---|
| `--input-dir` | ✓ | 清洗后 FASTQ 目录 (QC 输出) |
| `--output-dir` | ✓ | 分类结果目录 |
| `--kraken2-db` | ✓ | Kraken2 数据库路径 |
| `--confidence` | | 分类置信度阈值 |
| `--threads` | | 并行线程 |

**示例**:
```bash
python -m micos.cli run taxonomic-profiling \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/taxonomic_profiling \
  --kraken2-db /db/kraken2_standard \
  --confidence 0.1 \
  --threads 16
```

---

#### diversity-analysis

```bash
python -m micos.cli run diversity-analysis [选项]
```

**参数**:

| 参数 | 必需 | 描述 |
|:---|:---:|:---|
| `--input-biom` | ✓ | BIOM 特征表路径 |
| `--output-dir` | ✓ | 多样性结果目录 |
| `--metadata` | | 样本元数据文件 |
| `--sampling-depth` | | 稀释深度 |

**示例**:
```bash
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis \
  --metadata metadata.tsv \
  --sampling-depth 10000
```

---

#### functional-annotation

```bash
python -m micos.cli run functional-annotation [选项]
```

**参数**:

| 参数 | 必需 | 描述 |
|:---|:---:|:---|
| `--input-dir` | ✓ | 清洗后 FASTQ 目录 |
| `--output-dir` | ✓ | 功能结果目录 |
| `--threads` | | 并行线程 |
| `--nucleotide-db` | | ChocoPhlAN 数据库 |
| `--protein-db` | | UniRef 数据库 |

**示例**:
```bash
python -m micos.cli run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 8
```

---

#### summarize-results

```bash
python -m micos.cli run summarize-results [选项]
```

**参数**:

| 参数 | 必需 | 描述 |
|:---|:---:|:---|
| `--results-dir` | ✓ | 主结果目录 |
| `--output-file` | ✓ | 输出 HTML 报告路径 |
| `--format` | | 输出格式 (html, pdf) |

**示例**:
```bash
python -m micos.cli run summarize-results \
  --results-dir results \
  --output-file results/final_report.html
```

---

### validate-config

运行分析前验证配置文件。

#### 语法

```bash
python -m micos.cli validate-config [选项]
```

**参数**:

| 参数 | 必需 | 描述 |
|:---|:---:|:---|
| `--config` | | 配置文件路径 |

**示例**:
```bash
# 验证默认配置
python -m micos.cli validate-config

# 验证自定义配置
python -m micos.cli validate-config --config my_config.yaml
```

**输出**:
```
✓ 配置文件语法有效
✓ 必需字段存在
✓ 数据库路径存在
✓ 参数值在有效范围内
⚠ 警告: 未指定稀释深度 (将自动检测)
配置验证完成！
```

---

## 配置文件参考

### 位置

默认配置搜索顺序：
1. `--config` 指定的路径
2. `./config/analysis.yaml`
3. `~/.config/micos/analysis.yaml`

### 结构

```yaml
# config/analysis.yaml

project:
  name: "My_Study"
  description: "肠道样本宏基因组分析"

paths:
  input_dir: "data/raw"
  output_dir: "results"

resources:
  max_threads: 16
  max_memory: "32GB"

quality_control:
  kneaddata:
    min_quality: 20
    min_length: 50

taxonomic_profiling:
  kraken2:
    confidence: 0.1
    threads: 16

diversity_analysis:
  qiime2:
    sampling_depth: 10000

functional_annotation:
  humann:
    threads: 8
```

---

## 返回码

| 码 | 含义 |
|:---:|:---|
| 0 | 成功 |
| 1 | 一般错误 |
| 2 | 无效参数 |
| 3 | 配置错误 |
| 4 | 缺少依赖 |
| 5 | 数据库错误 |
| 6 | I/O 错误 |
| 130 | 用户中断 |

---

## 环境变量

| 变量 | 描述 | 示例 |
|:---|:---|:---|
| `MICOS_CONFIG` | 默认配置文件路径 | `/path/to/config.yaml` |
| `MICOS_THREADS` | 默认线程数 | `16` |
| `MICOS_LOG_LEVEL` | 日志级别 | `INFO`, `DEBUG` |
| `KRAKEN2_DB_PATH` | 默认 Kraken2 数据库 | `/db/kraken2` |

---

## 批量处理

### 运行多样本

```bash
# 处理多个数据集
for dataset in dataset1 dataset2 dataset3; do
  python -m micos.cli full-run \
    --input-dir "data/${dataset}" \
    --results-dir "results/${dataset}" \
    --config "config/${dataset}.yaml"
done
```

### 并行样本处理

```bash
# 使用 GNU parallel 并行处理样本
ls data/*/ | parallel -j 4 \
  'python -m micos.cli run taxonomic-profiling \
    --input-dir data/{} \
    --output-dir results/{}/taxonomy'
```

---

## 相关文档

- [配置指南](configuration.md) - 详细配置选项
- [用户手册](user_manual.md) - 分步使用指南
- [故障排除](troubleshooting.md) - 常见问题与解决方案
