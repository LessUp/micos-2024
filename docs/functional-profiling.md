# Functional Profiling

Complete guide to functional annotation and pathway analysis using HUMAnN within MICOS-2024.

---

## Table of Contents

- [Overview](#overview)
- [Methodology](#methodology)
- [Input Requirements](#input-requirements)
- [Running the Analysis](#running-the-analysis)
- [Parameter Configuration](#parameter-configuration)
- [Output Files](#output-files)
- [Result Interpretation](#result-interpretation)
- [Downstream Analysis](#downstream-analysis)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

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

### Algorithm Overview

1. **Taxonomic Profiling (MetaPhlAn)**
   - Quickly identify species present
   - Guide nucleotide search strategy

2. **Nucleotide-level Search (ChocoPhlAn)**
   - Map reads to species-specific gene families
   - High sensitivity for known species

3. **Protein-level Search (UniRef90)**
   - Diamond alignment for unmapped reads
   - Detect novel functions

4. **Pathway Reconstruction (MinPath)**
   - Identify complete metabolic pathways
   - Conservative: pathway must have all required reactions

### Functional Ontologies

| Level | Database | Description |
|:---|:---|:---|
| Gene Families | UniRef90 | Groups of protein sequences (>90% identical) |
| Pathways | MetaCyc | Curated metabolic pathways |
| Modules | KEGG | Functional units of metabolism |

---

## Input Requirements

### Input Data

| Source | Format | Description |
|:---|:---|:---|
| KneadData output | FASTQ | Quality-controlled, host-removed reads |
| Any cleaned reads | FASTQ/FASTA | Adapter-trimmed, quality-filtered |

### File Structure

```
input_dir/
├── sample1_paired_1.fastq.gz
├── sample1_paired_2.fastq.gz
├── sample1_unmatched_1.fastq.gz
├── sample1_unmatched_2.fastq.gz
├── sample2_paired_1.fastq.gz
└── ...
```

_Note: HUMAnN automatically detects paired and unpaired reads._

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

# Separate steps for control
# Step 1: Gene family quantification
humann --input sample.fastq \
  --output output_dir/ \
  --bypass-translated-search

# Step 2: Regroup to other ontologies
humann_regroup_table \
  -i sample_genefamilies.tsv \
  -g uniref90_ko \
  -o sample_ko.tsv

# Step 3: Pathway annotation
humann --input sample.fastq \
  --output output_dir/ \
  --resume \
  --gap-fill on \
  --minpath on
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

### Performance Tuning

```yaml
functional_annotation:
  humann:
    # Fast mode (for large datasets)
    threads: 32
    diamond_options: "--fast"
    
    # Comprehensive mode (for publication)
    threads: 16
    diamond_options: "--sensitive"
    gap_fill: true
    pathway_coverage: true
```

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
| Sample2 | Abundance (RPK) | 12.56 |

**Special entries**:
- `UNMAPPED`: Reads not matching any gene
- `UNGROUPED`: Genes not in any UniRef cluster

### Pathway Abundance File

| Column | Description | Example |
|:---|:---|:---|
| # Pathway | MetaCyc pathway | GLYCOLYSIS |
| Sample1 | Abundance | 145.2 |

**Stratified format**: `PATHWAY|Species` shows species contribution

Example:
```
GLYCOLYSIS|g__Bacteroides.s__Bacteroides_thetaiotaomicron    45.2
GLYCOLYSIS|g__Faecalibacterium.s__Faecalibacterium_prausnitzii    32.1
GLYCOLYSIS|unclassified    12.5
```

### Pathway Coverage File

Coverage indicates pathway completeness (0-1 scale):

| Coverage | Interpretation |
|:---:|:---|
| 1.0 | Complete pathway present |
| 0.5-0.9 | Partial pathway |
| < 0.5 | Fragmented pathway |

---

## Result Interpretation

### Quality Metrics

#### Mapping Rate

```bash
# Check mapping statistics in log file
grep "total aligned" sample.log
```

| Mapping Rate | Interpretation | Action |
|:---:|:---|:---|
| < 20% | Poor | Check data quality and database |
| 20-50% | Moderate | Acceptable for novel communities |
| 50-70% | Good | Standard performance |
| > 70% | Excellent | High-quality reference genomes |

#### Unmapped Reads

High unmapped rate may indicate:
- Novel taxa not in reference
- Viral sequences
- Host contamination (check QC)
- Low-quality sequencing

### Functional Richness

```bash
# Count unique gene families
cut -f1 sample_genefamilies.tsv | tail -n +2 | wc -l

# Count pathways
cut -f1 sample_pathabundance.tsv | tail -n +2 | wc -l
```

Typical ranges for human gut:
- Gene families: 100,000-500,000
- Pathways: 200-400

### Top Functions

```bash
# Top gene families (after normalization)
sort -k2,2nr sample_genefamilies-cpm.tsv | head -20

# Top pathways
sort -k2,2nr sample_pathabundance-cpm.tsv | head -20
```

---

## Downstream Analysis

### Normalization

```bash
# CPM (Copies Per Million) normalization
humann_renorm_table \
  -i sample_genefamilies.tsv \
  -o sample_genefamilies-cpm.tsv \
  --units cpm

# Relative abundance (fraction of total)
humann_renorm_table \
  -i sample_genefamilies.tsv \
  -o sample_genefamilies-relab.tsv \
  --units relab
```

### Stratification Analysis

```bash
# Split stratified table
humann_split_stratified_table \
  -i sample_genefamilies-cpm.tsv \
  -o stratified/

# Outputs:
#   stratified/sample_genefamilies-stratified.tsv
#   stratified/sample_genefamilies-unstratified.tsv
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

# To EC numbers
humann_regroup_table \
  -i sample_genefamilies.tsv \
  -g uniref90_ec \
  -o sample_ec.tsv
```

### Multi-Sample Analysis

```bash
# Join multiple samples
humann_join_tables \
  -i results/functional_annotation/ \
  -o merged_genefamilies.tsv \
  --file_name genefamilies

# Normalize merged table
humann_renorm_table \
  -i merged_genefamilies.tsv \
  -o merged_genefamilies-cpm.tsv \
  --units cpm
```

### Association Testing

```bash
# Test association with metadata
humann_associate \
  -i merged_genefamilies-cpm.tsv \
  -m metadata.tsv \
  -f group \
  -o association_results.tsv
```

### Differential Abundance

```python
# Using Python/Pandas
import pandas as pd
from scipy import stats

# Load normalized data
df = pd.read_csv('merged_genefamilies-cpm.tsv', 
                 sep='\t', index_col=0)

# Load metadata
meta = pd.read_csv('metadata.tsv', sep='\t', index_col=0)

# Perform t-test for each gene family
results = []
for gene in df.index:
    group_a = df.loc[gene, meta['group'] == 'Control']
    group_b = df.loc[gene, meta['group'] == 'Treatment']
    
    t_stat, p_val = stats.ttest_ind(group_a, group_b)
    results.append({'gene': gene, 'p_value': p_val})

results_df = pd.DataFrame(results)
```

---

## Advanced Topics

### Custom Gene Families

```bash
# Create custom database
humann_databases --download chocophlan full /custom/path

# Add custom sequences
cat custom_genes.fa >> /custom/path/chocophlan/*.ffn
```

### Focused Pathway Analysis

```bash
# Analyze specific pathways only
humann --input sample.fastq \
  --output output/ \
  --pathways metacyc \
  --gap-fill on \
  --pathway min
```

### Metatranscriptome Integration

```bash
# Use HUMAnN with transcriptomic data
humann --input sample_rna.fastq \
  --output rnaseq_output/ \
  --bypass-prescreen  # Don't skip protein search
```

---

## Troubleshooting

### Issue: Running Too Slow

**Solutions**:
```yaml
# Use faster settings
functional_annotation:
  humann:
    diamond_options: "--fast"
    threads: 32
    # Or use UniRef50 instead of UniRef90
    protein_database: "/db/uniref50"
```

### Issue: Memory Errors

**Solutions**:
```bash
# Reduce threads
humann --threads 8 ...

# Use memory-efficient mode
humann --memory-use minimum ...

# Process samples sequentially instead of parallel
```

### Issue: Most Reads Unmapped

**Diagnostic steps**:
```bash
# 1. Check input quality
fastqc sample.fastq

# 2. Verify database installation
ls -lh /db/humann/chocophlan/
ls -lh /db/humann/uniref90/

# 3. Check species coverage in MetaPhlAn output
# If unknown species dominate, need broader database
```

### Issue: Empty Pathway Results

**Solutions**:
```yaml
functional_annotation:
  humann:
    gap_fill: true        # Enable gap filling
    minpath: false        # Disable strict MinPath
```

---

## See Also

- [Taxonomic Profiling](taxonomic-profiling.md) - Species classification
- [Diversity Analysis](diversity-analysis.md) - Community structure
- [Configuration Guide](configuration.md) - Parameter details
- [HUMAnN Documentation](https://huttenhower.sph.harvard.edu/humann) - Official HUMAnN docs
