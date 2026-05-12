---
title: Diversity Analysis
---

# Diversity Analysis

Comprehensive guide to microbial community diversity analysis in MICOS-2024.

---

## Overview

Diversity analysis measures the **richness** (number of taxa) and **evenness** (distribution of abundances) of microbial communities. These metrics provide insights into:

- **Community health**: Higher diversity often associated with stability
- **Treatment effects**: Changes in diversity under different conditions
- **Ecological patterns**: Spatial and temporal variation
- **Comparative studies**: Differences between ecosystems

---

## Types of Diversity

### Alpha Diversity (Within-Sample)

Measures diversity within individual samples:

| Metric | What it Measures | Best Used For |
|:---|:---|:---|
| Richness | Number of taxa | Community complexity |
| Shannon | Richness + Evenness | General diversity |
| Simpson | Dominance | Detecting dominance |
| Faith's PD | Phylogenetic diversity | Evolutionary breadth |

### Beta Diversity (Between-Samples)

Measures dissimilarity between samples:

| Metric | Weighting | Best Used For |
|:---|:---|:---|
| Bray-Curtis | Abundance | Community composition |
| Jaccard | Presence/Absence | Species overlap |
| UniFrac | Phylogenetic | Evolutionary turnover |
| Aitchison | Composition | Zero-inflated data |

---

## Input Requirements

### Data Format

| Format | Description | Source |
|:---|:---|:---|
| BIOM | Standard format for microbiome data | Kraken-biom, QIIME2 |
| TSV | Tab-delimited feature table | Custom tables |
| QZA | QIIME2 artifact | QIIME2 exports |

### Metadata Requirements

| Column | Description | Required For |
|:---|:---|:---|
| sample-id | Unique identifier | All analyses |
| group | Experimental group | Group comparisons |
| subject-id | Subject identifier | Paired/longitudinal |
| time-point | Time of collection | Longitudinal |

---

## Running the Analysis

### Option 1: MICOS CLI

```bash
# Diversity analysis from BIOM file
python -m micos.cli run diversity-analysis \
  --input-biom results/taxonomic_profiling/feature-table.biom \
  --output-dir results/diversity_analysis \
  --metadata metadata.tsv

# As part of full pipeline
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /db/kneaddata \
  --kraken2-db /db/kraken2
```

### Option 2: Direct QIIME2

```bash
# Import BIOM to QIIME2
qiime tools import \
  --input-path feature-table.biom \
  --type 'FeatureTable[Frequency]' \
  --output-path table.qza

# Rarefy table
qiime feature-table rarefy \
  --i-table table.qza \
  --p-sampling-depth 10000 \
  --o-rarefied-table table-rarefied.qza
```

---

## Alpha Diversity

### Metrics Overview

#### Richness Estimators

| Metric | Description | Interpretation |
|:---|:---|:---|
| Observed Features | Raw count of taxa | Simple richness |
| Chao1 | Estimated total richness | Accounts for unobserved taxa |

#### Diversity Indices

| Metric | Formula | Range | Notes |
|:---|:---|:---:|:---|
| Shannon | -Σ(pᵢ × ln(pᵢ)) | 0 to ~7 | Accounts for richness and evenness |
| Simpson | 1 - Σ(pᵢ²) | 0 to 1 | Probability two random reads are different |

#### Evenness Measures

| Metric | Description | Range |
|:---|:---|:---:|
| Pielou's J | Shannon / ln(S) | 0-1 |

### Implementation

```bash
# Calculate alpha diversity
qiime diversity alpha \
  --i-table table.qza \
  --p-metric shannon \
  --o-alpha-diversity shannon.qza

# Multiple metrics at once
qiime diversity alpha-rarefaction \
  --i-table table.qza \
  --p-metrics shannon \
  --p-metrics chao1 \
  --p-metrics observed_features \
  --p-min-depth 1000 \
  --p-max-depth 50000 \
  --m-metadata-file metadata.tsv \
  --o-visualization alpha-rarefaction.qzv
```

---

## Beta Diversity

### Distance Metrics

#### Compositional Metrics

| Metric | Type | Formula Characteristics |
|:---|:---|:---|
| Bray-Curtis | Abundance-based | D = Σ\|Aᵢ - Bᵢ\| / Σ(Aᵢ + Bᵢ) |
| Jaccard | Binary | D = 1 - (\|A ∩ B\| / \|A ∪ B\|) |

#### Phylogenetic Metrics

| Metric | Weighting | Sensitive To |
|:---|:---|:---|
| Unweighted UniFrac | Presence/absence | Phylogenetic novelty |
| Weighted UniFrac | Abundance | Phylogenetic turnover |

### Implementation

```bash
# Calculate beta diversity
qiime diversity beta \
  --i-table table.qza \
  --p-metric braycurtis \
  --o-distance-matrix braycurtis.qza

# PCoA
qiime diversity pcoa \
  --i-distance-matrix braycurtis.qza \
  --o-pcoa braycurtis-pcoa.qza
```

### PERMANOVA

Tests if groups differ in multivariate space:

```bash
qiime diversity beta-group-significance \
  --i-distance-matrix braycurtis.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --p-method permanova \
  --o-visualization braycurtis-permanova.qzv
```

**Interpretation**:
- **p < 0.05**: Significant difference between groups
- **R²**: Proportion of variance explained by grouping

---

## Interpretation Guidelines

### Alpha Diversity - Typical Values (Human Gut)

| Metric | Range | Notes |
|:---|:---:|:---|
| Observed features | 50-200 | Varies with sampling depth |
| Shannon | 2.5-4.5 | >4 indicates high diversity |
| Chao1 | 100-400 | Estimate of total richness |
| Pielou's J | 0.6-0.9 | >0.8 indicates even distribution |

### Beta Diversity - PCoA Interpretation

| Pattern | Interpretation |
|:---|:---|
| Tight clusters by group | Strong group effect |
| Overlapping clusters | Similar communities |
| Gradient pattern | Continuous environmental driver |
| Outliers | Unique community composition |

---

## See Also

- [Taxonomic Profiling](./taxonomic-profiling.md) - Species classification
- [Functional Profiling](./functional-profiling.md) - Functional analysis
- [Configuration](../configuration.md) - Parameter settings
