# 更新日志

本项目的所有重要变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelogs.com/zh-CN/1.0.0/)，
本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/spec/v2.0.0.html)。

---

## [1.1.0] - 2025-04-16

### 🎉 亮点

- **专业文档**：完整的中英文双语文档重构
- **增强用户体验**：以任务为导向的文档重组
- **综合指南**：全新的安装、配置和故障排除指南

### 🚀 新功能

#### 文档
- 添加双语文档结构（`docs/en/` 和 `docs/zh/`）
- 创建 Docker 和 Conda 的详细安装指南
- 添加带参数说明的配置参考
- 新增多样性分析文档模块
- 添加 CLI 命令的 API 参考
- 创建常见问题解答部分

#### 配置
- 改进配置验证，提供更详细的错误信息
- 添加带内联文档的配置模板
- 增强数据库路径管理，支持变量替换

### 🔧 改进

#### 文档质量
- 重组所有文档以改善导航
- 在相关文档之间添加交叉引用
- 改进代码示例，使用真实参数
- 添加性能基准和建议

#### 用户体验
- 更清晰的安装说明，包含平台特定注释
- 更好的故障排除指南，包含诊断流程图
- 为常见用例添加快速入门指南

### 📚 文档

#### 新增文档
- `docs/en/index.md` - 英文文档门户
- `docs/zh/index.md` - 中文文档门户
- `docs/en/installation.md` - 详细安装指南
- `docs/zh/installation.md` - 详细安装指南
- `docs/en/configuration.md` - 配置参考
- `docs/zh/configuration.md` - 配置参考
- `docs/en/taxonomic-profiling.md` - 物种分类指南
- `docs/en/functional-profiling.md` - 功能注释指南
- `docs/en/diversity-analysis.md` - 多样性分析指南（新）
- `docs/en/troubleshooting.md` - 综合故障排除
- `docs/zh/troubleshooting.md` - 综合故障排除
- `docs/en/faq.md` - 常见问题
- `docs/zh/faq.md` - 常见问题
- `docs/en/api-reference.md` - CLI API 参考

### 🙏 贡献者

- MICOS-2024 团队

---

## [1.0.0] - 2024-10-24

### 🎉 亮点

- **首个稳定版本**：可用于生产的宏基因组分析平台
- **完整流程**：从原始 reads 到报告的端到端分析
- **竞赛就绪**：为 2024 猛犸杯优化

### 🚀 新功能

#### 核心流程
- 质量控制模块（FastQC + KneadData）
- 物种分类（Kraken2 + Bracken + Krona）
- 多样性分析（QIIME2 集成）
- 功能注释（HUMAnN 3.x）
- HTML 报告生成

#### 基础设施
- Docker 容器化
- WDL 工作流支持（Cromwell）
- Singularity 容器定义
- 带模块化命令的 CLI 界面

#### 分析功能
- 多线程支持
- 可配置参数
- 自动结果汇总
- 支持双端和单端数据

### 🔧 技术详情

#### 依赖
- Python 3.9+
- Kraken2 2.1.3
- QIIME2 2024.5
- HUMAnN 3.x
- KneadData 0.12.0

#### 支持平台
- Linux (Ubuntu 18.04+)
- macOS (11+)
- Docker/Singularity 容器

### 📚 文档

- 包含基本用法的初始 README
- 带安装说明的用户手册
- 配置指南
- 模块特定文档

---

## [0.9.0] - 2024-10-20

### 🎉 亮点

- **开源准备**：代码清理和文档
- **仓库重组**：改进的项目组织
- **CI/CD 设置**：自动化测试和工作流

### 🔧 改进

#### 项目结构
- 将部署配置重组到 `deploy/`
- 将历史脚本移至 `legacy/` 目录
- 创建 `changelog/` 目录进行版本跟踪
- 重组容器定义

#### 文档
- 添加 SECURITY.md
- 创建配置 README
- 添加贡献指南
- 初始故障排除指南

#### 开发
- 设置 GitHub Actions CI/CD
- 添加 pre-commit 钩子
- 配置代码覆盖率报告

### ⚠️ 破坏性变更

- 将 `docker-compose.yml` 移至 `deploy/docker-compose.example.yml`
- 移除废弃的 `install.sh` 脚本
- 重组 `steps/` 目录（移除构建目录）

### 🗑️ 移除

- 根级 `docker-compose.yml`（移至 `deploy/`）
- `install.sh` 脚本（使用 Conda 替代）
- `.augment-guidelines` 文件
- `steps/02_read_cleaning/` 中的构建目录

---

## 版本历史摘要

| 版本 | 日期 | 里程碑 |
|:---|:---|:---|
| 1.1.0 | 2025-04-16 | 专业文档发布 |
| 1.0.0 | 2024-10-24 | 首个稳定版本 |
| 0.9.0 | 2024-10-20 | 开源准备 |
| 0.1.0 | 2024-05-15 | 项目启动 |

---

## [未发布]

### 计划功能

- [ ] 增强 QC 模块，集成 multiqc
- [ ] 额外的可视化选项
- [ ] 云部署指南（AWS、GCP、Azure）
- [ ] 自动化数据库更新
- [ ] 不同硬件的性能基准

### 已知问题

- 当前无追踪问题

---

## 发布说明模板

创建新发布时：

```markdown
## [X.Y.Z] - YYYY-MM-DD

### 🎉 亮点
- 主要功能或改进

### 🚀 新功能
- 添加的新功能

### 🔧 改进
- 现有功能的增强

### 🐛 修复
- 修复的问题

### ⚠️ 破坏性变更
- 需要用户操作的变更

### 📚 文档
- 文档更新

### 🙏 贡献者
- 贡献者列表
```

---

[1.1.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v1.1.0
[1.0.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v1.0.0
[0.9.0]: https://github.com/BGI-MICOS/MICOS-2024/releases/tag/v0.9.0
