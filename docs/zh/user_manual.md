# MICOS-2024 用户手册

---

## 目录

- [快速开始](#快速开始)
- [详细安装指南](#详细安装指南)
- [数据准备](#数据准备)
- [运行分析](#运行分析)
- [结果解读](#结果解读)
- [命令参考](#命令参考)
- [常见问题](#常见问题)
- [高级功能](#高级功能)

---

## 快速开始

### 系统要求

| 项目 | 最低配置 | 推荐配置 |
|:---|:---:|:---:|
| **操作系统** | Linux (Ubuntu 18.04+) / macOS 11+ | Linux (Ubuntu 20.04+) |
| **内存** | 16GB | 32GB+ |
| **存储** | 100GB | 500GB+ SSD |
| **CPU** | 4 核 | 16+ 核 |

### 快速测试

```bash
# 激活环境
conda activate micos-2024

# 运行测试数据
./scripts/run_test_data.sh

# 查看结果
firefox results/reports/analysis_report.html
```

---

## 详细安装指南

### 方式 1：Docker 安装（推荐）

```bash
# 1. 安装 Docker 和 Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 2. 克隆项目
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024

# 3. 启动服务
docker compose -f deploy/docker-compose.example.yml up -d

# 4. 验证安装
docker compose -f deploy/docker-compose.example.yml ps
```

### 方式 2：Conda 安装

```bash
# 1. 安装 Miniforge
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh

# 2. 创建环境
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024
mamba env create -f environment.yml
conda activate micos-2024

# 3. 验证安装
./scripts/verify_installation.sh
```

---

## 数据准备

### 输入数据格式

MICOS-2024 支持以下输入格式：

| 格式 | 类型 | 命名规范 |
|:---|:---|:---|
| **FASTQ**（推荐） | 双端测序 | `sample_R1.fastq.gz`, `sample_R2.fastq.gz` |
| **FASTQ** | 单端测序 | `sample.fastq.gz` |

### 数据组织结构

```bash
data/
├── raw_input/
│   ├── Sample001_R1.fastq.gz
│   ├── Sample001_R2.fastq.gz
│   ├── Sample002_R1.fastq.gz
│   └── Sample002_R2.fastq.gz
└── metadata/
    └── samples.tsv
```

### 数据质量要求

| 指标 | 要求 |
|:---|:---|
| 测序深度 | 每样本 ≥ 1M reads |
| 序列长度 | ≥ 75bp |
| 质量值 | 平均 Q 值 ≥ 20 |

---

## 运行分析

### 完整流程分析

```bash
# 1. 准备配置文件
cp config/analysis.yaml.template config/analysis.yaml
cp config/samples.tsv.template config/samples.tsv

# 2. 编辑配置文件
nano config/analysis.yaml
nano config/samples.tsv

# 3. 运行完整分析
./scripts/run_full_analysis.sh

# 4. 监控进度
tail -f logs/analysis.log
```

### 使用 CLI 命令

```bash
# 完整流程
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db

# 单独模块
python -m micos.cli run quality-control \
  --input-dir data/raw_input \
  --output-dir results/quality_control \
  --threads 16

python -m micos.cli run taxonomic-profiling \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/taxonomic_profiling \
  --threads 16
```

---

## 结果解读

### 输出目录结构

```bash
results/
├── reports/                    # HTML 报告
│   └── analysis_report.html
├── 1_quality_control/          # 质量控制结果
│   ├── fastqc_reports/
│   └── kneaddata/
├── 2_taxonomic_profiling/      # 物种分类结果
│   ├── kraken_reports/
│   ├── krona_charts/
│   └── feature-table.biom
├── 3_diversity_analysis/       # 多样性分析
│   ├── alpha_diversity/
│   ├── beta_diversity/
│   └── pcoa_plots/
├── 4_functional_annotation/    # 功能分析
│   ├── genefamilies/
│   └── pathways/
└── logs/                       # 运行日志
```

### 关键指标解释

#### Alpha 多样性指标

| 指标 | 含义 | 解读 |
|:---|:---|:---|
| **Shannon** | 群落多样性 | 值越高多样性越大 |
| **Chao1** | 群落丰富度估计 | 估计总物种数 |
| **Observed Features** | 观测特征数 | 实际观测到的 ASV/OTU 数量 |

#### Beta 多样性指标

| 指标 | 含义 | 适用场景 |
|:---|:---|:---|
| **Bray-Curtis** | 基于丰度的群落差异 | 比较群落组成差异 |
| **Jaccard** | 基于存在/缺失的差异 | 比较物种有无差异 |
| **UniFrac** | 基于系统发育的差异 | 考虑进化关系 |

---

## 命令参考

### CLI 命令一览

| 命令 | 描述 |
|:---|:---|
| `python -m micos.cli full-run` | 运行完整分析流程 |
| `python -m micos.cli run quality-control` | 质量控制模块 |
| `python -m micos.cli run taxonomic-profiling` | 物种分类模块 |
| `python -m micos.cli run diversity-analysis` | 多样性分析模块 |
| `python -m micos.cli run functional-annotation` | 功能注释模块 |

### 全局选项

| 选项 | 描述 |
|:---|:---|
| `--config PATH` | 指定配置文件路径 |
| `--log-file PATH` | 日志输出文件 |
| `--verbose` | 启用详细日志 |

---

## 常见问题

### Q1: 环境创建失败？

**解决方案**：

```bash
# 清理 conda 缓存
conda clean --all

# 使用 mamba 替代
conda install mamba -c conda-forge
mamba env create -f environment.yml
```

### Q2: Docker 权限错误？

**解决方案**：

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Q3: 数据库路径错误？

**解决方案**：

```bash
# 检查数据库是否存在
ls -la /path/to/kraken2_db

# 更新配置文件
nano config/databases.yaml
```

### Q4: 内存不足？

**解决方案**：

```yaml
# 在 config/analysis.yaml 中减少并行度
resources:
  max_threads: 8
  max_memory: "16GB"
```

---

## 高级功能

### 差异丰度分析

MICOS-2024 支持多种差异丰度分析方法：

```bash
./scripts/run_module.sh differential_abundance
```

### 网络分析

```bash
./scripts/run_module.sh network_analysis
```

### 16S rRNA 扩增子分析

```bash
./scripts/run_module.sh amplicon_analysis
```

---

## 参考

### 相关文档

- [配置指南](configuration.md)
- [故障排除](troubleshooting.md)
- [物种分类分析](taxonomic-profiling.md)
- [功能注释](functional-profiling.md)

### 项目仓库

- [GitHub](https://github.com/BGI-MICOS/MICOS-2024)
- [问题反馈](https://github.com/BGI-MICOS/MICOS-2024/issues)
- [讨论区](https://github.com/BGI-MICOS/MICOS-2024/discussions)
