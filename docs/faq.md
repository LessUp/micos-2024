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
| End-to-end workflow | ✅ | Partial | ✅ | Partial |
| WDL workflows | ✅ | ❌ | ❌ | ❌ |
| Docker support | ✅ | ✅ | ❌ | ❌ |
| CLI interface | ✅ | ✅ | Web | ✅ |
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
| **Total** | **~200 GB** | **~700 GB** |

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
| **Total** | **2-6 hours** | Highly parallelizable |

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
- Specify format in configuration or let auto-detection handle it

### What about amplicon data (16S)?

While MICOS-2024 is optimized for shotgun metagenomics, it can process 16S data:

```yaml
# Configuration for amplicon data
quality_control:
  kneaddata:
    bypass_trf: true    # Skip tandem repeat filter (not needed)

taxonomic_profiling:
  kraken2:
    confidence: 0.05    # Lower for conserved regions
```

For dedicated 16S analysis, consider DADA2 or QIIME2's q2-dada2 plugin.

---

## Database Questions

### Which Kraken2 database should I use?

| Database | Size | Best For |
|:---|:---:|:---|
| **MiniKraken2** (8GB) | Small | Testing, limited RAM |
| **Standard** (70GB) | Medium | General purpose |
| **PlusPF** (100GB) | Large | Including fungi/protozoa |
| **PlusPFP** (150GB) | X-Large | Maximum coverage |
| **Custom** | Variable | Specific organisms |

### Can I use custom reference databases?

Yes:

```bash
# Build custom Kraken2 database
kraken2-build --download-taxonomy --db custom_db
kraken2-build --add-to-library my_genomes/*.fa --db custom_db
kraken2-build --build --threads 16 --db custom_db

# Use in MICOS
kraken2-db: "/path/to/custom_db"
```

### Do I need to build databases myself?

No. Pre-built databases are available:
- **Kraken2**: [AWS Index](https://genome-idx.s3.amazonaws.com/kraken/)
- **HUMAnN**: `humann_databases --download`
- **KneadData**: `kneaddata_database --download`

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
| Environmental sample | Sample type | Use PlusPF database |

### Which diversity metric should I use?

**Alpha Diversity**:
- **Shannon**: General diversity (richness + evenness)
- **Chao1**: Richness estimation
- **Observed**: Simple species count

**Beta Diversity**:
- **Bray-Curtis**: Standard for abundance data
- **UniFrac**: When phylogeny matters
- **Aitchison**: For compositional data with zeros

### How do I interpret statistical results?

| Test | p < 0.05 means | Visualization |
|:---|:---|:---|
| PERMANOVA | Groups differ significantly | PCoA plot |
| Kruskal-Wallis | Alpha diversity differs | Box plot |
| LEfSe | Specific taxa different | Bar plot |

### What's a "good" diversity value?

Human gut typical ranges:

| Metric | Low | Normal | High |
|:---|:---:|:---:|:---:|
| Shannon | <2.5 | 2.5-4.0 | >4.0 |
| Species richness | <50 | 50-150 | >150 |

**Note**: Context-dependent! Compare within same sample type.

---

## Troubleshooting Questions

### Analysis failed - where do I start?

1. **Check logs**: `tail -n 50 logs/analysis.log`
2. **Verify inputs**: Input files exist and valid
3. **Check resources**: `free -h`, `df -h`
4. **Test with subset**: Run on 1-2 samples first

### Can I resume a failed analysis?

Yes, if outputs from completed steps exist:

```bash
# MICOS will skip completed steps
python -m micos.cli full-run \
  --input-dir data/raw \
  --results-dir results \
  --threads 16
  # Steps already done will be skipped
```

For manual control, run individual modules:
```bash
python -m micos.cli run taxonomic-profiling ...
python -m micos.cli run functional-annotation ...
```

### How do I update MICOS-2024?

```bash
# Update code
git pull origin main

# Docker - rebuild image
docker compose -f deploy/docker-compose.example.yml build

# Conda - update environment
conda activate micos-2024
pip install -e . --upgrade
```

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
| Disable gap filling | 2x faster | Less pathway info |

### Can I run MICOS on a cluster?

Yes! Several approaches:

1. **WDL/Cromwell**: Use provided workflows
2. **Snakemake**: Convert to Snakemake workflow
3. **Manual parallelization**: Split samples, merge results

---

## Integration Questions

### Can I use MICOS output with other tools?

Yes! Output formats are standard:

| Output | Format | Compatible With |
|:---|:---|:---|
| Feature table | BIOM | QIIME2, phyloseq, vegan |
| Taxonomy | TSV | R, Python, Excel |
| Pathways | TSV | Gephi, Cytoscape, R |

### How do I import to R?

```r
library(phyloseq)

# Import BIOM
physeq <- import_biom("feature-table.biom")

# Import metadata
sample_data <- read.csv("metadata.tsv", sep="\t", row.names=1)
sample_data(physeq) <- sample_data(sample_data)
```

### How do I import to Python?

```python
import pandas as pd
import biom

# Load BIOM table
with biom.load_table("feature-table.biom") as table:
    df = table.to_dataframe()

# Load taxonomy
taxonomy = pd.read_csv("taxonomy.tsv", sep="\t", index_col=0)
```

---

## Citation and License

### How do I cite MICOS-2024?

```bibtex
@software{micos2024,
  title = {MICOS-2024: Metagenomic Intelligence and Comprehensive Omics Suite},
  author = {MICOS-2024 Team},
  year = {2024},
  url = {https://github.com/BGI-MICOS/MICOS-2024},
  version = {1.1.0}
}
```

Also cite individual tools used (Kraken2, HUMAnN, QIIME2, etc.)

### What license is MICOS-2024 under?

MIT License - free for academic and commercial use.

---

## Still Have Questions?

- 📖 Check the [User Manual](user_manual.md)
- 🔧 See [Troubleshooting](troubleshooting.md)
- 💬 Start a [Discussion](https://github.com/BGI-MICOS/MICOS-2024/discussions)
- 🐛 Report an [Issue](https://github.com/BGI-MICOS/MICOS-2024/issues)
