# 安装指南

MICOS-2024 的完整安装说明。

---

## 目录

- [系统要求](#系统要求)
- [安装方法](#安装方法)
- [数据库设置](#数据库设置)
- [验证](#验证)
- [离线安装](#离线安装)
- [故障排除](#故障排除)

---

## 系统要求

### 最低要求

| 组件 | 最低配置 | 推荐配置 |
|:---|:---|:---|
| **操作系统** | Linux (Ubuntu 18.04+) / macOS 11+ | Linux (Ubuntu 20.04+) |
| **CPU** | 4 核 | 16+ 核 |
| **内存 (RAM)** | 16 GB | 32+ GB |
| **存储** | 100 GB HDD | 500+ GB SSD |
| **网络** | 安装的互联网连接 | 数据库下载的互联网连接 |

### 软件前提条件

| 软件 | 版本 | 用于 |
|:---|:---:|:---|
| Python | 3.9+ | 核心平台 |
| Docker | 20.10+ | 容器化部署 |
| Conda/Mamba | 4.10+ | 包管理 |

### 数据库存储要求

| 数据库 | 大小 | 用途 |
|:---|:---:|:---|
| Kraken2 标准库 | ~70 GB | 物种分类 |
| Kraken2 MiniKraken | ~8 GB | 快速测试 |
| KneadData 人类基因组 | ~4 GB | 宿主 DNA 去除 |
| HUMAnN ChocoPhlAn | ~10 GB | 功能注释 |
| HUMAnN UniRef90 | ~20 GB | 蛋白质家族 |

---

## 安装方法

### 方式 1：Docker 安装（推荐）

Docker 提供最可重现的环境，所有依赖项均已预安装。

#### 步骤 1：安装 Docker

```bash
# Linux (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# 验证安装
docker --version
docker compose version
```

#### 步骤 2：克隆仓库

```bash
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024
```

#### 步骤 3：使用 Docker Compose 部署

```bash
# 启动所有服务
docker compose -f deploy/docker-compose.example.yml up -d

# 验证服务运行
docker compose -f deploy/docker-compose.example.yml ps

# 查看日志
docker compose -f deploy/docker-compose.example.yml logs -f
```

#### 步骤 4：进入容器

```bash
# 进入主分析容器
docker compose -f deploy/docker-compose.example.yml exec micos bash

# 运行分析
python -m micos.cli --help
```

**优点**：
- ✅ 完整的环境隔离
- ✅ 无依赖冲突
- ✅ 跨系统易于重现

---

### 方式 2：Conda 安装

Conda/Mamba 提供灵活的安装，性能良好。

#### 步骤 1：安装 Miniforge（推荐）

```bash
# 下载 Miniforge 安装程序
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

# 运行安装程序
bash Miniforge3-Linux-x86_64.sh -b -p $HOME/miniforge

# 初始化 shell
$HOME/miniforge/bin/conda init bash
source ~/.bashrc
```

#### 步骤 2：创建环境

```bash
# 克隆仓库
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024

# 使用 mamba 创建环境（更快）
mamba env create -f environment.yml

# 激活环境
conda activate micos-2024
```

#### 步骤 3：安装 MICOS 包

```bash
# 以可编辑模式安装（开发用）
pip install -e .

# 或正常安装
pip install .
```

#### 步骤 4：验证工具

```bash
# 检查核心依赖
kraken2 --version
humann --version
qiime --version
kneaddata --version
```

**优点**：
- ✅ 原生性能
- ✅ 易于定制
- ✅ 适合开发

---

## 数据库设置

### 自动化数据库下载

```bash
# 运行数据库下载脚本
python scripts/download_databases.py \
  --output-dir /path/to/databases \
  --databases kraken2,kneaddata,humann
```

### 手动数据库设置

#### Kraken2 数据库

```bash
# 创建数据库目录
mkdir -p /path/to/kraken2_db

# 下载并构建标准数据库（需要 ~70GB）
kraken2-build --download-taxonomy --db /path/to/kraken2_db
kraken2-build --download-library bacteria --db /path/to/kraken2_db
kraken2-build --download-library archaea --db /path/to/kraken2_db
kraken2-build --build --db /path/to/kraken2_db --threads 16

# 或下载预构建的 MiniKraken（快速开始，~8GB）
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904_UPDATE.tgz
tar -xzf minikraken2_v2_8GB_201904_UPDATE.tgz
```

#### KneadData 数据库

```bash
# 下载人类基因组参考
kneaddata_database --download human_genome bowtie2 /path/to/kneaddata_db
```

#### HUMAnN 数据库

```bash
# 下载功能数据库
humann_databases --download chocophlan full /path/to/humann_db
humann_databases --download uniref uniref90_diamond /path/to/humann_db
```

### 数据库配置

创建 `config/databases.yaml`：

```yaml
database_root: "/path/to/databases"

quality_control:
  kneaddata:
    human_genome: "${database_root}/kneaddata/human_genome"

taxonomy:
  kraken2:
    standard: "${database_root}/kraken2/standard"
    minikraken: "${database_root}/kraken2/minikraken"

functional:
  humann:
    chocophlan: "${database_root}/humann/chocophlan"
    uniref90: "${database_root}/humann/uniref90"
```

---

## 验证

### 步骤 1：安装验证

```bash
# 运行验证脚本
./scripts/verify_installation.sh
```

预期输出：
```
✓ Python 3.9+ 已找到
✓ Kraken2 已安装
✓ HUMAnN 已安装
✓ QIIME2 已安装
✓ Kneaddata 已安装
✓ 所有依赖已满足
```

### 步骤 2：测试运行

```bash
# 下载测试数据
python scripts/download_test_data.py --output-dir test_data

# 运行快速测试
python -m micos.cli full-run \
  --input-dir test_data \
  --results-dir test_results \
  --threads 4 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_minikraken
```

### 步骤 3：检查输出

```bash
# 验证输出是否存在
ls test_results/
# 应显示：quality_control/, taxonomic_profiling/, functional_annotation/, report.html
```

---

## 离线安装

对于无互联网访问的系统：

### 步骤 1：在联网系统准备

```bash
# 下载包
pip download \
  -r requirements.txt \
  -d ./offline_packages \
  --platform manylinux2014_x86_64

# 导出 conda 环境
conda env export --no-builds > environment-offline.yml

# 下载数据库（见数据库设置部分）
```

### 步骤 2：传输到离线系统

将这些目录传输到离线系统：
- `offline_packages/`
- `MICOS-2024/`（源代码）
- 数据库文件

### 步骤 3：离线安装

```bash
# 从本地包安装
pip install --no-index --find-links=./offline_packages -r requirements.txt

# 安装 MICOS
pip install -e MICOS-2024/
```

---

## 故障排除

### 问题：Docker 权限被拒绝

```bash
# 将用户添加到 docker 组
sudo usermod -aG docker $USER
newgrp docker

# 验证
docker run hello-world
```

### 问题：Conda 环境创建失败

```bash
# 清除 conda 缓存
conda clean --all

# 更新 conda
conda update -n base conda

# 尝试使用 mamba
conda install mamba -c conda-forge -n base
mamba env create -f environment.yml --force
```

### 问题：数据库下载失败

```bash
# 使用镜像站点
# 对于中国用户：
export KRAKEN2_DB_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/"

# 或从以下地址手动下载：
# https://benlangmead.github.io/aws-indexes/k2
```

### 问题：数据库构建时内存错误

```bash
# 构建期间减少线程数
kraken2-build --build --db /path/to/db --threads 4

# 或使用预构建数据库
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20231009.tar.gz
```

---

## 下一步

- 📖 [用户手册](user_manual.md) - 学习如何使用 MICOS-2024
- ⚙️ [配置指南](configuration.md) - 自定义您的分析
- 🧪 [测试数据](user_manual.md#测试数据) - 运行示例分析

---

## 获取帮助

- 📋 [FAQ](faq.md)
- 🔧 [故障排除](troubleshooting.md)
- 💬 [GitHub 讨论](https://github.com/BGI-MICOS/MICOS-2024/discussions)
- 🐛 [报告问题](https://github.com/BGI-MICOS/MICOS-2024/issues)
