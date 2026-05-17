---
title: 配置系统
---

# 配置系统

MICOS-2024 自带一套范围较广的模板配置。它的价值很大，但也意味着要分清两层：

1. **当前稳定 CLI 真实会使用到的配置**，
2. **平台更大蓝图对应的模板配置**。

## 配置文件

| 文件 | 作用 | 说明 |
| --- | --- | --- |
| `config/analysis.yaml.template` | 项目与分析参数模板 | 范围最广，也包含更长远的分析 ambition |
| `config/databases.yaml.template` | 数据库路径模板 | 对验证与运行默认值都重要 |
| `config/samples.tsv.template` | 样本元数据模板 | 用于标准化样本输入 |

## 实际优先级

结合当前 CLI 实现，最实际的优先级是：

1. 命令行参数，
2. `config/analysis.yaml`，
3. 代码默认值。

当存在 `config/databases.yaml` 时，`validate-config` 也会读取并检查它。

## 当前稳定全流程最关心什么

`full-run` 主命令最关键的配置包括：

- 输入目录，
- 输出目录，
- 线程数，
- KneadData 数据库路径，
- Kraken2 数据库路径。

其它配置很重要，但以上几项是最直接的运行最低集。

## 推荐设置流程

```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
python -m micos.cli validate-config --config config/analysis.yaml
```

## 最小可运行配置示例

```yaml
paths:
  input_dir: "data/raw_input"
  output_dir: "results"

resources:
  max_threads: 16

quality_control:
  kneaddata:
    threads: 8

taxonomic_profiling:
  kraken2:
    threads: 16
    confidence: 0.1
```

## 为什么模板比 CLI 看起来更大

因为仓库里同时存在：

- 稳定 CLI 模块，
- 工作流资产，
- 差异分析、网络分析、系统发育、扩增子、宏转录组等脚本层扩展。

模板配置反映的是更广的平台视野，而不是在说这些内容都已经统一进稳定 CLI。

## 配置建议

如果你新增一个配置字段，先判断它属于哪层：

- 稳定 CLI 契约，
- 工作流 / 环境支持，
- 专家脚本扩展。

文档应该跟着这个判断走，而不是一股脑放在同一个抽象层里。
