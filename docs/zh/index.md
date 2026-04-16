# MICOS-2024 文档中心

<p align="center">
  <strong>专业宏基因组分析平台</strong><br>
  <em>从原始测序数据到生物学洞察的端到端分析</em>
</p>

---

## 🚀 5分钟快速开始

几分钟内启动您的第一个宏基因组分析：

```bash
# 1. 克隆仓库
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024

# 2. Docker安装（推荐）
docker compose -f deploy/docker-compose.example.yml up -d

# 3. 运行分析
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

📖 **完整安装指南**: [installation.md](installation.md)

---

## 📚 文档概览

### 入门指南

| 文档 | 描述 | 适用人群 |
|:---|:---|:---|
| [安装指南](installation.md) | 完整安装说明 | 所有用户 |
| [快速开始](user_manual.md#快速开始) | 30秒测试运行 | 新用户 |
| [配置指南](configuration.md) | 参数配置说明 | 所有用户 |

### 分析模块

| 文档 | 描述 | 所用工具 |
|:---|:---|:---|
| [物种分类分析](taxonomic-profiling.md) | 物种分类与可视化 | Kraken2, Krona, QIIME2 |
| [功能注释分析](functional-profiling.md) | 基因家族和通路分析 | HUMAnN 3.x |
| [多样性分析](diversity-analysis.md) | Alpha/Beta 多样性指标 | QIIME2 |

### 参考文档

| 文档 | 描述 |
|:---|:---|
| [API 参考](api-reference.md) | 完整 CLI 命令参考 |
| [故障排除](troubleshooting.md) | 常见问题与解决方案 |
| [FAQ](faq.md) | 常见问题解答 |
| [贡献指南](contributing.md) | 开发和贡献指南 |

---

## 🎯 MICOS-2024 是什么？

MICOS-2024 是一个**端到端宏基因组分析平台**，将行业标准生物信息学工具集成到统一、可重现的工作流中。

### 核心能力

- **质量控制**: 宿主 DNA 去除与质量过滤 (KneadData, FastQC)
- **物种分类**: 快速种分类 (Kraken2, Bracken)
- **多样性分析**: Alpha/Beta 多样性指标 (QIIME2)
- **功能注释**: 基因家族和通路分析 (HUMAnN)
- **差异分析**: 物种/功能的统计比较
- **网络分析**: 微生物共现网络

### 主要特性

| 特性 | 描述 |
|:---|:---|
| 🐳 **容器化** | 支持 Docker 和 Singularity，确保可重现性 |
| ⚡ **高性能** | 多线程支持，针对大数据集优化 |
| 📊 **丰富可视化** | 交互式 HTML 报告、Krona 图表、多样性图 |
| 🔧 **模块化设计** |可运行完整流程或单独步骤 |
| 📝 **WDL 工作流** | 兼容 Cromwell，支持云端/HPC 部署 |

---

## 💡 典型使用案例

### 案例1：人体肠道微生物组分析

研究人体肠道微生物组的组成和功能：

```bash
# 运行完整分析
python -m micos.cli full-run \
  --input-dir gut_microbiome/ \
  --results-dir results/gut \
  --kneaddata-db /db/human_genome \
  --kraken2-db /db/kraken2_standard
```

**分析输出**：
- 门/属/种水平的物种组成
- 功能通路丰度（MetaCyc）
- Alpha 多样性 (Shannon, Chao1) 和 Beta 多样性 (PCoA)

### 案例2：环境宏基因组学

分析土壤或水样微生物组样本：

```bash
# 使用宽松参数进行物种分类
python -m micos.cli run taxonomic-profiling \
  --input-dir env_samples/ \
  --output-dir results/taxonomy \
  --kraken2-db /db/kraken2_pluspf \
  --confidence 0.05
```

### 案例3：比较分析

比较处理组与对照组：

```bash
# 步骤1：运行功能注释
python -m micos.cli run functional-annotation \
  --input-dir cleaned_reads/ \
  --output-dir results/function

# 步骤2：差异丰度分析
# （详见用户手册）
```

---

## 📊 性能基准

每 100 万对端 reads 的典型分析时间：

| 步骤 | 工具 | 时间 | 内存 |
|:---|:---|:---:|:---:|
| 质量控制 | KneadData | ~5 分钟 | 8 GB |
| 物种分类 | Kraken2 | ~2 分钟 | 16 GB |
| 功能注释 | HUMAnN | ~20 分钟 | 32 GB |
| 多样性分析 | QIIME2 | ~10 分钟 | 8 GB |

*测试环境：AMD EPYC 7402, 64GB RAM, SSD 存储*

---

## 🔗 快速链接

- **主仓库**: https://github.com/BGI-MICOS/MICOS-2024
- **问题追踪**: https://github.com/BGI-MICOS/MICOS-2024/issues
- **讨论区**: https://github.com/BGI-MICOS/MICOS-2024/discussions
- **发布说明**: [changelog.md](changelog.md)

---

## 📖 引用

如果您在研究中使用了 MICOS-2024，请引用：

```bibtex
@software{micos2024,
  title = {MICOS-2024: Metagenomic Intelligence and Comprehensive Omics Suite},
  author = {MICOS-2024 Team},
  year = {2024},
  url = {https://github.com/BGI-MICOS/MICOS-2024}
}
```

---

<p align="center">
  <strong>准备开始？</strong> → <a href="installation.md">安装指南</a>
</p>

<p align="center">
  <a href="../en/">English Documentation</a> | <a href="../../README.md">项目主页</a>
</p>
