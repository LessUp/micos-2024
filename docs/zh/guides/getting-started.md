---
title: 快速开始
---

# 快速开始

本页故意偏向**当前稳定可操作的主路径**，而不是把仓库里所有脚本都一并当成同等级入口。

## 先选运行姿态

| 姿态 | 适用场景 | 主要入口 |
| --- | --- | --- |
| Python CLI | 本地开发、可控环境 | `micos` 或 `python -m micos.cli` |
| Shell 包装层 | 兼容旧用法 | `scripts/run_full_analysis.sh`, `scripts/run_module.sh` |
| 工作流与容器 | 集成部署、可重现环境 | `steps/`, `containers/` |

## 最短可信路径

### 1. 克隆并安装

```bash
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024
pip install -e ".[dev]"
```

如果你更偏好 Conda / Mamba，可以直接使用仓库中的 `environment.yml`。

### 2. 复制配置模板

```bash
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv
```

然后把数据库路径改成你本地真实可用的位置。

### 3. 先做配置验证

```bash
python -m micos.cli validate-config --config config/analysis.yaml
```

这一步最省时间，能提前发现路径和模板残留问题。

### 4. 运行稳定全流程入口

```bash
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

## 如果你更想用包装脚本

包装脚本目前是薄包装层：

```bash
./scripts/run_full_analysis.sh \
  --config config/analysis.yaml \
  --input-dir data/raw_input \
  --results-dir results
```

在新项目、自动化或排错场景中，仍建议优先使用主 CLI。

## 如果你更想用容器

仓库提供了 Singularity 定义文件，用于锁定执行环境：

```bash
sudo singularity build kraken2.sif steps/03_taxonomic_profiling_kraken/kraken2.def
```

需要注意，容器定义更接近环境锁定脚手架，而不是对全流程的”一键全自动承诺”。

## 第一次运行之后看什么

- `results/quality_control/`
- `results/taxonomic_profiling/`
- `results/diversity_analysis/`
- `results/functional_annotation/`

如果这些目录内容合理，平台的其他部分就更容易建立信任。
