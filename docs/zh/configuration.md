---
title: 配置系统
---

# 配置系统

MICOS-2024 使用 Pydantic 模型管理配置，支持 YAML 文件和命令行参数两种来源。

## 配置文件

| 文件 | 作用 |
| --- | --- |
| `config/analysis.yaml.template` | 分析参数模板（只含已接入 CLI 的字段） |
| `config/databases.yaml.template` | 数据库路径模板（只含已接入 CLI 的字段） |
| `config/samples.tsv.template` | 样本元数据模板 |

## 严格校验（fail-closed）

生产配置模型统一 `extra="forbid"`：

- 未知字段（拼写错误、模板外字段）→ 立即失败；
- 错误类型 → 校验失败；
- 空或损坏的 YAML → 配置错误退出；
- 占位符路径（`/path/to/...` 或 `${...}`）与可选数据库 → 仅警告，不失败。

未实现的字段（如 `max_memory` / `memory_gb` / `max_time`）不在活动配置中，
见 [配置愿景参数路线图](roadmap.md)。

## 配置优先级

1. 命令行参数（CLI）
2. `config/analysis.yaml`
3. `config/databases.yaml`（仅数据库路径）
4. 代码默认值

`full-run --dry-run` 会输出 resolved plan 并标注每个参数的来源
（`cli` / `analysis.yaml` / `databases.yaml` / `default`），保证配置可追踪。

## 相对路径

相对路径按**所在配置文件目录**解析（不依赖进程 CWD）：

- `analysis.yaml` 中的 `paths.input_dir` / `paths.output_dir` 相对该文件所在目录；
- `databases.yaml` 中的数据库路径相对该文件所在目录。

## full-run 关键配置

`full-run` 主命令最关键的配置：

- 输入目录
- 输出目录
- 线程数
- KneadData 数据库路径
- Kraken2 数据库路径

## 校验与预览

```bash
# 校验配置：语法/未知字段/缺失必需阶段依赖返回非零；占位符仅警告
micos validate-config --config config/analysis.yaml

# 输出 resolved plan（阶段、输入、输出、threads、数据库、参数来源），不执行工具
micos --dry-run full-run
```

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

活动配置模板只保留已接入 CLI 的字段；愿景参数与未实现字段收纳在
[配置愿景参数路线图](roadmap.md)。新增配置字段时应先接入 CLI，再从路线图
移回模板，并同步本说明与配置/CLI 测试。
