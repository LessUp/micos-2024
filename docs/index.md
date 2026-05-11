# MICOS-2024

**专业宏基因组分析平台**

端到端分析从原始测序数据到生物学洞察

---

## 选择文档语言

- [English Documentation](en/index.md)
- [中文文档](zh/index.md)

---

## What is MICOS-2024?

MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite) 是一个端到端宏基因组分析平台，整合 Kraken2、QIIME2、HUMAnN 等业界标准生物信息学工具。

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

- **容器化** - 支持 Docker 和 Singularity
- **高性能** - 多线程支持，针对大数据集优化
- **丰富可视化** - 交互式 HTML 报告
- **模块化设计** - 可运行完整流程或单独步骤
- **WDL 工作流** - 兼容 Cromwell，支持云端/HPC 部署

---

## 快速链接

- [GitHub](https://github.com/LessUp/micos-2024)
- [Issues](https://github.com/LessUp/micos-2024/issues)
- [Discussions](https://github.com/LessUp/micos-2024/discussions)

---

License: MIT | Team: MICOS-2024 Team
