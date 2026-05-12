---
title: Troubleshooting
---

# Troubleshooting Guide

Comprehensive solutions for common MICOS-2024 issues.

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

# Installation check
./scripts/verify_installation.sh

# Database check
ls -la /path/to/kraken2_db/*.k2d
ls -la /path/to/kneaddata_db/*.bt2

# Log analysis
tail -f logs/analysis.log
grep -i "error\|fatal\|exception" logs/*.log
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
```

---

## Configuration Issues

### Issue: Database Path Not Found

**Symptoms**:
```
FileNotFoundError: [Errno 2] No such file or directory: '/path/to/kraken2_db'
```

**Diagnosis**:
```bash
# Check database files
ls -la /path/to/kraken2_db/

# Verify required files exist
ls hash.k2d opts.k2d taxo.k2d  # For Kraken2
ls *.bt2  # For KneadData/Bowtie2
```

### Issue: YAML Syntax Error

**Common Causes**:

| Error | Example | Fix |
|:---|:---|:---|
| Missing space after colon | `key:value` | `key: value` |
| Tab indentation | `\tkey: value` | `  key: value` |

**Validation**:
```bash
# Check YAML syntax
python -c "import yaml; yaml.safe_load(open('config/analysis.yaml'))"
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

# 2. Verify memory
free -h

# 3. Re-download if corrupted
kraken2-build --download-taxonomy --db /new/path
```

### Issue: HUMAnN Running Very Slow

**Symptoms**: Analysis taking >10x expected time

**Solutions**:
```yaml
functional_annotation:
  humann:
    diamond_options: "--fast"
    threads: 8
    protein_database: "/db/uniref50"
```

---

## Performance Issues

### Issue: Analysis Is Too Slow

| Strategy | Command/Config | Expected Speedup |
|:---|:---|:---:|
| Increase threads | `--threads 32` | 2-4x |
| Use SSD for temp | `temp_dir: /ssd/tmp` | 2-3x |
| Use MiniKraken (testing) | `--kraken2-db /db/minikraken` | 5-10x |

### Issue: Running Out of Disk Space

```bash
# 1. Clean intermediate files
rm -rf results/*/intermediate/

# 2. Compress outputs
gzip results/*/*.fastq

# 3. Enable auto-cleanup in config
quality_control:
  kneaddata:
    remove_intermediate: true
```

### Issue: High Memory Usage

```yaml
# Reduce parallel jobs
resources:
  max_threads: 8
  max_memory: "16GB"

# Disable memory mapping for Kraken2
taxonomic_profiling:
  kraken2:
    memory_mapping: false
```

---

## Data Quality Issues

### Issue: Low Classification Rate

| Classification Rate | Assessment |
|:---:|:---|
| > 70% | Good |
| 50-70% | Normal for some environments |
| 30-50% | Check quality and database |
| < 30% | Problematic |

**Solutions**:
```yaml
taxonomic_profiling:
  kraken2:
    confidence: 0.05
databases:
  kraken2: "/db/kraken2_pluspf"
```

---

## Error Code Reference

| Exit Code | Meaning | Common Cause |
|:---:|:---|:---|
| 1 | General error | Check logs for details |
| 2 | Misuse of command | Wrong arguments |
| 126 | Command not executable | Permission denied |
| 127 | Command not found | PATH issue, not installed |
| 137 | SIGKILL (9) | Out of memory |
| 139 | Segmentation fault | Invalid memory access |

---

## Getting Help

### Reporting Issues

When reporting issues, include:

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

### Support Channels

| Channel | Best For | Response Time |
|:---|:---|:---:|
| [GitHub Issues](https://github.com/BGI-MICOS/MICOS-2024/issues) | Bug reports, feature requests | 1-3 days |
| [Discussions](https://github.com/BGI-MICOS/MICOS-2024/discussions) | Questions, best practices | 1-7 days |
| Documentation | Quick reference | Immediate |

---

## See Also

- [FAQ](./faq.md) - Frequently asked questions
- [Getting Started](./guides/getting-started.md) - Installation guide
