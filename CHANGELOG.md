# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- 配置强制校验（`enforce-effective-configuration`）：生产配置 model 统一 `extra="forbid"`，未知字段立即失败；移除 `max_memory`/`memory_gb` 等未接入 CLI 的愿景字段（迁至 `docs/zh/roadmap.md`）；明确配置优先级（CLI > analysis.yaml > databases.yaml > 默认）并支持 resolved value 来源输出；相对路径按所在配置文件目录解析；`validate-config` 对语法/未知字段/必需 stage 依赖返回非零；`full-run --dry-run` 输出 resolved plan（含 stage、输入、输出、threads、数据库、参数来源）且不执行外部工具
- 统一 GitHub 身份为 LessUp，清除全部遗留 BGI-MICOS 引用
- 修复文档站英文 404 自动重定向，CI 增加文档构建检查
- 归档遗留 `workflows/wdl_scripts/`，统一以 `steps/` 为权威 WDL 源
- 修复 WDL 语法错误（Directory/None 关键字）、统一 `${}` 为 `~{}`、固定生信工具版本
- 修复 Dockerfile 构建错误与 EOL 基础镜像（Python 3.6、R latest）
- 补齐 4 个流水线模块单元测试与 skip 选项测试，删除 `load_config` 死代码
- 修复 scripts 过时路径与 bash `set -e` 陷阱，清理临时工作文档

## [1.1.0] - 2025-04-16

- Complete Chinese documentation
- New installation, configuration, and troubleshooting guides
- API reference for CLI commands

## [1.0.0] - 2024-10-24

- First stable release for Mammoth Cup 2024
- Quality control (FastQC, KneadData)
- Taxonomic profiling (Kraken2, Krona)
- Diversity analysis (QIIME2)
- Functional annotation (HUMAnN)
- Docker containerization and WDL workflow support

## [0.9.0] - 2024-10-20

- Open source preparation and code cleanup
- Repository restructure
- CI/CD setup
