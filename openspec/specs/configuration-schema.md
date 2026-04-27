# 配置文件模式定义

## 概述

MICOS-2024 使用 YAML 格式的分层配置系统，支持模板化和环境变量替换。

## 配置文件结构

### 主配置文件 (analysis.yaml)

```yaml
# =============================================================================
# MICOS-2024 分析配置
# =============================================================================

# 项目信息
project:
  name: "MICOS-2024 分析项目"
  version: "1.0.0"
  description: "宏基因组分析"
  contact:
    name: "项目负责人"
    email: "contact@example.org"

# 路径配置
paths:
  input_dir: "${PROJECT_ROOT}/data/raw_input"
  output_dir: "${PROJECT_ROOT}/results"
  temp_dir: "${PROJECT_ROOT}/temp"
  log_dir: "${PROJECT_ROOT}/logs"

# 计算资源配置
resources:
  threads: 16
  memory: "32G"
  timeout: 3600  # 秒

# 质量控制参数
quality_control:
  fastqc:
    adapters: null  # 自定义适配体文件
    contaminants: null
  kneaddata:
    quality_threshold: 20
    min_length: 50
    remove_human: true
    human_genome_db: "${DATABASES}/kneaddata/human_genome"

# 物种分类参数
taxonomic_profiling:
  kraken2:
    database: "${DATABASES}/kraken2/standard"
    confidence: 0.0
    threads: 8
  krona:
    taxonomy_db: "${DATABASES}/krona/taxonomy"

# 多样性分析参数
diversity_analysis:
  qiime2:
    sampling_depth: 10000
    metadata_file: "${PROJECT_ROOT}/config/metadata.tsv"
  phyloseq:
    rarefaction_depth: 10000

# 功能注释参数
functional_analysis:
  humann:
    chocophlan_db: "${DATABASES}/humann/chocophlan"
    uniref_db: "${DATABASES}/humann/uniref90"
    protein_db: "${DATABASES}/humann/uniprot"

# 统计分析参数
statistics:
  differential_abundance:
    methods: ["DESeq2", "ALDEx2", "ANCOMBC"]
    significance_level: 0.05
    min_abundance: 10
    min_prevalence: 0.1

# 可视化参数
visualization:
  figures:
    format: "png"
    dpi: 300
    style: "seaborn-v0_8-whitegrid"
  colors:
    palette: "Set2"

# 报告生成参数
reporting:
  output_format: "html"
  include_code: false
  include_session_info: true
```

### 数据库配置 (databases.yaml)

```yaml
# =============================================================================
# 数据库路径配置
# =============================================================================

database_root: "${HOME}/micos_databases"

quality_control:
  kneaddata:
    human_genome: "${database_root}/kneaddata/hg37_and_human_contamination"
    mouse_genome: "${database_root}/kneaddata/mm10"

taxonomy:
  kraken2:
    standard: "${database_root}/kraken2/standard"
    minikraken: "${database_root}/kraken2/minikraken_8GB"
    greengenes: "${database_root}/kraken2/greengenes"
  krona:
    taxonomy: "${database_root}/krona/taxonomy"

functional:
  humann:
    chocophlan: "${database_root}/humann/chocophlan_v296_201901"
    uniref90: "${database_root}/humann/uniref90"
    uniref50: "${database_root}/humann/uniref50"
    uniprot: "${database_root}/humann/uniprot"

diversity:
  qiime2:
    silva: "${database_root}/qiime2/silva-138-99"
    greengenes: "${database_root}/qiime2/greengenes-13-8-99"
```

## 环境变量替换

支持以下变量替换语法：

| 语法 | 描述 |
|------|------|
| `${VAR}` | 环境变量 |
| `${VAR:-default}` | 带默认值 |
| `${PROJECT_ROOT}` | 项目根目录 |
| `${DATABASES}` | 数据库根目录 |

## 配置验证

使用 JSON Schema 进行配置验证：

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["project", "paths", "resources"],
  "properties": {
    "project": {
      "type": "object",
      "required": ["name"],
      "properties": {
        "name": {"type": "string"}
      }
    }
  }
}
```

## 配置加载优先级

1. 命令行参数 (最高优先级)
2. 环境变量
3. 用户配置文件 (`~/.micos/config.yaml`)
4. 项目配置文件 (`config/analysis.yaml`)
5. 默认配置 (最低优先级)
