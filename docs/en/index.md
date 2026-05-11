# MICOS-2024

**Professional Metagenomic Analysis Platform**

End-to-end analysis from raw sequencing data to biological insights

---

## What is MICOS-2024?

MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite) is an end-to-end metagenomic analysis platform that integrates industry-standard bioinformatics tools into a unified, reproducible workflow.

### Core Capabilities

| Module | Description | Tools |
|--------|-------------|-------|
| Quality Control | Host DNA removal and quality filtering | KneadData, FastQC |
| Taxonomic Profiling | Rapid species classification | Kraken2, Bracken |
| Diversity Analysis | Alpha/Beta diversity metrics | QIIME2 |
| Functional Annotation | Gene family and pathway analysis | HUMAnN 3.x |
| Differential Analysis | Statistical comparison of taxa/functions | DESeq2, ALDEx2 |
| Network Analysis | Microbial co-occurrence networks | NetworkX, igraph |

### Key Features

- **Containerized** - Docker & Singularity support
- **High Performance** - Multi-threading, optimized for large datasets
- **Rich Visualizations** - Interactive HTML reports
- **Modular Design** - Run complete pipeline or individual steps
- **WDL Workflows** - Cromwell-compatible for cloud/HPC deployment

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/LessUp/micos-2024.git
cd micos-2024

# 2. Install via Docker (recommended)
docker compose -f deploy/docker-compose.example.yml up -d

# 3. Run analysis
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16
```

See [Installation Guide](installation.md) for details.

---

## Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](installation.md) | Complete installation instructions |
| [Configuration Guide](configuration.md) | Parameter configuration |
| [Taxonomic Profiling](taxonomic-profiling.md) | Species classification and visualization |
| [Functional Profiling](functional-profiling.md) | Gene family and pathway analysis |
| [API Reference](api-reference.md) | Complete CLI command reference |

---

## Links

- [GitHub Repository](https://github.com/LessUp/micos-2024)
- [Issue Tracker](https://github.com/LessUp/micos-2024/issues)
- [Discussions](https://github.com/LessUp/micos-2024/discussions)

---

[中文文档](../zh/index.md) | [GitHub](https://github.com/LessUp/micos-2024)
