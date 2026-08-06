---
title: 配置系统
---

# 配置系统

MICOS-2024 使用 Pydantic 模型管理配置，支持 YAML 文件和命令行参数两种来源。

## 配置文件

| 文件 | 作用 |
| --- | --- |
| `config/analysis.yaml.template` | 项目与分析参数模板 |
| `config/databases.yaml.template` | 数据库路径模板 |
| `config/samples.tsv.template` | 样本元数据模板 |

## 配置优先级

1. 命令行参数
2. `config/analysis.yaml`
3. 代码默认值

当存在 `config/databases.yaml` 时，`validate-config` 也会读取并检查它。

## full-run 关键配置

`full-run` 主命令最关键的配置：

- 输入目录
- 输出目录
- 线程数
- KneadData 数据库路径
- Kraken2 数据库路径

## 推荐设置流程

```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
micos validate-config --config config/analysis.yaml
```

## 最小可运行配置示例

```yaml
paths:
  input_dir: "data/raw_input"
  output_dir: "results"
  databases:
    kneaddata: "/db/kneaddata/human_genome"
    kraken2: "/db/kraken2/standard"

resources:
  max_threads: 16
```

## 模板与 CLI 的关系

配置模板反映的是更大的平台视野（包括 `scripts/` 下的扩展分析），而当前稳定 CLI 只覆盖其中主链路。新增配置字段时应判断它属于稳定 CLI 契约、工作流/环境支持，还是专家脚本扩展。
