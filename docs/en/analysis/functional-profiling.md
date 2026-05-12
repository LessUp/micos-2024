---
title: Functional Profiling
---

# Functional Profiling

Complete guide to functional annotation and pathway analysis using HUMAnN within MICOS-2024.

---

## Overview

Functional profiling characterizes the metabolic potential of microbial communities by quantifying gene families and metabolic pathways. Unlike taxonomic profiling which answers "who is there?", functional profiling answers "what can they do?"

### Key Features

- **Gene family quantification**: UniRef90 protein clusters
- **Pathway analysis**: MetaCyc metabolic pathways
- **Species stratification**: Attribute functions to specific taxa
- **Multi-sample integration**: Compare functional profiles across samples

---

## Methodology

### HUMAnN Analysis Pipeline

```
Input Reads
    ↓
[MetaPhlAn] → Taxonomic profile
    ↓
[Mapping] → Split reads by species
    ↓
[ChocoPhlAn] → Align to pangenomes (nucleotide)
    ↓
[UniRef90] → Align unmapped to proteins
    ↓
[Pathway Reconstruction] → MinPath + gap filling
    ↓
Gene Families + Pathway Abundance + Coverage
```

### Functional Ontologies

| Level | Database | Description |
|:---|:---|:---|
| Gene Families | UniRef90 | Groups of protein sequences (>90% identical) |
| Pathways | MetaCyc | Curated metabolic pathways |
| Modules | KEGG | Functional units of metabolism |

---

## Input Requirements

### Database Requirements

| Database | Size | Description |
|:---|:---:|:---|
| ChocoPhlAn | ~10 GB | Nucleotide pangenome database |
| UniRef90 | ~20 GB | Protein families (>90% identity) |
| UniRef50 | ~5 GB | Reduced protein families (>50% identity) |
| MetaCyc | Included | Metabolic pathway definitions |

**Storage tip**: Use UniRef50 for faster processing, UniRef90 for comprehensive results.

---

## Running the Analysis

### Option 1: MICOS CLI

```bash
# Functional annotation only
python -m micos.cli run functional-annotation \
  --input-dir results/quality_control/kneaddata \
  --output-dir results/functional_annotation \
  --threads 16

# As part of full pipeline
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /db/kneaddata \
  --kraken2-db /db/kraken2
```

### Option 2: Direct HUMAnN

```bash
# Basic run
humann --input sample.fastq \
  --output output_dir/ \
  --nucleotide-database /db/chocophlan \
  --protein-database /db/uniref90 \
  --threads 16
```

---

## Parameter Configuration

### HUMAnN Configuration

```yaml
functional_annotation:
  enabled: true

  humann:
    enabled: true
    threads: 16

    # Database paths
    nucleotide_database: "${paths.databases}/humann/chocophlan"
    protein_database: "${paths.databases}/humann/uniref90"

    # Search options
    search_mode: "diamond"    # diamond or usearch

    # Sensitivity vs speed trade-off
    diamond_options: "--mid-sensitive"

    # Pathway options
    pathway_coverage: true
    gap_fill: true            # Fill pathway gaps
    minpath: true             # Use MinPath for pathway selection

    # Output options
    remove_temp: true
```

### Database Selection Guide

| Database | Time | Sensitivity | Use Case |
|:---|:---:|:---:|:---|
| ChocoPhlAn only | Fast | Species-dependent | Known species abundant |
| + UniRef50 | Moderate | Good | Balance speed/coverage |
| + UniRef90 | Slow | Best | Maximum sensitivity |

---

## Output Files

### Directory Structure

```
results/functional_annotation/
├── sample_genefamilies.tsv         # Gene family abundances
├── sample_genefamilies-cpm.tsv     # Normalized to CPM
├── sample_pathabundance.tsv        # Pathway abundances
├── sample_pathcoverage.tsv         # Pathway coverage
├── sample_pathabundance-cpm.tsv    # Normalized pathway
└── sample.log                      # Run log
```

### Gene Families File

| Column | Description | Example |
|:---|:---|:---|
| # Gene Family | UniRef90 cluster | UniRef90_A0A0A0MQD6 |
| Sample1 | Abundance (RPK) | 45.23 |

**Special entries**:
- `UNMAPPED`: Reads not matching any gene
- `UNGROUPED`: Genes not in any UniRef cluster

### Pathway Coverage

Coverage indicates pathway completeness (0-1 scale):

| Coverage | Interpretation |
|:---:|:---|
| 1.0 | Complete pathway present |
| 0.5-0.9 | Partial pathway |
| < 0.5 | Fragmented pathway |

---

## Downstream Analysis

### Normalization

```bash
# CPM (Copies Per Million) normalization
humann_renorm_table \
  -i sample_genefamilies.tsv \
  -o sample_genefamilies-cpm.tsv \
  --units cpm
```

### Regrouping to Other Ontologies

```bash
# To KEGG Orthology (KO)
humann_regroup_table \
  -i sample_genefamilies.tsv \
  -g uniref90_ko \
  -o sample_ko.tsv

# To GO terms
humann_regroup_table \
  -i sample_genefamilies.tsv \
  -g uniref90_go \
  -o sample_go.tsv
```

---

## Troubleshooting

### Issue: Running Too Slow

```yaml
# Use faster settings
functional_annotation:
  humann:
    diamond_options: "--fast"
    threads: 32
    # Or use UniRef50 instead of UniRef90
    protein_database: "/db/uniref50"
```

### Issue: Most Reads Unmapped

```bash
# 1. Check input quality
fastqc sample.fastq

# 2. Verify database installation
ls -lh /db/humann/chocophlan/
ls -lh /db/humann/uniref90/
```

---

## See Also

- [Taxonomic Profiling](./taxonomic-profiling.md) - Species classification
- [Diversity Analysis](./diversity-analysis.md) - Community structure
- [Configuration](../configuration.md) - Parameter details
