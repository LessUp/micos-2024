# MICOS-2024 配置指南

## 概述

MICOS-2024使用多层配置系统，支持灵活的参数调整和自定义分析流程。本文档详细介绍了各种配置选项和最佳实践。

## 配置文件结构

```bash
config/
├── config.conf          # Cromwell工作流引擎配置
├── analysis.yaml        # 分析参数配置
├── databases.yaml       # 数据库路径配置
└── samples.tsv          # 样本元数据
```

## 分析参数配置

### 基本配置 (analysis.yaml)

```yaml
# 项目信息
project:
  name: "MICOS_Analysis"
  description: "宏基因组分析项目"
  version: "1.0.0"
  author: "Your Name"

# 输入输出路径
paths:
  input_dir: "data/raw_input"
  output_dir: "results"
  temp_dir: "tmp"
  log_dir: "logs"

# 计算资源配置
resources:
  max_threads: 16
  max_memory: "32GB"
  max_time: "24h"
```

### 质量控制参数

```yaml
quality_control:
  fastqc:
    enabled: true
    threads: 4
  
  kneaddata:
    enabled: true
    threads: 8
    min_quality: 20
    min_length: 50
    remove_intermediate: true
    bypass_trf: true
```

### 物种分类参数

```yaml
taxonomic_profiling:
  kraken2:
    enabled: true
    threads: 16
    confidence: 0.1
    min_base_quality: 20
    min_hit_groups: 2
    use_names: true
    memory_mapping: true
    
  kraken_biom:
    enabled: true
    format: "hdf5"
    
  krona:
    enabled: true
```

### QIIME2分析参数

```yaml
qiime2:
  enabled: true
  
  # 特征表过滤
  feature_filtering:
    min_frequency: 10
    min_samples: 3
    
  # 多样性分析
  diversity:
    sampling_depth: 1000
    metrics:
      alpha:
        - "shannon"
        - "chao1"
        - "simpson"
        - "observed_features"
      beta:
        - "braycurtis"
        - "jaccard"
        - "unweighted_unifrac"
        - "weighted_unifrac"
        
  # 分类学分析
  taxonomy:
    classifier_confidence: 0.7
```

## 数据库配置

### 数据库路径配置 (databases.yaml)

```yaml
# 数据库根目录
database_root: "/path/to/databases"

# 质量控制数据库
quality_control:
  kneaddata:
    human_genome: "${database_root}/kneaddata/human_genome"
    mouse_genome: "${database_root}/kneaddata/mouse_genome"

# 分类学数据库
taxonomy:
  kraken2:
    standard: "${database_root}/kraken2/standard"
    minikraken: "${database_root}/kraken2/minikraken2_v2_8GB"
    
  qiime2:
    silva_138_99_515_806: "${database_root}/qiime2/silva-138-99-515-806-nb-classifier.qza"
    greengenes_13_8_99: "${database_root}/qiime2/gg-13-8-99-nb-classifier.qza"

# 功能注释数据库
functional:
  humann:
    chocophlan: "${database_root}/humann/chocophlan"
    uniref90: "${database_root}/humann/uniref90"
```

## 样本元数据

### 元数据格式 (samples.tsv)

样本元数据文件必须是制表符分隔的文本文件，包含以下必需列：

```tsv
sample-id	group	treatment	time-point
Sample001	Control	None	T0
Sample002	Treatment	Drug_A	T24
Sample003	Treatment	Drug_B	T24
```

### 必需列说明

- **sample-id**: 唯一的样本标识符
- **group**: 样本分组（如Control、Treatment）
- **treatment**: 处理条件
- **time-point**: 时间点

### 可选列

- **subject-id**: 受试者ID（纵向研究）
- **body-site**: 采样部位
- **age**: 年龄
- **sex**: 性别
- **bmi**: 体重指数
- **description**: 样本描述

## 高级配置

### 功能分析参数

```yaml
functional_analysis:
  humann:
    enabled: false
    threads: 16
    nucleotide_database: "/path/to/chocophlan"
    protein_database: "/path/to/uniref"
```

### 统计分析参数

```yaml
statistics:
  alpha_diversity:
    test_method: "kruskal"
    pairwise: true
    
  beta_diversity:
    test_method: "permanova"
    permutations: 999
    
  differential_abundance:
    method: "deseq2"
    alpha: 0.05
    fold_change_threshold: 2.0
```

### 可视化参数

```yaml
visualization:
  plots:
    dpi: 300
    format: ["png", "svg", "pdf"]
    color_palette: "Set1"
    
  krona:
    max_depth: 7
    
  heatmap:
    top_features: 50
    clustering_method: "ward"
```

## 工作流配置

### Cromwell配置 (config.conf)

```hocon
akka {
  loglevel = "WARNING"
  logging-filter = "akka.event.slf4j.Slf4jLoggingFilter"
}

docker {
  hash-lookup {
    enabled = false
  }
}

system.dispatchers {
  engine-dispatcher {
    type = Dispatcher
    executor = "fork-join-executor"
    fork-join-executor {
      parallelism-min = 2
      parallelism-factor = 2.0
      parallelism-max = 10
    }
    throughput = 100
  }
}
```

## 配置最佳实践

### 1. 资源配置

- 根据系统资源合理设置线程数和内存限制
- 大数据集建议使用SSD存储临时文件
- 设置合适的超时时间

### 2. 数据库选择

- 小型项目可使用minikraken数据库
- 生产环境建议使用完整的标准数据库
- 定期更新数据库版本

### 3. 参数调优

- 根据数据质量调整质量控制参数
- 根据研究目的选择合适的多样性指标
- 测试不同的置信度阈值

### 4. 样本元数据

- 确保样本ID与文件名一致
- 包含足够的分组信息用于统计分析
- 避免使用特殊字符和空格

## 常见配置问题

### 问题1: 数据库路径错误

**解决方案**: 检查databases.yaml中的路径是否正确，确保数据库文件存在。

### 问题2: 内存不足

**解决方案**: 减少并行线程数，增加系统内存，或使用更小的数据库。

### 问题3: 样本元数据格式错误

**解决方案**: 确保使用制表符分隔，检查列名拼写，避免特殊字符。

## 配置模板

项目提供了以下配置模板：

- `config/analysis.yaml.template`: 分析参数模板
- `config/databases.yaml.template`: 数据库配置模板
- `config/samples.tsv.template`: 样本元数据模板

使用前请复制模板文件并根据实际情况修改：

```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
```
