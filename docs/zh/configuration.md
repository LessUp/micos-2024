---
title: 配置指南
---

# 配置指南

MICOS-2024 分析参数的完整参考。

---

## 配置概述

MICOS-2024 使用基于 YAML 格式的**多层配置系统**。该系统支持：

- **模块化配置**：每个分析模块有独立设置
- **变量替代**：使用 `${variable}` 语法实现可重用值
- **配置继承**：默认值 → 项目 → 命令行覆盖
- **自动验证**：分析开始前检查配置有效性

### 配置层次

```
1. 默认值（代码内置）
   ↓
2. 配置文件（config/analysis.yaml）
   ↓
3. 环境变量（MICOS_* 变量）
   ↓
4. 命令行参数（最高优先级）
```

---

## 配置文件

### 文件结构

```
config/
├── analysis.yaml          # 主要分析参数
├── databases.yaml         # 数据库路径
├── samples.tsv           # 样本元数据
└── config.conf           # Cromwell 工作流设置
```

---

## 项目配置

### 基本项目信息

```yaml
project:
  name: "肠道微生物组研究_2024"
  description: "治疗与对照的人肠道微生物组分析"
  version: "1.0.0"
  author: "研究团队"
```

### 路径配置

```yaml
paths:
  input_dir: "data/raw_input"
  output_dir: "results"
  temp_dir: "/tmp/micos"
  log_dir: "logs"

  databases:
    kraken2: "/data/databases/kraken2/standard"
    kneaddata: "/data/databases/kneaddata/human_genome"
    humann: "/data/databases/humann"
```

---

## 资源配置

### 计算资源

```yaml
resources:
  max_threads: 16
  max_memory: "32GB"
  max_time: "24h"

  thread_allocation:
    quality_control: 8
    taxonomic_profiling: 16
    functional_annotation: 8
    diversity_analysis: 4
```

### 资源指南

| 数据集规模 | 线程 | 内存 | 临时存储 |
|:---|:---:|:---:|:---:|
| 小型（< 10 个样本） | 8 | 16 GB | 50 GB |
| 中型（10-50 个样本） | 16 | 32 GB | 200 GB |
| 大型（50-200 个样本） | 32 | 64 GB | 1 TB |
| 超大型（> 200 个样本） | 64+ | 128 GB | 2 TB+ |

---

## 模块特定参数

### 物种分类模块

```yaml
taxonomic_profiling:
  enabled: true

  kraken2:
    enabled: true
    threads: 16
    confidence: 0.1
    min_base_quality: 20
    min_hit_groups: 2
    memory_mapping: true
    use_names: true

  krona:
    enabled: true
    max_depth: 7
```

#### Kraken2 置信度参数指南

| 置信度 | 敏感性 | 精确度 | 使用场景 |
|:---:|:---:|:---:|:---|
| 0.0 | 极高 | 较低 | 探索性分析 |
| 0.1 | 高 | 良好 | **默认，平衡** |
| 0.3 | 中等 | 高 | 保守分析 |
| 0.5 | 低 | 极高 | 仅高置信度 |

### 功能注释模块

```yaml
functional_annotation:
  enabled: true

  humann:
    enabled: true
    threads: 8
    nucleotide_database: "${paths.databases}/humann/chocophlan"
    protein_database: "${paths.databases}/humann/uniref90"
    search_mode: "diamond"
    pathway_coverage: true
    gap_fill: true
    minpath: true
```

---

## 配置验证

```bash
# 验证配置
python -m micos.cli validate-config --config config/analysis.yaml

# 干运行测试配置
python -m micos.cli full-run \
  --config config/analysis.yaml \
  --dry-run
```

---

## 相关文档

- [安装指南](./guides/getting-started.md) - 入门指南
- [CLI 参考](./reference/cli.md) - 命令行选项
