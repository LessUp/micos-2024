---
title: FAQ
---

# Frequently Asked Questions (FAQ)

Quick answers to common questions about MICOS-2024.

---

## General Questions

### What is MICOS-2024?

MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite) is an integrated platform for end-to-end metagenomic analysis. It combines quality control, taxonomic profiling, functional annotation, and diversity analysis into a unified workflow.

### Who should use MICOS-2024?

- **Biologists**: With minimal bioinformatics experience
- **Bioinformaticians**: Who need standardized, reproducible workflows
- **Clinical researchers**: Analyzing microbiome samples
- **Ecologists**: Studying environmental microbiomes

### How does MICOS-2024 compare to other tools?

| Feature | MICOS-2024 | Qiime2 | MG-RAST | mothur |
|:---|:---|:---:|:---:|:---:|
| End-to-end workflow | ✓ | Partial | ✓ | Partial |
| WDL workflows | ✓ | x | x | x |
| Docker support | ✓ | ✓ | x | x |
| CLI interface | ✓ | ✓ | Web | ✓ |
| Pipeline flexibility | High | Medium | Low | Medium |

---

## Installation Questions

### What's the recommended installation method?

**Docker** for:
- Maximum reproducibility
- Easy deployment on servers
- Production environments

**Conda** for:
- Development work
- Custom modifications
- Systems without Docker

### How much disk space do I need?

| Component | Minimum | Recommended |
|:---|:---:|:---:|
| Software installation | 5 GB | 10 GB |
| Kraken2 database | 70 GB | 150 GB (PlusPF) |
| HUMAnN database | 30 GB | 50 GB |
| Analysis output | 100 GB | 500 GB |
| Total | ~200 GB | ~700 GB |

### Can I install without administrator privileges?

Yes! Both installation methods work without sudo:
- **Docker**: Requires user added to `docker` group
- **Conda**: Installs entirely in user directory

### Do I need a GPU?

No. MICOS-2024 is CPU-based. GPU acceleration is not currently supported.

---

## Analysis Questions

### How long does analysis take?

Approximate times per sample (10M paired-end reads):

| Step | Time | Notes |
|:---|:---:|:---|
| Quality Control | 10-30 min | Depends on host genome size |
| Taxonomic Profiling | 5-15 min | With Kraken2 standard |
| Functional Annotation | 1-4 hours | Depends on database |
| Diversity Analysis | 10-30 min | Per calculation |
| Total | 2-6 hours | Highly parallelizable |

**Speed tips**:
- Use SSD for temporary files
- Increase `--threads` parameter
- Use MiniKraken for testing

### What sequencing depth do I need?

| Study Type | Minimum | Recommended |
|:---|:---:|:---:|
| Pilot/testing | 1M reads/sample | 2M reads/sample |
| General profiling | 5M reads/sample | 10M reads/sample |
| Rare species detection | 20M reads/sample | 50M reads/sample |
| Functional analysis | 10M reads/sample | 30M reads/sample |

### Can I analyze single-end data?

Yes, MICOS-2024 supports both paired-end and single-end data. However:
- **Paired-end recommended** for better taxonomic resolution
- **Single-end sufficient** for functional profiling

---

## Database Questions

### Which Kraken2 database should I use?

| Database | Size | Best For |
|:---|:---:|:---|
| MiniKraken2 (8GB) | Small | Testing, limited RAM |
| Standard (70GB) | Medium | General purpose |
| PlusPF (100GB) | Large | Including fungi/protozoa |
| PlusPFP (150GB) | X-Large | Maximum coverage |

### Can I use custom reference databases?

Yes:

```bash
# Build custom Kraken2 database
kraken2-build --download-taxonomy --db custom_db
kraken2-build --add-to-library my_genomes/*.fa --db custom_db
kraken2-build --build --threads 16 --db custom_db
```

---

## Results Questions

### Why are most of my reads unclassified?

Possible reasons:

| Reason | Check | Solution |
|:---|:---|:---|
| Database too small | Use Standard not MiniKraken | Download larger DB |
| Confidence too high | Check config | Lower to 0.05-0.1 |
| Novel organisms | Literature search | Build custom DB |
| Data quality | Run FastQC | Improve QC parameters |

### Which diversity metric should I use?

**Alpha Diversity**:
- **Shannon**: General diversity (richness + evenness)
- **Chao1**: Richness estimation
- **Observed**: Simple species count

**Beta Diversity**:
- **Bray-Curtis**: Standard for abundance data
- **UniFrac**: When phylogeny matters

### What's a "good" diversity value?

Human gut typical ranges:

| Metric | Low | Normal | High |
|:---|:---:|:---:|:---:|
| Shannon | <2.5 | 2.5-4.0 | >4.0 |
| Species richness | <50 | 50-150 | >150 |

::: warning Note
Context-dependent! Compare within same sample type.
:::

---

## Performance Questions

### Can I run MICOS on a laptop?

For small datasets (test data, <5 samples):
- **Minimum**: 16GB RAM, 4 cores
- **Recommended**: 32GB RAM, 8 cores

For production analysis, use servers or cloud instances.

### How do I optimize for speed?

| Action | Improvement | Trade-off |
|:---|:---:|:---|
| Use SSD for temp | 2-3x faster | Need SSD storage |
| Increase threads | Linear to ~32 | More RAM needed |
| Use MiniKraken | 5-10x faster | Lower sensitivity |

---

## Still Have Questions?

- Check the [Getting Started](./guides/getting-started.md) guide
- See [Troubleshooting](./troubleshooting.md) for common issues
- Start a [Discussion](https://github.com/BGI-MICOS/MICOS-2024/discussions)
- Report an [Issue](https://github.com/BGI-MICOS/MICOS-2024/issues)
