# MICOS-2024

**专业宏基因组分析平台**

端到端分析从原始测序数据到生物学洞察

---

## MICOS-2024 是什么？

MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite) 是一个端到端宏基因组分析平台，将业界标准生物信息学工具集成到统一、可重现的工作流中。

### 核心能力

| 模块 | 描述 | 工具 |
|------|------|------|
| 质量控制 | 宿主 DNA 去除与质量过滤 | KneadData, FastQC |
| 物种分类 | 快速物种分类 | Kraken2, Bracken |
| 多样性分析 | Alpha/Beta 多样性指标 | QIIME2 |
| 功能注释 | 基因家族和通路分析 | HUMAnN 3.x |
| 差异分析 | 物种/功能的统计比较 | DESeq2, ALDEx2 |
| 网络分析 | 微生物共现网络 | NetworkX, igraph |

### 主要特性

- **容器化** - 支持 Docker 和 Singularity，确保可重现性
- **高性能** - 多线程支持，针对大数据集优化
- **丰富可视化** - 交互式 HTML 报告
- **模块化设计** - 可运行完整流程或单独步骤
- **WDL 工作流** - 兼容 Cromwell，支持云端/HPC 部署

---

## 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/LessUp/micos-2024.git
cd micos-2024

# 2. Docker 安装（推荐）
docker compose -f deploy/docker-compose.example.yml up -d

# 3. 运行分析
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16
```

详见 [安装指南](installation.md)。

---

## 文档导航

| 文档 | 描述 |
|------|------|
| [安装指南](installation.md) | 完整安装说明 |
| [配置指南](configuration.md) | 参数配置说明 |
| [物种分类分析](taxonomic-profiling.md) | 物种分类与可视化 |
| [功能注释分析](functional-profiling.md) | 基因家族和通路分析 |
| [API 参考](api-reference.md) | 完整 CLI 命令参考 |

---

## 快速链接

- [GitHub 仓库](https://github.com/LessUp/micos-2024)
- [问题追踪](https://github.com/LessUp/micos-2024/issues)
- [社区讨论](https://github.com/LessUp/micos-2024/discussions)

---

[English Docs](../en/index.md) | [GitHub](https://github.com/LessUp/micos-2024)
