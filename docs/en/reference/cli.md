---
title: CLI Reference
---

# CLI Reference

Complete reference for MICOS-2024 command-line interface.

---

## Overview

MICOS-2024 provides a unified command-line interface (CLI) for metagenomic analysis. All commands follow the pattern:

```bash
python -m micos.cli [GLOBAL_OPTIONS] <COMMAND> [COMMAND_OPTIONS]
```

### Getting Help

```bash
# General help
python -m micos.cli --help

# Command-specific help
python -m micos.cli full-run --help
python -m micos.cli run quality-control --help
```

---

## Global Options

| Option | Short | Description | Default |
|:---|:---:|:---|:---|
| `--config` | `-c` | Path to configuration file | `config/analysis.yaml` |
| `--verbose` | `-v` | Enable verbose output | `false` |
| `--log-file` | `-l` | Path to log file | `logs/micos.log` |
| `--threads` | `-t` | Number of parallel threads | `16` |
| `--dry-run` | `-n` | Show what would be executed | `false` |
| `--version` | `-V` | Show version information | - |

---

## Commands

### full-run

Execute the complete analysis pipeline from raw reads to final report.

#### Synopsis

```bash
python -m micos.cli full-run [OPTIONS]
```

#### Required Arguments

| Argument | Description | Example |
|:---|:---|:---|
| `--input-dir` | Directory containing raw FASTQ files | `--input-dir data/raw` |
| `--results-dir` | Directory for output files | `--results-dir results` |

#### Database Arguments

| Argument | Description | Example |
|:---|:---|:---|
| `--kneaddata-db` | Path to KneadData database | `--kneaddata-db /db/human_genome` |
| `--kraken2-db` | Path to Kraken2 database | `--kraken2-db /db/kraken2_standard` |

#### Optional Arguments

| Argument | Description | Default |
|:---|:---|:---|
| `--threads` | Maximum parallel threads | `16` |
| `--samples` | Comma-separated sample list | All samples |
| `--skip-qc` | Skip quality control | `false` |
| `--skip-taxonomy` | Skip taxonomic profiling | `false` |
| `--skip-functional` | Skip functional annotation | `false` |
| `--skip-diversity` | Skip diversity analysis | `false` |

#### Output Structure

```
results/
├── quality_control/
│   ├── fastqc_reports/
│   └── kneaddata/
├── taxonomic_profiling/
│   ├── *.kraken
│   ├── *.report
│   ├── *.krona.html
│   └── feature-table.biom
├── functional_annotation/
│   ├── *_genefamilies.tsv
│   └── *_pathabundance.tsv
├── diversity_analysis/
│   ├── alpha_diversity/
│   └── beta_diversity/
└── report.html
```

---

### run

Execute individual analysis modules.

#### Synopsis

```bash
python -m micos.cli run <MODULE> [OPTIONS]
```

#### Available Modules

| Module | Description |
|:---|:---|
| `quality-control` | FastQC and KneadData processing |
| `taxonomic-profiling` | Kraken2 classification |
| `diversity-analysis` | QIIME2 diversity metrics |
| `functional-annotation` | HUMAnN functional profiling |
| `summarize-results` | Generate HTML report |

---

#### quality-control

```bash
python -m micos.cli run quality-control [OPTIONS]
```

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-dir` | ✓ | Raw FASTQ directory |
| `--output-dir` | ✓ | QC results directory |
| `--kneaddata-db` | ✓ | Host genome database |
| `--threads` | | Parallel threads |

---

#### taxonomic-profiling

```bash
python -m micos.cli run taxonomic-profiling [OPTIONS]
```

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-dir` | ✓ | Cleaned FASTQ directory (QC output) |
| `--output-dir` | ✓ | Taxonomy results directory |
| `--kraken2-db` | ✓ | Kraken2 database path |
| `--confidence` | | Classification confidence threshold |
| `--threads` | | Parallel threads |

---

#### diversity-analysis

```bash
python -m micos.cli run diversity-analysis [OPTIONS]
```

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-biom` | ✓ | BIOM feature table path |
| `--output-dir` | ✓ | Diversity results directory |
| `--metadata` | | Sample metadata file |
| `--sampling-depth` | | Rarefaction depth |

---

#### functional-annotation

```bash
python -m micos.cli run functional-annotation [OPTIONS]
```

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-dir` | ✓ | Cleaned FASTQ directory |
| `--output-dir` | ✓ | Functional results directory |
| `--threads` | | Parallel threads |
| `--nucleotide-db` | | ChocoPhlAN database |
| `--protein-db` | | UniRef database |

---

### validate-config

Validate configuration file before running analysis.

```bash
python -m micos.cli validate-config [OPTIONS]
```

| Argument | Required | Description |
|:---|:---:|:---|
| `--config` | | Path to configuration file |

---

## Return Codes

| Code | Meaning |
|:---:|:---|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Configuration error |
| 4 | Missing dependencies |
| 5 | Database error |
| 6 | I/O error |
| 130 | Interrupted by user |

---

## Environment Variables

| Variable | Description | Example |
|:---|:---|:---|
| `MICOS_CONFIG` | Default config file path | `/path/to/config.yaml` |
| `MICOS_THREADS` | Default thread count | `16` |
| `MICOS_LOG_LEVEL` | Logging level | `INFO`, `DEBUG` |
| `KRAKEN2_DB_PATH` | Default Kraken2 database | `/db/kraken2` |

---

## See Also

- [Configuration](../configuration.md) - Detailed configuration options
- [Getting Started](../guides/getting-started.md) - Installation guide
- [Troubleshooting](../troubleshooting.md) - Common issues and solutions
