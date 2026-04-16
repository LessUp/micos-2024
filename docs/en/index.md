# MICOS-2024 Documentation

<p align="center">
  <strong>Professional Metagenomic Analysis Platform</strong><br>
  <em>End-to-end analysis from raw sequencing data to biological insights</em>
</p>

---

## 🚀 5-Minute Quick Start

Get your first metagenomic analysis running in minutes:

```bash
# 1. Clone the repository
git clone https://github.com/BGI-MICOS/MICOS-2024.git
cd MICOS-2024

# 2. Install via Docker (recommended)
docker compose -f deploy/docker-compose.example.yml up -d

# 3. Run analysis
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

📖 **Full Installation Guide**: [installation.md](installation.md)

---

## 📚 Documentation Overview

### Getting Started

| Document | Description | For Whom |
|:---|:---|:---|
| [Installation Guide](installation.md) | Complete installation instructions | All users |
| [Quick Start](user_manual.md#quick-start) | 30-second test run | New users |
| [Configuration Guide](configuration.md) | Parameter configuration | All users |

### Analysis Modules

| Document | Description | Tools Used |
|:---|:---|:---|
| [Taxonomic Profiling](taxonomic-profiling.md) | Species classification and visualization | Kraken2, Krona, QIIME2 |
| [Functional Profiling](functional-profiling.md) | Gene family and pathway analysis | HUMAnN 3.x |
| [Diversity Analysis](diversity-analysis.md) | Alpha/Beta diversity metrics | QIIME2 |

### Reference

| Document | Description |
|:---|:---|
| [API Reference](api-reference.md) | Complete CLI command reference |
| [Troubleshooting](troubleshooting.md) | Common issues and solutions |
| [FAQ](faq.md) | Frequently asked questions |
| [Contributing Guide](contributing.md) | Development and contribution guidelines |

---

## 🎯 What is MICOS-2024?

MICOS-2024 is an **end-to-end metagenomic analysis platform** that integrates industry-standard bioinformatics tools into a unified, reproducible workflow.

### Core Capabilities

- **Quality Control**: Host DNA removal and quality filtering (KneadData, FastQC)
- **Taxonomic Profiling**: Rapid species classification (Kraken2, Bracken)
- **Diversity Analysis**: Alpha/Beta diversity metrics (QIIME2)
- **Functional Annotation**: Gene family and pathway analysis (HUMAnN)
- **Differential Analysis**: Statistical comparison of taxa/functions
- **Network Analysis**: Microbial co-occurrence networks

### Key Features

| Feature | Description |
|:---|:---|
| 🐳 **Containerized** | Docker & Singularity support for reproducibility |
| ⚡ **High Performance** | Multi-threading support, optimized for large datasets |
| 📊 **Rich Visualizations** | Interactive HTML reports, Krona charts, diversity plots |
| 🔧 **Modular Design** | Run complete pipeline or individual steps |
| 📝 **WDL Workflows** | Cromwell-compatible for cloud/HPC deployment |

---

## 💡 Typical Use Cases

### Case 1: Human Gut Microbiome Analysis

Study the composition and function of human gut microbiota:

```bash
# Run complete analysis
python -m micos.cli full-run \
  --input-dir gut_microbiome/ \
  --results-dir results/gut \
  --kneaddata-db /db/human_genome \
  --kraken2-db /db/kraken2_standard
```

**Outputs**:
- Taxonomic composition at phylum/genus/species level
- Functional pathway abundances (MetaCyc)
- Alpha diversity (Shannon, Chao1) and Beta diversity (PCoA)

### Case 2: Environmental Metagenomics

Analyze soil or water microbiome samples:

```bash
# Focus on taxonomic profiling with relaxed parameters
python -m micos.cli run taxonomic-profiling \
  --input-dir env_samples/ \
  --output-dir results/taxonomy \
  --kraken2-db /db/kraken2_pluspf \
  --confidence 0.05
```

### Case 3: Comparative Analysis

Compare treatment vs. control groups:

```bash
# Step 1: Run functional annotation
python -m micos.cli run functional-annotation \
  --input-dir cleaned_reads/ \
  --output-dir results/function

# Step 2: Differential abundance analysis
# (See user manual for detailed differential analysis)
```

---

## 📊 Performance Benchmarks

Typical analysis times (per 1M paired-end reads):

| Step | Tool | Time | Memory |
|:---|:---|:---:|:---:|
| Quality Control | KneadData | ~5 min | 8 GB |
| Taxonomic Profiling | Kraken2 | ~2 min | 16 GB |
| Functional Annotation | HUMAnN | ~20 min | 32 GB |
| Diversity Analysis | QIIME2 | ~10 min | 8 GB |

*Benchmarked on: AMD EPYC 7402, 64GB RAM, SSD storage*

---

## 🔗 Quick Links

- **Main Repository**: https://github.com/BGI-MICOS/MICOS-2024
- **Issue Tracker**: https://github.com/BGI-MICOS/MICOS-2024/issues
- **Discussions**: https://github.com/BGI-MICOS/MICOS-2024/discussions
- **Release Notes**: [changelog.md](changelog.md)

---

## 📖 Citation

If you use MICOS-2024 in your research, please cite:

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
  <strong>Ready to start?</strong> → <a href="installation.md">Installation Guide</a>
</p>

<p align="center">
  <a href="../zh/">中文文档</a> | <a href="../../README.md">Project README</a>
</p>
