# Troubleshooting Guide

Comprehensive solutions for common MICOS-2024 issues.

---

## Table of Contents

- [Diagnostic Quick Reference](#diagnostic-quick-reference)
- [Installation Issues](#installation-issues)
- [Configuration Issues](#configuration-issues)
- [Runtime Errors](#runtime-errors)
- [Performance Issues](#performance-issues)
- [Data Quality Issues](#data-quality-issues)
- [Output Issues](#output-issues)
- [Error Code Reference](#error-code-reference)
- [Getting Help](#getting-help)

---

## Diagnostic Quick Reference

### Quick Diagnostic Commands

```bash
# System resources
free -h                              # Memory
df -h                                # Disk space
nproc                                # CPU cores
ulimit -a                            # Resource limits

# Environment
which python
python --version
conda list | grep -E "kraken2|humann|qiime"
collecho $PATH

# Installation check
./scripts/verify_installation.sh

# Database check
ls -la /path/to/kraken2_db/*.k2d
ls -la /path/to/kneaddata_db/*.bt2

# Log analysis
tail -f logs/analysis.log
grep -i "error\|fatal\|exception" logs/*.log
```

### Diagnostic Flowchart

```
Problem occurs
      ↓
Check logs (logs/error.log)
      ↓
┌─────────────┴─────────────┐
↓                           ↓
Installation Error      Runtime Error
↓                           ↓
Verify dependencies    Check input data
↓                           ↓
Reinstall if needed    Adjust parameters
```

---

## Installation Issues

### Issue: Conda Environment Creation Fails

**Symptoms**:
```
CondaEnvException: Pip failed
ResolvePackageNotFound
```

**Causes & Solutions**:

| Cause | Solution |
|:---|:---|
| Outdated conda | `conda update -n base conda` |
| Corrupted cache | `conda clean --all` |
| Channel conflicts | Use mamba: `mamba env create -f environment.yml` |
| Network issues | Configure mirrors or use offline packages |

**Step-by-Step Fix**:
```bash
# 1. Update conda
conda update -n base -c conda-forge conda

# 2. Clean cache
conda clean --all -y

# 3. Install mamba (faster solver)
conda install -n base -c conda-forge mamba

# 4. Create environment with mamba
mamba env create -f environment.yml

# 5. If still failing, try sequential installation
conda create -n micos-2024 python=3.9
conda activate micos-2024
mamba install kraken2 kneaddata humann
pip install -e .
```

### Issue: Docker Permission Denied

**Symptoms**:
```
permission denied while trying to connect to Docker daemon
```

**Solution**:
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker run hello-world

# If still failing, check socket permissions
ls -la /var/run/docker.sock
```

### Issue: Memory Error During Installation

**Symptoms**:
```
MemoryError: Unable to allocate array
OSError: Cannot allocate memory
```

**Solutions**:
```bash
# Increase swap space
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Or reduce parallelism
export CONDA_SOLVER_THREADS=2
mamba env create -f environment.yml
```

### Issue: Package Conflicts

**Symptoms**:
```
Found conflicts! Looking for incompatible packages.
```

**Solution**:
```bash
# Use fresh environment
conda env create -f environment.yml --force

# Or install in specific order
conda create -n micos-2024 python=3.9
conda activate micos-2024
conda install -c bioconda -c conda-forge kraken2
conda install -c bioconda -c conda-forge humann
conda install -c bioconda -c conda-forge kneaddata
pip install -e .
```

---

## Configuration Issues

### Issue: Database Path Not Found

**Symptoms**:
```
FileNotFoundError: [Errno 2] No such file or directory: '/path/to/kraken2_db'
kraken2: database does not contain necessary file hash.k2d
```

**Diagnosis**:
```bash
# Check database files
ls -la /path/to/kraken2_db/

# Verify required files exist
ls hash.k2d opts.k2d taxo.k2d  # For Kraken2
ls *.bt2  # For KneadData/Bowtie2
```

**Solution**:
```bash
# 1. Update configuration
nano config/databases.yaml

# 2. Verify paths
echo "kraken2: /correct/path/to/kraken2_db"

# 3. If database missing, download
# See Installation Guide for database download
```

### Issue: YAML Syntax Error

**Symptoms**:
```
yaml.scanner.ScannerError: mapping values are not allowed here
ParserError: while parsing a block mapping
```

**Common Causes**:

| Error | Example | Fix |
|:---|:---|:---|
| Missing space after colon | `key:value` | `key: value` |
| Tab indentation | `\tkey: value` | `  key: value` |
| Quoted special chars | `path: "C:\temp"` | `path: 'C:\temp'` |

**Validation**:
```bash
# Check YAML syntax
python -c "import yaml; yaml.safe_load(open('config/analysis.yaml'))"

# Or use yamllint
yamllint config/analysis.yaml
```

### Issue: Sample Metadata Format Error

**Symptoms**:
```
ValueError: Sample metadata file format error
Error: Column 'sample-id' not found
```

**Requirements Checklist**:
- [ ] Tab-delimited format (not comma)
- [ ] Header row present
- [ ] `sample-id` column exists
- [ ] `group` column exists for comparisons
- [ ] No spaces in column names (use underscores)
- [ ] Sample IDs match FASTQ filenames

**Fix**:
```bash
# Convert CSV to TSV
sed 's/,/\t/g' samples.csv > samples.tsv

# Verify format
head -3 samples.tsv | cat -A
# Should show tabs (^I) not commas

# Validate column names
head -1 samples.tsv | tr '\t' '\n' | nl
```

---

## Runtime Errors

### Issue: Kraken2 Classification Fails

**Symptoms**:
```
kraken2: unable to open database
Error reading in hash table
```

**Solutions**:

```bash
# 1. Check database integrity
ls -lh /path/to/kraken2_db/
# Should have: hash.k2d, opts.k2d, taxo.k2d

# 2. Check permissions
ls -la /path/to/kraken2_db/

# 3. Verify memory
free -h
# Database requires ~size of database in RAM

# 4. Re-download if corrupted
kraken2-build --download-taxonomy --db /new/path
```

### Issue: KneadData Bowtie2 Error

**Symptoms**:
```
Error: Bowtie2 failed
Error: could not open index file
```

**Solutions**:
```bash
# Check index files
ls /path/to/kneaddata_db/*.bt2
# Should have: .1.bt2, .2.bt2, .3.bt2, .4.bt2, .rev.1.bt2, .rev.2.bt2

# Re-download if needed
kneaddata_database --download human_genome bowtie2 /new/path

# Check disk space
df -h
```

### Issue: HUMAnN Running Very Slow

**Symptoms**:
- Analysis taking >10x expected time
- High CPU but minimal progress

**Solutions**:
```yaml
# Use faster settings in config
functional_annotation:
  humann:
    diamond_options: "--fast"
    threads: 8
    # Use UniRef50 instead of UniRef90
    protein_database: "/db/uniref50"
```

### Issue: QIIME2 Import Error

**Symptoms**:
```
ValueError: BIOM file appears to be empty
```

**Diagnosis**:
```bash
# Check BIOM file
biom summarize-table -i feature-table.biom

# If empty, regenerate
kraken-biom *.report --fmt hdf5 -o new-table.biom

# Check Kraken2 reports
head *.report
# Should have classification data
```

---

## Performance Issues

### Issue: Analysis Is Too Slow

**Optimization Strategies**:

| Strategy | Command/Config | Expected Speedup |
|:---|:---|:---:|
| Increase threads | `--threads 32` | 2-4x |
| Use SSD for temp | `temp_dir: /ssd/tmp` | 2-3x |
| Use MiniKraken (testing) | `--kraken2-db /db/minikraken` | 5-10x |
| Disable memory mapping | `memory_mapping: false` | 1.5x (less RAM) |

**Configuration**:
```yaml
resources:
  max_threads: 32
  max_memory: "64GB"

paths:
  temp_dir: "/fast_ssd/tmp"

taxonomic_profiling:
  kraken2:
    memory_mapping: true    # Faster but more RAM
```

### Issue: Running Out of Disk Space

**Solutions**:
```bash
# 1. Clean intermediate files
rm -rf results/*/intermediate/
rm -rf tmp/*

# 2. Compress outputs
gzip results/*/*.fastq

# 3. Enable auto-cleanup in config
quality_control:
  kneaddata:
    remove_intermediate: true

# 4. Use external storage
ln -s /external/storage/results results
```

### Issue: High Memory Usage

**Memory Reduction Strategies**:

```yaml
# Reduce parallel jobs
resources:
  max_threads: 8    # Instead of 16+
  max_memory: "16GB"

# Disable memory mapping for Kraken2
taxonomic_profiling:
  kraken2:
    memory_mapping: false

# Use smaller database
databases:
  kraken2: "/db/minikraken2_v2_8GB"
```

---

## Data Quality Issues

### Issue: Low Classification Rate

**Normal vs Abnormal**:

| Classification Rate | Assessment |
|:---:|:---|
| > 70% | Good |
| 50-70% | Normal for some environments |
| 30-50% | Check quality and database |
| < 30% | Problematic |

**Solutions**:
```yaml
# Lower confidence threshold
taxonomic_profiling:
  kraken2:
    confidence: 0.05

# Use broader database
databases:
  kraken2: "/db/kraken2_pluspf"  # Includes fungi/protozoa
```

### Issue: Sample Fails QC

**FastQC Warnings to Address**:

| Warning | Action |
|:---|:---|
| Low quality scores | Increase `min_quality` in config |
| Adapter contamination | Enable adapter trimming |
| High duplication | May be normal for amplicon data |
| GC bias | Check for contamination |

**Configuration**:
```yaml
quality_control:
  kneaddata:
    min_quality: 25      # Increase from 20
    min_length: 75       # Increase from 50
```

### Issue: Batch Effects Detected

**Symptoms**:
- Samples cluster by sequencing run, not biological group
- High beta diversity within expected similar samples

**Solutions**:
```bash
# 1. Check metadata for batch information
cut -f3 metadata.tsv | sort | uniq -c

# 2. Include batch in statistical model
# Use PERMANOVA with strata
qiime diversity beta-group-significance \
  --i-distance-matrix braycurtis.qza \
  --m-metadata-file metadata.tsv \
  --m-metadata-column group \
  --p-method permanova \
  --p-permutations 999 \
  --o-visualization results.qzv
```

---

## Output Issues

### Issue: Empty Reports

**Diagnostic**:
```bash
# Check if earlier steps produced output
ls -lh results/quality_control/
ls -lh results/taxonomic_profiling/

# Check logs
tail logs/analysis.log
```

### Issue: Krona Charts Not Displaying

**Solutions**:
```bash
# Check if data exists
head results/taxonomic_profiling/*.report

# Regenerate manually
ktImportTaxonomy \
  -o new_krona.html \
  results/taxonomic_profiling/*.report

# Check browser console for JavaScript errors
```

### Issue: Missing Sample in Results

**Checklist**:
```bash
# 1. Sample in metadata?
grep "Sample001" metadata.tsv

# 2. Input files exist?
ls data/raw_input/Sample001*.fastq.gz

# 3. Sample passed QC?
grep "Sample001" results/quality_control/kneaddata/*.log

# 4. Check for errors
grep -i "Sample001" logs/*.log | grep -i error
```

---

## Error Code Reference

| Exit Code | Meaning | Common Cause |
|:---:|:---|:---|
| 1 | General error | Check logs for details |
| 2 | Misuse of command | Wrong arguments |
| 126 | Command not executable | Permission denied |
| 127 | Command not found | PATH issue, not installed |
| 128 + N | Fatal signal N | Process killed |
| 130 | Ctrl+C | User interrupted |
| 137 | SIGKILL (9) | Out of memory |
| 139 | Segmentation fault | Invalid memory access |
| 143 | SIGTERM (15) | Terminated by system |

### OOM (Out of Memory) Detection

```bash
# Exit code 137 indicates OOM
dmesg | grep -i "killed process"
# Shows processes killed by OOM killer
```

---

## Getting Help

### Before Asking for Help

1. **Check documentation**:
   - [User Manual](user_manual.md)
   - [Configuration Guide](configuration.md)
   - This troubleshooting guide

2. **Gather information**:
   ```bash
   # System info
   uname -a
   cat /etc/os-release
   
   # Environment
   conda list
   pip list | grep micos
   
   # Recent logs
   tail -n 100 logs/analysis.log
   ```

3. **Try minimal reproduction**:
   ```bash
   # Run on test data
   python -m micos.cli full-run \
     --input-dir test_data \
     --results-dir test_results \
     --threads 4
   ```

### Reporting Issues

When reporting issues, include:

```markdown
**Environment**
- OS: [e.g., Ubuntu 20.04]
- Python: [e.g., 3.9.12]
- MICOS version: [e.g., 1.0.0]
- Installation method: [Docker/Conda/Source]

**Command**
```bash
# The exact command you ran
```

**Error message**
```
Full error message or relevant log excerpt
```

**What you've tried**
- Step 1: ...
- Step 2: ...
```

### Support Channels

| Channel | Best For | Response Time |
|:---|:---|:---:|
| [GitHub Issues](https://github.com/BGI-MICOS/MICOS-2024/issues) | Bug reports, feature requests | 1-3 days |
| [Discussions](https://github.com/BGI-MICOS/MICOS-2024/discussions) | Questions, best practices | 1-7 days |
| Documentation | Quick reference | Immediate |

---

<p align="center">
  <a href="faq.md">→ View Frequently Asked Questions</a>
</p>
