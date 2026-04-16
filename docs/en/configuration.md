# Configuration Guide

Complete reference for configuring MICOS-2024 analysis parameters.

---

## Table of Contents

- [Configuration Overview](#configuration-overview)
- [Configuration Files](#configuration-files)
- [Project Configuration](#project-configuration)
- [Resource Configuration](#resource-configuration)
- [Module-Specific Parameters](#module-specific-parameters)
- [Configuration Validation](#configuration-validation)
- [Best Practices](#best-practices)
- [Examples](#examples)

---

## Configuration Overview

MICOS-2024 uses a **multi-layer configuration system** based on YAML format. The system supports:

- **Modular configuration**: Each analysis module has independent settings
- **Variable substitution**: Use `${variable}` syntax for reusable values
- **Configuration inheritance**: Default → Project → Command-line overrides
- **Automatic validation**: Check configuration before analysis starts

### Configuration Hierarchy

```
1. Default values (built into code)
   ↓
2. Configuration files (config/analysis.yaml)
   ↓
3. Environment variables (MICOS_* variables)
   ↓
4. Command-line arguments (highest priority)
```

---

## Configuration Files

### File Structure

```
config/
├── analysis.yaml          # Main analysis parameters
├── databases.yaml         # Database paths
├── samples.tsv           # Sample metadata
└── config.conf           # Cromwell workflow settings
```

### Quick Setup

```bash
# Copy template files
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv

# Edit configurations
nano config/analysis.yaml
nano config/databases.yaml
nano config/samples.tsv
```

---

## Project Configuration

### Basic Project Information

```yaml
project:
  name: "Gut_Microbiome_Study_2024"
  description: "Analysis of human gut microbiome in treatment vs control"
  version: "1.0.0"
  author: "Research Team"
  email: "team@example.com"
```

### Path Configuration

```yaml
paths:
  input_dir: "data/raw_input"           # Raw data directory
  output_dir: "results"                  # Results directory
  temp_dir: "/tmp/micos"                 # Temporary files (use fast storage)
  log_dir: "logs"                        # Log files directory
  
  # Database paths (can also use databases.yaml)
  databases:
    kraken2: "/data/databases/kraken2/standard"
    kneaddata: "/data/databases/kneaddata/human_genome"
    humann: "/data/databases/humann"
```

### Path Variables

Use variable substitution for cleaner configuration:

```yaml
paths:
  base_dir: "/project/micos_analysis"
  input_dir: "${paths.base_dir}/data"
  output_dir: "${paths.base_dir}/results"
  temp_dir: "${paths.base_dir}/tmp"
```

---

## Resource Configuration

### Compute Resources

```yaml
resources:
  max_threads: 16              # Maximum parallel threads
  max_memory: "32GB"           # Maximum memory allocation
  max_time: "24h"              # Maximum runtime per task
  
  # Per-module thread allocation
  thread_allocation:
    quality_control: 8
    taxonomic_profiling: 16
    functional_annotation: 8
    diversity_analysis: 4
```

### Resource Guidelines

| Dataset Size | Threads | Memory | Temp Storage |
|:---|:---:|:---:|:---:|
| Small (< 10 samples) | 8 | 16 GB | 50 GB |
| Medium (10-50 samples) | 16 | 32 GB | 200 GB |
| Large (50-200 samples) | 32 | 64 GB | 1 TB |
| Very Large (> 200 samples) | 64+ | 128 GB | 2 TB+ |

### Storage Optimization

```yaml
resources:
  # Use SSD for temporary files
  temp_dir: "/ssd/tmp"
  
  # Enable compression
  compression:
    enabled: true
    level: 6              # gzip compression level (1-9)
  
  # Cleanup settings
  cleanup:
    remove_intermediate: true
    keep_logs: true
```

---

## Module-Specific Parameters

### Quality Control Module

```yaml
quality_control:
  enabled: true
  
  fastqc:
    enabled: true
    threads: 4
    memory: "2GB"
  
  kneaddata:
    enabled: true
    threads: 8
    
    # Quality filtering
    min_quality: 20           # Minimum base quality score
    min_length: 50            # Minimum read length after trimming
    
    # Trimmomatic options
    trimmomatic_options: "SLIDINGWINDOW:4:20 MINLEN:50"
    
    # Host removal
    reference_db: "${paths.databases.kneaddata}"
    
    # Additional options
    remove_intermediate: true
    bypass_trf: false         # Skip tandem repeat filtering
    threads: 8
```

### Taxonomic Profiling Module

```yaml
taxonomic_profiling:
  enabled: true
  
  kraken2:
    enabled: true
    threads: 16
    
    # Classification parameters
    confidence: 0.1           # Confidence threshold (0-1)
                            # Lower = more classified reads, potentially more false positives
                            # Higher = fewer classified reads, higher precision
    min_base_quality: 20      # Minimum base quality for classification
    min_hit_groups: 2         # Minimum number of hit groups
    
    # Memory options
    memory_mapping: true      # Use memory-mapped I/O (faster, more memory)
    
    # Output options
    use_names: true           # Include taxonomic names in output
    report_zeros: false       # Include taxa with zero counts
  
  kraken_biom:
    enabled: true
    format: "hdf5"            # hdf5 or json
    
  krona:
    enabled: true
    max_depth: 7              # Maximum taxonomic depth for visualization
```

#### Kraken2 Confidence Parameter Guide

| Confidence | Use Case | Expected Classification Rate |
|:---:|:---|:---:|
| 0.0 | Maximum sensitivity | 80-95% |
| 0.1 | Balanced (default) | 60-80% |
| 0.3 | Higher precision | 40-60% |
| 0.5 | Conservative | 20-40% |

### Diversity Analysis Module

```yaml
diversity_analysis:
  enabled: true
  
  qiime2:
    enabled: true
    
    # Feature table filtering
    feature_filtering:
      min_frequency: 10       # Minimum count per feature
      min_samples: 3          # Minimum samples feature must appear in
      
    # Rarefaction depth (auto-detect if not specified)
    # sampling_depth: 10000
    
    # Alpha diversity metrics
    alpha_metrics:
      - "shannon"            # Shannon diversity index
      - "chao1"              # Chao1 richness estimator
      - "simpson"            # Simpson index
      - "observed_features"   # Number of observed ASVs/OTUs
      - "pielou_e"           # Pielou's evenness
      
    # Beta diversity metrics
    beta_metrics:
      - "braycurtis"         # Bray-Curtis dissimilarity
      - "jaccard"            # Jaccard distance
      - "unweighted_unifrac" # Unweighted UniFrac
      - "weighted_unifrac"   # Weighted UniFrac
```

#### Choosing Sampling Depth

```yaml
# Method 1: Auto-detect (recommended for beginners)
diversity_analysis:
  qiime2:
    sampling_depth: "auto"

# Method 2: Manual based on data
# Use 10th percentile of read counts per sample
diversity_analysis:
  qiime2:
    sampling_depth: 10000

# Method 3: Based on negative controls
diversity_analysis:
  qiime2:
    sampling_depth: 1000    # Above negative control threshold
```

### Functional Annotation Module

```yaml
functional_annotation:
  enabled: true
  
  humann:
    enabled: true
    threads: 8
    
    # Database paths
    nucleotide_database: "${paths.databases.humann}/chocophlan"
    protein_database: "${paths.databases.humann}/uniref90"
    
    # Search options
    search_mode: "diamond"    # diamond or bowtie2
    
    # Annotation databases
    pathway_database: "metacyc"   # metacyc or reactome
    
    # Output normalization
    normalization: "cpm"      # cpm (copies per million) or relab
```

#### HUMAnN Database Selection

| Database | Size | Speed | Use Case |
|:---|:---:|:---:|:---|
| UniRef50 | ~5 GB | Fast | Quick screening |
| UniRef90 | ~20 GB | Moderate | Standard analysis |
| UniRef100 | ~50 GB | Slow | Maximum coverage |

### Differential Abundance Module

```yaml
differential_abundance:
  enabled: true
  
  methods:
    # DESeq2 for raw count data
    deseq2:
      enabled: true
      alpha: 0.05
      fold_change_threshold: 2.0
      min_count: 10
      
    # ALDEx2 for compositional data
    aldex2:
      enabled: true
      mc_samples: 128
      test: "t"                 # t-test or wilcox
      effect_size_threshold: 1.0
      
    # ANCOM-BC for bias correction
    ancom_bc:
      enabled: true
      alpha: 0.05
      p_adj_method: "BH"        # Benjamini-Hochberg
      zero_cut: 0.90
      lib_cut: 1000
  
  visualization:
    volcano_plot: true
    ma_plot: true
    heatmap: true
    top_features: 50
```

### Network Analysis Module

```yaml
network_analysis:
  enabled: true
  
  correlation:
    method: "spearman"        # spearman, pearson, or sparcc
    min_abundance: 0.001      # Minimum relative abundance
    min_prevalence: 0.1       # Minimum fraction of samples
    
  network_construction:
    correlation_threshold: 0.6
    pvalue_threshold: 0.05
    multiple_testing_correction: "BH"
    
  topology_analysis:
    centrality_metrics: true
    module_detection: true
    key_species_identification: true
```

---

## Configuration Validation

### Automatic Validation

MICOS-2024 validates configuration before running:

```bash
# Validate configuration
python -m micos.cli validate-config --config config/analysis.yaml

# Dry run to test configuration
python -m micos.cli full-run \
  --config config/analysis.yaml \
  --dry-run
```

### Validation Checks

| Check | Description | Failure Action |
|:---|:---|:---|
| YAML syntax | Valid YAML format | Error + exit |
| Required fields | All mandatory fields present | Error + exit |
| Path existence | Input/output directories exist | Warning/Error |
| Parameter ranges | Values within valid ranges | Warning |
| Database integrity | Database files are valid | Error + exit |
| Resource limits | Memory/threads within system limits | Warning |

### Manual Validation

```python
# Python validation
import yaml
from micos.config import validate_config

with open('config/analysis.yaml') as f:
    config = yaml.safe_load(f)
    
validation_result = validate_config(config)
if not validation_result.valid:
    print(validation_result.errors)
```

---

## Best Practices

### 1. Start with Templates

```bash
# Always start from templates
cp config/*.template config/
# Then customize
```

### 2. Use Relative Paths

```yaml
# Good - portable across systems
paths:
  input_dir: "data/raw"
  output_dir: "results"

# Less portable
paths:
  input_dir: "/home/user/specific/path/data"
```

### 3. Version Control Configuration

```bash
# Track configuration templates
git add config/*.template

# Don't track actual configs (may contain paths specific to your system)
echo "config/*.yaml" >> .gitignore
```

### 4. Document Customizations

```yaml
project:
  name: "Study_2024"
  
analysis:
  # Increased confidence due to high-quality data
  kraken2:
    confidence: 0.15
```

### 5. Test with Subset

```yaml
# test_config.yaml - analyze only first 3 samples
samples:
  subset: 3
```

---

## Examples

### Example 1: Quick Test Configuration

```yaml
project:
  name: "Quick_Test"

paths:
  input_dir: "test_data"
  output_dir: "test_results"

resources:
  max_threads: 4
  max_memory: "8GB"

taxonomic_profiling:
  kraken2:
    confidence: 0.1
    
# Use MiniKraken for speed
databases:
  kraken2: "/db/minikraken2_v2_8GB"
```

### Example 2: Production Pipeline

```yaml
project:
  name: "Clinical_Study_Phase2"
  version: "2.1.0"
  description: "Large-scale clinical metagenomics analysis"

paths:
  base_dir: "/projects/clinical_study"
  input_dir: "${paths.base_dir}/raw_data"
  output_dir: "${paths.base_dir}/results"
  temp_dir: "/ssd/tmp"

resources:
  max_threads: 32
  max_memory: "128GB"

quality_control:
  kneaddata:
    min_quality: 25
    min_length: 75
    threads: 16

taxonomic_profiling:
  kraken2:
    confidence: 0.1
    threads: 32
    memory_mapping: true

diversity_analysis:
  qiime2:
    sampling_depth: 50000
    alpha_metrics: ["shannon", "chao1", "observed_features"]
    beta_metrics: ["braycurtis", "weighted_unifrac"]

differential_abundance:
  methods:
    deseq2:
      enabled: true
      alpha: 0.01
      fold_change_threshold: 4.0
```

### Example 3: Environmental Metagenomics

```yaml
project:
  name: "Soil_Microbiome_Survey"

# Environmental samples - adjust parameters
taxonomic_profiling:
  kraken2:
    confidence: 0.05          # Lower confidence for diverse samples
    
functional_annotation:
  humann:
    # Use UniRef50 for faster processing of diverse samples
    protein_database: "/db/humann/uniref50"
```

---

## Configuration Reference

### Complete Parameter List

See the configuration templates for all available parameters:

- `config/analysis.yaml.template` - Analysis parameters
- `config/databases.yaml.template` - Database paths
- `config/samples.tsv.template` - Sample metadata

---

## Next Steps

- 📖 [User Manual](user_manual.md) - Learn to run analyses
- 🧬 [Taxonomic Profiling](taxonomic-profiling.md) - Species classification details
- 🧪 [Functional Profiling](functional-profiling.md) - Functional annotation details
