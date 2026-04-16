# Installation Guide

Complete installation instructions for MICOS-2024.

---

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Docker (Recommended)](#method-1-docker-installation-recommended)
  - [Conda/Mamba](#method-2-conda-installation)
  - [Source Installation](#method-3-source-installation)
- [Database Setup](#database-setup)
- [Verification](#verification)
- [Offline Installation](#offline-installation)
- [Troubleshooting](#troubleshooting)

---

## System Requirements

### Minimum Requirements

| Component | Minimum | Recommended |
|:---|:---|:---|
| **Operating System** | Linux (Ubuntu 18.04+) / macOS 11+ | Linux (Ubuntu 20.04+) |
| **CPU** | 4 cores | 16+ cores |
| **Memory (RAM)** | 16 GB | 32+ GB |
| **Storage** | 100 GB HDD | 500+ GB SSD |
| **Network** | Internet for installation | Internet for database downloads |

### Software Prerequisites

| Software | Version | Required For |
|:---|:---:|:---|
| Python | 3.9+ | Core platform |
| Docker | 20.10+ | Containerized deployment |
| Conda/Mamba | 4.10+ | Package management |

### Database Storage Requirements

| Database | Size | Purpose |
|:---|:---:|:---|
| Kraken2 Standard | ~70 GB | Species classification |
| Kraken2 MiniKraken | ~8 GB | Quick testing |
| KneadData Human Genome | ~4 GB | Host DNA removal |
| HUMAnN ChocoPhlAn | ~10 GB | Functional annotation |
| HUMAnN UniRef90 | ~20 GB | Protein families |

---

## Installation Methods

### Method 1: Docker Installation (Recommended)

Docker provides the most reproducible environment with all dependencies pre-installed.

#### Step 1: Install Docker

```bash
# Linux (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

#### Step 2: Clone Repository

```bash
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024
```

#### Step 3: Deploy with Docker Compose

```bash
# Start all services
docker compose -f deploy/docker-compose.example.yml up -d

# Verify services are running
docker compose -f deploy/docker-compose.example.yml ps

# View logs
docker compose -f deploy/docker-compose.example.yml logs -f
```

#### Step 4: Access Container

```bash
# Enter the main analysis container
docker compose -f deploy/docker-compose.example.yml exec micos bash

# Run analysis
python -m micos.cli --help
```

**Advantages**:
- ✅ Complete environment isolation
- ✅ No dependency conflicts
- ✅ Easy to reproduce across systems

---

### Method 2: Conda Installation

Conda/Mamba provides flexible installation with good performance.

#### Step 1: Install Miniforge (Recommended)

```bash
# Download Miniforge installer
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh

# Run installer
bash Miniforge3-Linux-x86_64.sh -b -p $HOME/miniforge

# Initialize shell
$HOME/miniforge/bin/conda init bash
source ~/.bashrc
```

#### Step 2: Create Environment

```bash
# Clone repository
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024

# Create environment with mamba (faster)
mamba env create -f environment.yml

# Activate environment
conda activate micos-2024
```

#### Step 3: Install MICOS Package

```bash
# Install in editable mode for development
pip install -e .

# Or install normally
pip install .
```

#### Step 4: Verify Tools

```bash
# Check core dependencies
kraken2 --version
humann --version
qiime --version
kneaddata --version
```

**Advantages**:
- ✅ Native performance
- ✅ Easy customization
- ✅ Good for development

---

### Method 3: Source Installation

For developers who want to modify the code.

#### Step 1: System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    python3-dev \
    python3-pip \
    git \
    wget \
    curl

# Install bioinformatics tools manually
# See individual tool documentation for details
```

#### Step 2: Python Environment

```bash
# Create virtual environment
python3 -m venv micos-env
source micos-env/bin/activate

# Install Python dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # For development
```

#### Step 3: Install MICOS

```bash
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024
pip install -e .
```

**Advantages**:
- ✅ Full control over installation
- ✅ Easy to modify source code
- ✅ Minimal overhead

---

## Database Setup

### Automated Database Download

```bash
# Run database download script
python scripts/download_databases.py \
  --output-dir /path/to/databases \
  --databases kraken2,kneaddata,humann
```

### Manual Database Setup

#### Kraken2 Database

```bash
# Create database directory
mkdir -p /path/to/kraken2_db

# Download and build standard database (requires ~70GB)
kraken2-build --download-taxonomy --db /path/to/kraken2_db
kraken2-build --download-library bacteria --db /path/to/kraken2_db
kraken2-build --download-library archaea --db /path/to/kraken2_db
kraken2-build --build --db /path/to/kraken2_db --threads 16

# Or download pre-built MiniKraken (quick start, ~8GB)
wget https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v2_8GB_201904_UPDATE.tgz
tar -xzf minikraken2_v2_8GB_201904_UPDATE.tgz
```

#### KneadData Database

```bash
# Download human genome reference
kneaddata_database --download human_genome bowtie2 /path/to/kneaddata_db
```

#### HUMAnN Database

```bash
# Download functional databases
humann_databases --download chocophlan full /path/to/humann_db
humann_databases --download uniref uniref90_diamond /path/to/humann_db
```

### Database Configuration

Create `config/databases.yaml`:

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

## Verification

### Step 1: Installation Verification

```bash
# Run verification script
./scripts/verify_installation.sh
```

Expected output:
```
✓ Python 3.9+ found
✓ Kraken2 installed
✓ HUMAnN installed
✓ QIIME2 installed
✓ Kneaddata installed
✓ All dependencies satisfied
```

### Step 2: Test Run

```bash
# Download test data
python scripts/download_test_data.py --output-dir test_data

# Run quick test
python -m micos.cli full-run \
  --input-dir test_data \
  --results-dir test_results \
  --threads 4 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_minikraken
```

### Step 3: Check Output

```bash
# Verify outputs exist
ls test_results/
# Should show: quality_control/, taxonomic_profiling/, functional_annotation/, report.html
```

---

## Offline Installation

For systems without internet access:

### Step 1: Prepare on Online System

```bash
# Download packages
pip download \
  -r requirements.txt \
  -d ./offline_packages \
  --platform manylinux2014_x86_64

# Export conda environment
conda env export --no-builds > environment-offline.yml

# Download databases (see Database Setup section)
```

### Step 2: Transfer to Offline System

Transfer these directories to the offline system:
- `offline_packages/`
- `MICOS-2024/` (source code)
- Database files

### Step 3: Install Offline

```bash
# Install from local packages
pip install --no-index --find-links=./offline_packages -r requirements.txt

# Install MICOS
pip install -e MICOS-2024/
```

---

## Troubleshooting

### Issue: Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker run hello-world
```

### Issue: Conda Environment Creation Fails

```bash
# Clear conda cache
conda clean --all

# Update conda
conda update -n base conda

# Try with mamba
conda install mamba -c conda-forge -n base
mamba env create -f environment.yml --force
```

### Issue: Database Download Fails

```bash
# Use mirror sites
# For China users:
export KRAKEN2_DB_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/"

# Or download manually from:
# https://benlangmead.github.io/aws-indexes/k2
```

### Issue: Memory Error During Database Build

```bash
# Reduce threads during build
kraken2-build --build --db /path/to/db --threads 4

# Or use pre-built databases
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20231009.tar.gz
```

---

## Next Steps

- 📖 [User Manual](user_manual.md) - Learn how to use MICOS-2024
- ⚙️ [Configuration Guide](configuration.md) - Customize your analysis
- 🧪 [Test Data](user_manual.md#test-data) - Run example analysis

---

## Getting Help

- 📋 [FAQ](faq.md)
- 🔧 [Troubleshooting](troubleshooting.md)
- 💬 [GitHub Discussions](https://github.com/BGI-MICOS/MICOS-2024/discussions)
- 🐛 [Report Issues](https://github.com/BGI-MICOS/MICOS-2024/issues)
