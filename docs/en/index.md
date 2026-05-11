# MICOS-2024

Professional Metagenomic Analysis Platform

End-to-end analysis from raw sequencing data to biological insights

---

## What is MICOS-2024?

MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite) is an end-to-end metagenomic analysis platform that integrates industry-standard bioinformatics tools into a unified, reproducible workflow.

### Core Capabilities

| Module | Description | Tools |
|:---|:---|:---|
| :material-dna: Quality Control | Host DNA removal and quality filtering | KneadData, FastQC |
| :material-account-tree: Taxonomic Profiling | Rapid species classification | Kraken2, Bracken |
| :material-chart-bar: Diversity Analysis | Alpha/Beta diversity metrics | QIIME2 |
| :material-function: Functional Annotation | Gene family and pathway analysis | HUMAnN 3.x |
| :material-compare: Differential Analysis | Statistical comparison of taxa/functions | DESeq2, ALDEx2 |
| :material-graph: Network Analysis | Microbial co-occurrence networks | NetworkX, igraph |

### Key Features

- :whale: **Containerized** - Docker & Singularity support for reproducibility
- :zap: **High Performance** - Multi-threading, optimized for large datasets
- :chart_with_upwards_trend: **Rich Visualizations** - Interactive HTML reports, Krona charts
- :wrench: **Modular Design** - Run complete pipeline or individual steps
- :memo: **WDL Workflows** - Cromwell-compatible for cloud/HPC deployment

---

## Quick Start

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
  --threads 16
```

[:octicons-book-24: Full Installation Guide](installation.md)

---

## Documentation

| Document | Description |
|:---|:---|
| [Installation Guide](installation.md) | Complete installation instructions |
| [Configuration Guide](configuration.md) | Parameter configuration |
| [Taxonomic Profiling](taxonomic-profiling.md) | Species classification and visualization |
| [Functional Profiling](functional-profiling.md) | Gene family and pathway analysis |
| [API Reference](api-reference.md) | Complete CLI command reference |

---

## Links

- :material-github: [GitHub Repository](https://github.com/BGI-MICOS/MICOS-2024)
- :material-bug: [Issue Tracker](https://github.com/BGI-MICOS/MICOS-2024/issues)
- :material-forum: [Discussions](https://github.com/BGI-MICOS/MICOS-2024/discussions)

---

<p align="center">
  <a href="../zh/">中文文档</a> | <a href="https://github.com/BGI-MICOS/MICOS-2024">GitHub</a>
</p>
