# API Reference

Complete reference for MICOS-2024 command-line interface.

---

## Table of Contents

- [Overview](#overview)
- [Global Options](#global-options)
- [Commands](#commands)
  - [full-run](#full-run)
  - [run](#run)
  - [validate-config](#validate-config)

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

### Examples

```bash
# Use custom config
python -m micos.cli --config my_config.yaml full-run --input-dir data/

# Verbose output with custom log
python -m micos.cli --verbose --log-file analysis.log full-run ...

# Dry run (preview only)
python -m micos.cli --dry-run full-run --input-dir data/
```

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

#### Examples

```bash
# Basic usage
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /db/human_genome \
  --kraken2-db /db/kraken2_standard

# Analyze specific samples only
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --samples SampleA,SampleB,SampleC

# Skip functional analysis (taxonomy only)
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --skip-functional
```

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

**Arguments**:

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-dir` | ✓ | Raw FASTQ directory |
| `--output-dir` | ✓ | QC results directory |
| `--kneaddata-db` | ✓ | Host genome database |
| `--threads` | | Parallel threads |

**Example**:
```bash
python -m micos.cli run quality-control \
  --input-dir data/raw_input \
  --output-dir results/quality_control \
  --kneaddata-db /db/human_genome \
  --threads 8
```

---

#### taxonomic-profiling

```bash
python -m micos.cli run taxonomic-profiling [OPTIONS]
```

**Arguments**:

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-dir` | ✓ | Cleaned FASTQ directory (QC output) |
| `--output-dir` | ✓ | Taxonomy results directory |
| `--kraken2-db` | ✓ | Kraken2 database path |
| `--confidence` | | Classification confidence threshold |
| `--threads` | | Parallel threads |

**Example**:
```bash
python -m micos.cli run taxonomic-profiling \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/taxonomic_profiling \
  --kraken2-db /db/kraken2_standard \
  --confidence 0.1 \
  --threads 16
```

---

#### diversity-analysis

```bash
python -m micos.cli run diversity-analysis [OPTIONS]
```

**Arguments**:

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-biom` | ✓ | BIOM feature table path |
| `--output-dir` | ✓ | Diversity results directory |
| `--metadata` | | Sample metadata file |
| `--sampling-depth` | | Rarefaction depth |

**Example**:
```bash
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis \
  --metadata metadata.tsv \
  --sampling-depth 10000
```

---

#### functional-annotation

```bash
python -m micos.cli run functional-annotation [OPTIONS]
```

**Arguments**:

| Argument | Required | Description |
|:---|:---:|:---|
| `--input-dir` | ✓ | Cleaned FASTQ directory |
| `--output-dir` | ✓ | Functional results directory |
| `--threads` | | Parallel threads |
| `--nucleotide-db` | | ChocoPhlAN database |
| `--protein-db` | | UniRef database |

**Example**:
```bash
python -m micos.cli run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 8
```

---

#### summarize-results

```bash
python -m micos.cli run summarize-results [OPTIONS]
```

**Arguments**:

| Argument | Required | Description |
|:---|:---:|:---|
| `--results-dir` | ✓ | Main results directory |
| `--output-file` | ✓ | Output HTML report path |
| `--format` | | Output format (html, pdf) |

**Example**:
```bash
python -m micos.cli run summarize-results \
  --results-dir results \
  --output-file results/final_report.html
```

---

### validate-config

Validate configuration file before running analysis.

#### Synopsis

```bash
python -m micos.cli validate-config [OPTIONS]
```

**Arguments**:

| Argument | Required | Description |
|:---|:---:|:---|
| `--config` | | Path to configuration file |

**Example**:
```bash
# Validate default config
python -m micos.cli validate-config

# Validate custom config
python -m micos.cli validate-config --config my_config.yaml
```

**Output**:
```
✓ Configuration file syntax valid
✓ Required fields present
✓ Database paths exist
✓ Parameter values in valid range
⚠ Warning: Sampling depth not specified (will auto-detect)
Configuration validation completed successfully!
```

---

## Configuration File Reference

### Location

Default configuration search order:
1. Path specified with `--config`
2. `./config/analysis.yaml`
3. `~/.config/micos/analysis.yaml`

### Structure

```yaml
# config/analysis.yaml

project:
  name: "My_Study"
  description: "Metagenomic analysis of gut samples"

paths:
  input_dir: "data/raw"
  output_dir: "results"

resources:
  max_threads: 16
  max_memory: "32GB"

quality_control:
  kneaddata:
    min_quality: 20
    min_length: 50

taxonomic_profiling:
  kraken2:
    confidence: 0.1
    threads: 16

diversity_analysis:
  qiime2:
    sampling_depth: 10000

functional_annotation:
  humann:
    threads: 8
```

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

## Batch Processing

### Running Multiple Samples

```bash
# Process multiple datasets
for dataset in dataset1 dataset2 dataset3; do
  python -m micos.cli full-run \
    --input-dir "data/${dataset}" \
    --results-dir "results/${dataset}" \
    --config "config/${dataset}.yaml"
done
```

### Parallel Sample Processing

```bash
# GNU parallel for parallel sample processing
ls data/*/ | parallel -j 4 \
  'python -m micos.cli run taxonomic-profiling \
    --input-dir data/{} \
    --output-dir results/{}/taxonomy'
```

---

## See Also

- [Configuration Guide](configuration.md) - Detailed configuration options
- [User Manual](user_manual.md) - Step-by-step usage guide
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
