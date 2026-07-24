---
title: 部署模式
---

# 部署模式

MICOS-2024 可以用多种方式部署，但这些方式并不等价。不同模式服务于不同目标。

## 模式 1，直接 Python 执行

适合：

- 本地开发，
- 调试，
- 已经有可控 Python 环境的场景。

优点：

- 反馈最快，
- 最容易对照 CLI 行为，
- 与 `micos/cli.py` 对齐最直接。

## 模式 2，Shell 包装层执行

适合：

- 保持旧有 shell-first 工作流，
- 渐进迁移到主 CLI。

关键点：

包装脚本现在更像委托层，而不是独立流程实现层。

## 模式 3，工作流驱动执行

适合：

- 更大的执行生态，
- 需要 workflow engine 集成的环境，
- 希望显式表达步骤图的场景。

相关资产：

- `steps/01_quality_control/fastqc.wdl`
- `steps/02_read_cleaning/kneaddata.wdl`
- `steps/03_taxonomic_profiling_kraken/kraken2.wdl`
- `steps/04_taxonomic_conversion_biom/kraken-biom.wdl`
- `steps/05_taxonomic_visualization_krona/krona.wdl`
- `steps/06_qiime2_analysis/*.wdl`

## 模式 4，容器化执行

适合：

- 固定依赖栈，
- 团队交付，
- 防止环境漂移。

相关资产：

- `containers/singularity/*.def`

## 实践建议

对于多数贡献者来说：

1. 先用稳定 CLI 路径，
2. 再用工作流资产做系统集成，
3. 再用容器锁定环境，
4. 包装脚本只在需要兼容旧流程时使用。
