# Performance Benchmarks

This document presents MICOS-2024 performance across different dataset scales, helping users plan resource requirements.

## Test Environment

- **Hardware**: AMD EPYC 7742 64-Core Processor
- **Memory**: 256GB DDR4
- **Storage**: NVMe SSD
- **OS**: Ubuntu 22.04 LTS
- **Databases**: Kraken2 Standard (16GB), KneadData human_genome

## Performance Data

<BenchmarkChart
  title="Processing Time Comparison (hours)"
  :labels="['Small', 'Medium', 'Large', 'X-Large']"
  :data="[
    { label: 'Processing Time', values: [2, 8, 15, 72], unit: 'hours' }
  ]"
/>

<BenchmarkChart
  title="Memory Usage (GB)"
  :labels="['Small', 'Medium', 'Large', 'X-Large']"
  :data="[
    { label: 'Peak Memory', values: [16, 32, 64, 128], unit: 'GB' }
  ]"
/>

## Detailed Benchmark Data

| Dataset Scale | Samples | Processing Time | Memory Usage | Threads | Storage |
|:---:|:---:|:---:|:---:|:---:|:---:|
| Small | 10 | ~2 hours | 16GB | 16 | 50GB |
| Medium | 50 | ~8 hours | 32GB | 32 | 200GB |
| Large | 100 | ~15 hours | 64GB | 64 | 500GB |
| X-Large | 500 | ~72 hours | 128GB | 128 | 2TB |

## Stage-by-Stage Performance

### Quality Control Stage

| Step | Time % | Peak Memory | Parallelizable |
|------|--------|-------------|----------------|
| FastQC | 5% | 2GB | ✓ |
| KneadData | 35% | 16GB | ✓ |
| Quality Report | 2% | 1GB | ✓ |

### Taxonomic Classification Stage

| Step | Time % | Peak Memory | Parallelizable |
|------|--------|-------------|----------------|
| Kraken2 | 25% | DB size | ✓ |
| Krona | 3% | 4GB | ✓ |
| BIOM Conversion | 2% | 2GB | ✓ |

### Diversity Analysis Stage

| Step | Time % | Peak Memory | Parallelizable |
|------|--------|-------------|----------------|
| QIIME2 | 20% | 8GB | Partial |
| Ordination | 5% | 4GB | Partial |
| Visualization | 3% | 2GB | ✓ |

## Resource Planning Recommendations

### Minimum Configuration

- **CPU**: 8 cores
- **Memory**: 32GB
- **Storage**: 100GB SSD
- **Use Case**: Teaching demos, small datasets

### Recommended Configuration

- **CPU**: 32 cores
- **Memory**: 64GB
- **Storage**: 500GB NVMe SSD
- **Use Case**: Research projects, medium datasets

### High-Performance Configuration

- **CPU**: 64+ cores
- **Memory**: 128GB+
- **Storage**: 2TB NVMe SSD
- **Use Case**: Production, large datasets

## Optimization Tips

1. **I/O Optimization**: Use NVMe SSD for FASTQ storage
2. **Memory Optimization**: Load Kraken2 database into memory
3. **Parallel Optimization**: Best efficiency when samples > cores
4. **Storage Optimization**: Clean intermediate files to save space
