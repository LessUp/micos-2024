---
title: 配置愿景参数路线图
---

# 配置愿景参数路线图

> 本页收纳**尚未接入 CLI** 的愿景参数与名称漂移字段，作为后续模块接入时的
> 参数模板（`enforce-effective-configuration` 将不再把它们放在活动配置模板中）。
> 对应字段接入 CLI 后，再从本页移回 `config/*.template`。

## 资源限制（未实现，暂不出现于活动配置）

以下字段对应的资源限制**尚未实现**，配置了也不会生效，故从活动配置模板移除。
在资源限制真正实现前，不要在 `analysis.yaml` / `databases.yaml` 中填写它们
（生产配置 `extra="forbid"` 会直接拒绝）。

- `resources.max_memory`（如 `"32GB"`）：计划中的内存上限字段；
- `resources.memory_gb`：旧实现中的漂移字段名，已被 `max_memory` 取代；
- `resources.max_time`（如 `"24h"`）：计划中的运行时间上限字段。

## 分析参数（尚未接入 CLI）

以下参数对应模块当前使用内部默认值，接入 CLI 前不会影响实际分析行为。

```yaml
# 项目信息
project:
  name: "MICOS_Analysis"
  description: "宏基因组分析项目"
  version: "1.0.0"
  author: "Your Name"
  email: "your.email@example.com"

# 输入输出路径扩展（暂未接入）
paths:
  temp_dir: "tmp"
  log_dir: "logs"

# 质量控制参数（micos.quality_control 当前使用固定默认值）
quality_control:
  fastqc:
    enabled: true
    threads: 4
  kneaddata:
    enabled: true
    threads: 8
    min_quality: 20
    min_length: 50

# 物种分类参数（micos.taxonomic_profiling 通过 CLI --confidence 传入）
taxonomic_profiling:
  kraken2:
    confidence: 0.1
    threads: 16

# 多样性分析参数（micos.diversity_analysis 当前使用 QIIME2 默认参数）
qiime2:
  diversity:
    sampling_depth: 1000

# 功能注释参数（micos.functional_annotation 当前使用 HUMAnN 默认参数）
functional_analysis:
  humann:
    enabled: false
    threads: 16
```

## 数据库（尚未接入主链路）

以下数据库对应步骤（多样性 / 功能注释等）当前使用命令行参数或工具默认值，
接入主链路前不要放入 `databases.yaml`（`extra="forbid"` 会拒绝未知字段）。

```yaml
# QIIME2 分类器（多样性分析步骤当前未接入此配置）
# taxonomy:
#   qiime2:
#     silva_138_99_515_806: "${database_root}/qiime2/silva-138-99-515-806-nb-classifier.qza"

# HUMAnN 数据库（功能注释步骤当前使用命令行参数）
# functional:
#   humann:
#     chocophlan: "${database_root}/humann/chocophlan"
#     uniref90: "${database_root}/humann/uniref90"

# 其他未接入数据库（KEGG/COG/Pfam/CARD/ResFinder/病毒/宿主基因组等）
```

## 接入流程

1. 在 `micos/config.py` 中为对应模块新增字段并接入 `full-run` / 对应子命令；
2. 将字段移回 `config/*.template`，删除本页对应条目；
3. 补充 `docs/zh/configuration.md` 说明与配置/CLI 测试。
