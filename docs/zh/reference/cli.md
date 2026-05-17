---
title: CLI 参考
---

# CLI 参考

本页严格对齐 **`micos/cli.py` 里当前真实实现的 Click 命令**。

## 调用模式

```bash
python -m micos.cli [全局选项] <命令> [命令选项]
```

如果通过 `pyproject.toml` 安装成功，也可以直接使用：

```bash
micos [全局选项] <命令> [命令选项]
```

## 全局选项

| 选项 | 说明 |
| --- | --- |
| `--config` | 指定分析配置文件路径 |
| `--log-file` | 指定日志输出文件 |
| `--verbose` | 打开调试级日志 |
| `--dry-run` | 只打印计划，不真正执行 |
| `--version` | 输出版本信息 |

## 稳定命令

### `validate-config`

运行前验证配置：

```bash
python -m micos.cli validate-config --config config/analysis.yaml
```

### `full-run`

运行稳定全流程主入口：

```bash
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /db/kneaddata/human_genome \
  --kraken2-db /db/kraken2/standard
```

关键跳过参数：

- `--skip-qc`
- `--skip-taxonomy`
- `--skip-functional`
- `--skip-diversity`

### `run quality-control`

```bash
python -m micos.cli run quality-control \
  --input-dir data/raw_input \
  --output-dir results/quality_control \
  --threads 8 \
  --kneaddata-db /db/kneaddata/human_genome
```

### `run taxonomic-profiling`

```bash
python -m micos.cli run taxonomic-profiling \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/taxonomic_profiling \
  --threads 16 \
  --kraken2-db /db/kraken2/standard \
  --confidence 0.1
```

### `run diversity-analysis`

```bash
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis
```

### `run functional-annotation`

```bash
python -m micos.cli run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 8
```

### `run summarize-results`

```bash
python -m micos.cli run summarize-results \
  --results-dir results \
  --output-file results/micos_summary_report.html
```

## Shell 包装脚本

仓库里两个包装脚本仍然重要：

| 包装脚本 | 角色 |
| --- | --- |
| `scripts/run_full_analysis.sh` | `micos full-run` 的兼容薄包装层 |
| `scripts/run_module.sh` | 把模块执行委托给稳定 CLI |

关键点在于：这些脚本是**委托层**，不是第二套独立流程实现。

## 返回码

`micos/cli.py` 中定义了显式退出码：

| 码 | 含义 |
| --- | --- |
| `0` | 成功 |
| `1` | 一般错误 |
| `2` | 参数无效 |
| `3` | 配置错误 |
| `4` | 缺少依赖 |
| `5` | 数据库错误 |
| `6` | I/O 错误 |
| `130` | 用户中断 |

## 实用提醒

如果你在旧文档或脚本说明里看到更大的命令面，请以本页为准。本页对应的是当前实现，而不是历史漂移出来的描述。
