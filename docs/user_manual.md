# 🧬 MICOS-2024 用户手册

## 📖 目录

1. [快速开始](#快速开始)
2. [详细安装指南](#详细安装指南)
3. [配置说明](#配置说明)
4. [数据准备](#数据准备)
5. [运行分析](#运行分析)
6. [结果解读](#结果解读)
7. [高级功能](#高级功能)
8. [常见问题](#常见问题)

## 🚀 快速开始

### 系统要求

- **操作系统**: Linux (Ubuntu 18.04+) 或 macOS (10.14+)
- **内存**: 最少16GB，推荐32GB+
- **存储**: 最少100GB可用空间
- **CPU**: 多核处理器，推荐16核+

### 一键安装

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/MICOS-2024/main/install.sh | bash

# 或者手动安装
git clone https://github.com/YOUR_USERNAME/MICOS-2024.git
cd MICOS-2024
chmod +x install.sh
./install.sh
```

### 快速测试

```bash
# 激活环境
conda activate micos-2024

# 运行测试数据
./scripts/run_test_data.sh

# 查看结果
firefox results/reports/analysis_report.html
```

## 🔧 详细安装指南

### 方式1: Docker安装（推荐）

```bash
# 1. 安装Docker和Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 2. 克隆项目
git clone https://github.com/YOUR_USERNAME/MICOS-2024.git
cd MICOS-2024

# 3. 启动服务
docker-compose up -d

# 4. 验证安装
docker-compose exec micos-web python --version
```

### 方式2: Conda安装

```bash
# 1. 安装Miniforge
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh

# 2. 创建环境
git clone https://github.com/YOUR_USERNAME/MICOS-2024.git
cd MICOS-2024
mamba env create -f environment.yml
conda activate micos-2024

# 3. 验证安装
./scripts/verify_installation.sh
```

### 方式3: 源码安装

```bash
# 1. 安装系统依赖
sudo apt-get update
sudo apt-get install -y build-essential python3-dev

# 2. 安装Python依赖
pip install -r requirements.txt

# 3. 安装生物信息学工具
# 详见 docs/manual_installation.md
```

## ⚙️ 配置说明

### 主配置文件

MICOS-2024使用YAML格式的配置文件，主要包括：

```bash
config/
├── analysis.yaml        # 分析参数配置
├── databases.yaml       # 数据库路径配置
├── samples.tsv          # 样本元数据
└── cromwell.conf        # Cromwell工作流配置
```

### 分析参数配置

复制模板文件并编辑：

```bash
cp config/analysis.yaml.template config/analysis.yaml
nano config/analysis.yaml
```

关键参数说明：

```yaml
# 计算资源
resources:
  max_threads: 16          # 最大线程数
  max_memory: "32GB"       # 最大内存
  
# 质量控制
quality_control:
  kneaddata:
    min_quality: 20        # 最小质量值
    min_length: 50         # 最小序列长度
    
# 物种分类
taxonomic_profiling:
  kraken2:
    confidence: 0.1        # 置信度阈值
    threads: 16            # 线程数
```

### 数据库配置

```bash
cp config/databases.yaml.template config/databases.yaml
nano config/databases.yaml
```

设置数据库路径：

```yaml
taxonomy:
  kraken2:
    standard: "/path/to/kraken2_standard_db"
  qiime2:
    silva_classifier: "/path/to/silva-classifier.qza"
```

### 样本元数据

创建样本信息文件：

```bash
cp config/samples.tsv.template config/samples.tsv
nano config/samples.tsv
```

样本文件格式：

```tsv
sample-id	group	treatment	time-point
Sample001	Control	None	T0
Sample002	Treatment	Drug_A	T24
Sample003	Treatment	Drug_B	T24
```

## 📁 数据准备

### 输入数据格式

MICOS-2024支持以下输入格式：

1. **FASTQ文件** (推荐)
   - 双端测序: `sample_R1.fastq.gz`, `sample_R2.fastq.gz`
   - 单端测序: `sample.fastq.gz`

2. **FASTA文件**
   - 已组装序列: `sample.fasta`

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

- **测序深度**: 建议每样本≥1M reads
- **序列长度**: ≥75bp
- **质量值**: 平均Q值≥20

## 🔄 运行分析

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

### 模块化运行

```bash
# 只运行质量控制
./scripts/run_module.sh quality_control

# 只运行物种分类
./scripts/run_module.sh taxonomic_profiling

# 只运行多样性分析
./scripts/run_module.sh diversity_analysis

# 只运行功能分析
./scripts/run_module.sh functional_analysis
```

### 使用WDL工作流

```bash
# 使用Cromwell运行
java -jar cromwell.jar run \
  workflows/wdl_scripts/meta-dev.wdl \
  --inputs config/analysis.json

# 使用miniwdl运行
miniwdl run workflows/wdl_scripts/meta-dev.wdl \
  --input config/analysis.json \
  --dir results/
```

### 使用Docker运行

```bash
# 启动所有服务
docker-compose up -d

# 运行特定分析
docker-compose run --rm kraken2 \
  kraken2 --db /references/kraken2_db \
  --paired /data/sample_R1.fastq /data/sample_R2.fastq

# 查看运行状态
docker-compose ps
docker-compose logs -f
```

## 📊 结果解读

### 输出目录结构

```bash
results/
├── reports/                 # HTML报告
├── quality_control/         # 质量控制结果
├── taxonomic_profiling/     # 物种分类结果
├── diversity_analysis/      # 多样性分析
├── functional_analysis/     # 功能分析
└── logs/                    # 运行日志
```

### 主要输出文件

1. **质量控制报告**
   - `quality_control/multiqc_report.html`: 综合质量报告
   - `quality_control/fastqc_reports/`: 各样本质量报告

2. **物种分类结果**
   - `taxonomic_profiling/kraken2_reports/`: Kraken2分类报告
   - `taxonomic_profiling/krona_charts/`: 交互式分类图表
   - `taxonomic_profiling/biom_files/`: BIOM格式文件

3. **多样性分析**
   - `diversity_analysis/alpha_diversity/`: Alpha多样性指标
   - `diversity_analysis/beta_diversity/`: Beta多样性分析
   - `diversity_analysis/pcoa_plots/`: PCoA图表

### 关键指标解读

#### Alpha多样性指标

- **Shannon指数**: 群落多样性，值越高多样性越大
- **Chao1指数**: 群落丰富度估计
- **Simpson指数**: 群落均匀度

#### Beta多样性指标

- **Bray-Curtis距离**: 基于丰度的群落差异
- **Jaccard距离**: 基于存在/缺失的群落差异
- **UniFrac距离**: 基于系统发育的群落差异
