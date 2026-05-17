---
title: 项目结构
---

# 项目结构

这一页不是按目录名字解释目录，而是按“职责”解释仓库。

## 顶层地图

| 路径 | 职责 |
| --- | --- |
| `micos/` | 稳定 Python 包与 CLI 编排核心 |
| `config/` | 配置模板与样本元数据 |
| `steps/` | 步骤级 WDL 工作流资产 |
| `scripts/` | 包装层和主 CLI 之外的专家分析脚本 |
| `deploy/` | Docker Compose 示例 |
| `containers/` | Singularity 定义与环境资产 |
| `tests/` | Python 工具函数与包装层回归测试 |
| `docs/` | 双语白皮书式文档站 |

## 稳定核心

```text
micos/
├── cli.py
├── full_run.py
├── quality_control.py
├── taxonomic_profiling.py
├── diversity_analysis.py
├── functional_annotation.py
└── summarize_results.py
```

这是最需要保持内聚的一棵子树，因为它承担了当前最清晰的公共契约。

## 更广的平台表面

```text
scripts/
├── run_full_analysis.sh
├── run_module.sh
├── download_databases.sh
├── verify_installation.sh
├── network_analysis.py
├── phylogenetic_analysis.py
├── amplicon_analysis.py
└── metatranscriptome_analysis.py
```

这棵子树里既有兼容层，也有专家扩展分析。它很重要，但不应被误读为与主 CLI 同等级稳定。

## 文档如何映射仓库

- 学院，解释分析模型，
- 架构，解释代码和资产分层，
- 指南，解释如何运行，
- 参考，解释精确接口，
- 研究，解释知识来源与演进方向。
