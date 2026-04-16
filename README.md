# MICOS-2024: Metagenomic Intelligence and Comprehensive Omics Suite

<p align="center">
  <strong>End-to-End Metagenomic Analysis Platform</strong>
</p>

<p align="center">
  <a href="https://github.com/BGI-MICOS/MICOS-2024/releases/latest">
    <img src="https://img.shields.io/github/v/release/BGI-MICOS/MICOS-2024?style=flat-square&color=blue" alt="Latest Release">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" alt="License">
  </a>
  <a href="https://www.python.org/downloads/">
    <img src="https://img.shields.io/badge/Python-3.9+-green.svg?style=flat-square" alt="Python">
  </a>
  <a href="https://www.docker.com/">
    <img src="https://img.shields.io/badge/Docker-Supported-blue.svg?style=flat-square" alt="Docker">
  </a>
</p>

<p align="center">
  <a href="https://github.com/BGI-MICOS/MICOS-2024/issues">Issues</a> •
  <a href="https://github.com/BGI-MICOS/MICOS-2024/discussions">Discussions</a> •
  <a href="docs/en/">Documentation</a> •
  <a href="docs/zh/">中文文档</a>
</p>

---

## Overview

**MICOS-2024** is a comprehensive, production-ready platform for metagenomic analysis that transforms raw sequencing data into actionable biological insights. Built for researchers who need reliability, reproducibility, and ease of use.

### What Makes MICOS-2024 Different?

| Feature | MICOS-2024 | Traditional Approaches |
|:---|:---|:---|
| **Integration** | Single unified pipeline | Multiple disconnected tools |
| **Reproducibility** | Docker + WDL workflows | Manual, error-prone steps |
| **Documentation** | Comprehensive bilingual guides | Scattered, outdated docs |
| **Support** | Active community + detailed guides | Limited help resources |

---

## Quick Start

### 30-Second Installation

```bash
# Clone repository
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024

# Deploy with Docker
docker compose -f deploy/docker-compose.example.yml up -d

# Run analysis
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

📖 **[Complete Installation Guide](docs/en/installation.md)** | **[安装指南](docs/zh/installation.md)**

---

## Key Features

### 🧬 Complete Analysis Pipeline

```
Raw FASTQ → Quality Control → Taxonomic Profiling → 
Diversity Analysis → Functional Annotation → HTML Report
```

| Module | Tools | Purpose |
|:---|:---|:---|
| **Quality Control** | FastQC, KneadData | Remove host DNA, trim adapters |
| **Taxonomic Profiling** | Kraken2, Bracken, Krona | Species classification |
| **Diversity Analysis** | QIIME2 | Alpha/Beta diversity |
| **Functional Annotation** | HUMAnN 3.x | Gene families & pathways |
| **Reporting** | Custom HTML generator | Interactive summaries |

### 🚀 Performance

- **Speed**: Processes 10M reads/sample in ~2 hours
- **Scalability**: Tested on 1000+ samples
- **Parallelization**: Multi-threading throughout

### 🐳 Deployment Options

| Method | Best For | Setup Time |
|:---|:---|:---:|
| **Docker** | Production, Servers | 5 min |
| **Conda** | Development, HPC | 15 min |
| **Source** | Customization | 30 min |

---

## Documentation

### English

| Document | Description |
|:---|:---|
| [Quick Start](docs/en/index.md) | Get running in 5 minutes |
| [Installation](docs/en/installation.md) | Detailed setup instructions |
| [User Manual](docs/en/user_manual.md) | Complete usage guide |
| [Configuration](docs/en/configuration.md) | Parameter reference |
| [Troubleshooting](docs/en/troubleshooting.md) | Common issues & solutions |

### 中文

| 文档 | 描述 |
|:---|:---|
| [快速开始](docs/zh/index.md) | 5分钟上手指南 |
| [安装指南](docs/zh/installation.md) | 详细安装说明 |
| [用户手册](docs/zh/user_manual.md) | 完整使用指南 |
| [配置指南](docs/zh/configuration.md) | 参数参考 |
| [故障排除](docs/zh/troubleshooting.md) | 常见问题与解决 |

---

## System Requirements

| Component | Minimum | Recommended |
|:---|:---:|:---:|
| **OS** | Linux/macOS | Linux (Ubuntu 20.04+) |
| **CPU** | 4 cores | 16+ cores |
| **RAM** | 16 GB | 32+ GB |
| **Storage** | 200 GB | 700+ GB SSD |

### Database Storage

| Database | Size | Use Case |
|:---:|:---:|:---|
| Kraken2 Standard | 70 GB | General profiling |
| Kraken2 MiniKraken | 8 GB | Testing/development |
| HUMAnN UniRef90 | 20 GB | Functional analysis |

---

## Citation

If you use MICOS-2024 in your research, please cite:

```bibtex
@software{micos2024,
  title = {MICOS-2024: Metagenomic Intelligence and Comprehensive Omics Suite},
  author = {MICOS-2024 Team},
  year = {2024},
  url = {https://github.com/BGI-MICOS/MICOS-2024},
  version = {1.1.0}
}
```

Also cite the individual tools used in your analysis (Kraken2, HUMAnN, QIIME2, etc.)

---

## Community

| Resource | Link |
|:---|:---|
| **Issues** | [Report bugs](https://github.com/BGI-MICOS/MICOS-2024/issues) |
| **Discussions** | [Ask questions](https://github.com/BGI-MICOS/MICOS-2024/discussions) |
| **Releases** | [Changelog](CHANGELOG.md) |
| **Contributing** | [Guidelines](CONTRIBUTING.md) |

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  <strong>MICOS-2024</strong> — Made with ❤️ for the Metagenomics Community
</p>

<p align="center">
  <a href="#top">⬆ Back to Top</a>
</p>
