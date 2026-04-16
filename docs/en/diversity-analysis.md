# Diversity Analysis

Comprehensive guide to microbial community diversity analysis in MICOS-2024.

---

## Table of Contents

- [Overview](#overview)
- [Types of Diversity](#types-of-diversity)
- [Input Requirements](#input-requirements)
- [Running the Analysis](#running-the-analysis)
- [Alpha Diversity](#alpha-diversity)
- [Beta Diversity](#beta-diversity)
- [Statistical Testing](#statistical-testing)
- [Visualization](#visualization)
- [Interpretation Guidelines](#interpretation-guidelines)
- [Advanced Topics](#advanced-topics)

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
| **Richness** | Number of taxa | Community complexity |
| **Shannon** | Richness + Evenness | General diversity |
| **Simpson** | Dominance | Detecting dominance |
| **Faith's PD** | Phylogenetic diversity | Evolutionary breadth |

### Beta Diversity (Between-Samples)

Measures dissimilarity between samples:

| Metric | Weighting | Best Used For |
|:---|:---|:---|
| **Bray-Curtis** | Abundance | Community composition |
| **Jaccard** | Presence/Absence | Species overlap |
| **UniFrac** | Phylogenetic | Evolutionary turnover |
| **Aitchison** | Composition | Zero-inflated data |

### Gamma Diversity

Total diversity across the entire dataset (landscape scale).

---

## Input Requirements

### Data Format

| Format | Description | Source |
|:---|:---|:---|
| BIOM | Standard format for microbiome data | Kraken-biom, QIIME2 |
| TSV | Tab-delimited feature table | Custom tables |
| QZA | QIIME2 artifact | QIIME2 exports |

### Feature Table Structure

```
# OTU/ASV table (samples as columns)
#OTU ID	Sample1	Sample2	Sample3
k__Bacteria;p__Firmicutes	125	89	203
k__Bacteria;p__Bacteroidetes	534	612	445
...
```

### Metadata Requirements

| Column | Description | Required For |
|:---|:---|:---|
| sample-id | Unique identifier | All analyses |
| group | Experimental group | Group comparisons |
| subject-id | Subject identifier | Paired/longitudinal |
| time-point | Time of collection | Longitudinal |
| [any] | Additional covariates | Multivariate analysis |

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

# Import metadata
qiime metadata tabulate \
  --m-input-file metadata.tsv \
  --o-visualization metadata.qzv

# Rarefy table
qiime feature-table rarefy \
  --i-table table.qza \
  --p-sampling-depth 10000 \
  --o-rarefied-table table-rarefied.qza
```

---

## Alpha Diversity

### Metrics Overview

#### 1. Richness Estimators

| Metric | Description | Interpretation |
|:---|:---|:---|
| **Observed Features** | Raw count of taxa | Simple richness |
| **Chao1** | Estimated total richness | Accounts for unobserved taxa |
| **ACE** | Abundance-based coverage | Alternative richness estimate |

**Formula - Chao1**:
```
Chao1 = S_obs + (n₁² / 2n₂)
Where:
  S_obs = observed species
  n₁ = number of singletons
  n₂ = number of doubletons
```

#### 2. Diversity Indices

| Metric | Formula | Range | Notes |
|:---|:---|:---:|:---|
| **Shannon** | -Σ(pᵢ × ln(pᵢ)) | 0 to ~7 | Accounts for richness and evenness |
| **Simpson** | 1 - Σ(pᵢ²) | 0 to 1 | Probability two random reads are different |
| **Inverse Simpson** | 1 / Σ(pᵢ²) | 1 to N | Higher = more diverse |

#### 3. Evenness Measures

| Metric | Description | Range |
|:---|:---|:---:|
| **Pielou's J** | Shannon / ln(S) | 0-1 |
| **Simpson's E** | (1/D) / S | 0-1 |
| **Heip's E** | (e^H - 1) / (S - 1) | 0-1 |

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

### Statistical Testing

```bash
# Group comparison
qiime diversity alpha-group-significance \
  --i-alpha-diversity shannon.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --o-visualization shannon-significance.qzv
```

**Common Tests**:
- **Kruskal-Wallis**: Non-parametric group comparison
- **Pairwise Wilcoxon**: Post-hoc comparisons
- **Linear mixed effects**: Longitudinal data

---

## Beta Diversity

### Distance Metrics

#### 1. Compositional Metrics

| Metric | Type | Formula Characteristics |
|:---|:---|:---|
| **Bray-Curtis** | Abundance-based | D = Σ\|Aᵢ - Bᵢ\| / Σ(Aᵢ + Bᵢ) |
| **Jaccard** | Binary | D = 1 - (\|A ∩ B\| / \|A ∪ B\|) |
| **Canberra** | Weighted by abundance | Emphasizes rare taxa |

#### 2. Phylogenetic Metrics

| Metric | Weighting | Sensitive To |
|:---|:---|:---|
| **Unweighted UniFrac** | Presence/absence | Phylogenetic novelty |
| **Weighted UniFrac** | Abundance | Phylogenetic turnover |
| **Generalized UniFrac** | Balanced | Tunable parameter α |

#### 3. Transformation-Based

| Metric | Method | Use Case |
|:---|:---|:---|
| **Aitchison** | CLR + Euclidean | Compositional data |
| **RPCA** | Robust PCA | Zero-inflated data |
| **DEICODE** | Matrix completion | Sparse datasets |

### Implementation

```bash
# Calculate beta diversity
qiime diversity beta \
  --i-table table.qza \
  --p-metric braycurtis \
  --o-distance-matrix braycurtis.qza

# Phylogenetic diversity (requires tree)
qiime diversity beta-phylogenetic \
  --i-table table.qza \
  --i-phylogeny tree.qza \
  --p-metric unweighted_unifrac \
  --o-distance-matrix unweighted-unifrac.qza
```

### Dimensionality Reduction

```bash
# PCoA
qiime diversity pcoa \
  --i-distance-matrix braycurtis.qza \
  --o-pcoa braycurtis-pcoa.qza

# Emperor visualization
qiime emperor plot \
  --i-pcoa braycurtis-pcoa.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization braycurtis-emperor.qzv
```

### Statistical Testing

#### PERMANOVA

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

#### PERMDISP

Tests homogeneity of multivariate dispersions:

```bash
qiime diversity beta-group-significance \
  --i-distance-matrix braycurtis.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --p-method permdisp \
  --o-visualization braycurtis-permdisp.qzv
```

---

## Visualization

### Alpha Diversity Plots

```python
import seaborn as sns
import matplotlib.pyplot as plt

# Box plot
data = pd.read_csv('alpha_diversity.tsv', sep='\t')
sns.boxplot(data=data, x='group', y='shannon')
plt.title('Shannon Diversity by Group')
plt.savefig('shannon_boxplot.pdf')

# Rarefaction curve
# (Use QIIME2 visualization: alpha-rarefaction.qzv)
```

### Beta Diversity Plots

```python
from skbio.stats.ordination import pcoa
from skbio import DistanceMatrix
import matplotlib.pyplot as plt

# Load distance matrix
dm = DistanceMatrix.read('braycurtis.tsv')

# PCoA
pcoa_results = pcoa(dm)

# Plot
fig, ax = plt.subplots(figsize=(8, 6))
for group in metadata['group'].unique():
    mask = metadata['group'] == group
    ax.scatter(pcoa_results.samples.loc[mask, 'PC1'],
               pcoa_results.samples.loc[mask, 'PC2'],
               label=group)
ax.set_xlabel(f'PC1 ({pcoa_results.proportion_explained[0]:.1%})')
ax.set_ylabel(f'PC2 ({pcoa_results.proportion_explained[1]:.1%})')
ax.legend()
plt.savefig('pcoa_plot.pdf')
```

---

## Interpretation Guidelines

### Alpha Diversity

#### Typical Values (Human Gut)

| Metric | Range | Notes |
|:---|:---:|:---|
| Observed features | 50-200 | Varies with sampling depth |
| Shannon | 2.5-4.5 | >4 indicates high diversity |
| Chao1 | 100-400 | Estimate of total richness |
| Pielou's J | 0.6-0.9 | >0.8 indicates even distribution |

#### Ecological Interpretation

| Scenario | Interpretation |
|:---|:---|
| Low richness, high evenness | Few dominant species, well-balanced |
| High richness, low evenness | Many rare species, few dominant |
| Low alpha in treatment | Potential dysbiosis or stress |
| High alpha in healthy | Diverse, resilient community |

### Beta Diversity

#### PCoA Interpretation

| Pattern | Interpretation |
|:---|:---|
| Tight clusters by group | Strong group effect |
| Overlapping clusters | Similar communities |
| Gradient pattern | Continuous environmental driver |
| Outliers | Unique community composition |

#### Distance Comparison

| Comparison | Typical Values | Context |
|:---|:---:|:---|
| Within-group distances | Lower | Similar communities |
| Between-group distances | Higher | Distinct communities |
| Technical replicates | Very low | Measurement precision |

---

## Advanced Topics

### Rarefaction and Sequencing Depth

```yaml
# Configuration for rarefaction
diversity_analysis:
  qiime2:
    sampling_depth: "auto"    # Auto-detect
    # Or specify manually
    # sampling_depth: 10000
```

**Choosing sampling depth**:
1. Examine rarefaction curves
2. Select depth where curves plateau
3. Include maximum samples possible
4. Exclude samples below minimum depth

### Longitudinal Analysis

```python
# Mixed effects model for longitudinal data
from statsmodels.regression.mixed_linear_model import MixedLM

# Model: alpha ~ time * treatment + (1|subject)
model = MixedLM.from_formula(
    'shannon ~ time_point * treatment',
    groups='subject_id',
    data=metadata
)
result = model.fit()
print(result.summary())
```

### Multivariate Analysis

```python
# Adonis2 (PERMANOVA with covariates)
from skbio.stats.distance import permanova

# Test group effect while controlling for age
results = permanova(
    distance_matrix=dm,
    grouping=metadata['group'],
    covariates=metadata[['age', 'bmi']],
    permutations=999
)
```

### Core Microbiome Analysis

```python
# Identify core features
from qiime2 import Artifact

# Load feature table
table = Artifact.load('table.qza')

# Define core (present in >50% of samples, >0.1% abundance)
core_features = table.view(pd.DataFrame)
core_features = core_features[
    (core_features > 0).sum(axis=1) / len(core_features.columns) > 0.5
]
core_features = core_features[core_features.sum(axis=1) > 0.001]
```

---

## See Also

- [Taxonomic Profiling](taxonomic-profiling.md) - Species classification
- [Functional Profiling](functional-profiling.md) - Functional analysis
- [Configuration Guide](configuration.md) - Parameter settings
- [QIIME2 Documentation](https://docs.qiime2.org/) - Detailed QIIME2 guides
