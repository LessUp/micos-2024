# MICOS-2024 辅助脚本

本目录包含 MICOS-2024 的辅助分析脚本。这些脚本提供额外的分析功能，可作为独立工具使用。

---

## 脚本列表

### 数据库管理

| 脚本 | 功能 |
|------|------|
| `download_databases.sh` | 下载常用分析数据库（Kraken2, HUMAnN, KneadData） |

### 增强分析

| 脚本 | 功能 | CLI 集成状态 |
|------|------|-------------|
| `enhanced_qc.py` | 增强质量控制分析 | 独立工具 |
| `network_analysis.py` | 微生物共现网络分析 | 独立工具 |
| `phylogenetic_analysis.py` | 系统发育分析 | 独立工具 |
| `amplicon_analysis.py` | 16S rRNA 扩增子分析 | 独立工具 |
| `metatranscriptome_analysis.py` | 宏转录组分析 | 独立工具 |
| `functional_annotation.py` | 功能注释（增强版） | 独立工具 |
| `summarize_results.py` | 结果汇总（增强版） | 独立工具 |

### 工作流包装

| 脚本 | 功能 |
|------|------|
| `run_module.sh` | Shell 包装层，调用主 CLI |
| `run_full_analysis.sh` | 完整分析流程包装 |

---

## 使用方法

### 数据库下载

```bash
# 下载 MiniKraken2 数据库
./scripts/download_databases.sh kraken2-minikraken

# 下载所有数据库
./scripts/download_databases.sh all

# 指定数据库目录
MICOS_DB_ROOT=/data/dbs ./scripts/download_databases.sh kraken2-standard
```

### 增强质量控制

```bash
python scripts/enhanced_qc.py input/*.fastq.gz -o results/enhanced_qc/
```

### 网络分析

```bash
python scripts/network_analysis.py \
    -c config/analysis.yaml \
    -i results/taxonomic_profiling/abundance.tsv \
    -o results/network_analysis/
```

### 系统发育分析

```bash
python scripts/phylogenetic_analysis.py \
    -i results/taxonomic_profiling/ \
    -o results/phylogenetic/
```

---

## 与主 CLI 的关系

- **主 CLI (`micos`)**: 提供核心分析流程，推荐日常使用
- **辅助脚本**: 提供额外的专业分析功能，适合高级用户

推荐使用主 CLI 进行标准分析：

```bash
# 推荐方式
micos full-run --input-dir data/ --results-dir results/

# 仅在需要额外功能时使用辅助脚本
python scripts/network_analysis.py ...
```

---

## 注意事项

1. 这些脚本需要额外的依赖包，请参考各脚本的文档字符串
2. 部分脚本可能需要较长的运行时间
3. 建议在独立环境中运行，避免依赖冲突
