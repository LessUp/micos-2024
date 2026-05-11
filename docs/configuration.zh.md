# 配置指南

MICOS-2024 分析参数的完整参考。

---

## 目录

- [配置概述](#配置概述)
- [配置文件](#配置文件)
- [项目配置](#项目配置)
- [资源配置](#资源配置)
- [模块特定参数](#模块特定参数)
- [配置验证](#配置验证)
- [最佳实践](#最佳实践)

---

## 配置概述

MICOS-2024 使用基于 YAML 格式的**多层配置系统**。该系统支持：

- **模块化配置**：每个分析模块有独立设置
- **变量替代**：使用 `${variable}` 语法实现可重用值
- **配置继承**：默认值 → 项目 → 命令行覆盖
- **自动验证**：分析开始前检查配置有效性

### 配置层次

```
1. 默认值（代码内置）
   ↓
2. 配置文件（config/analysis.yaml）
   ↓
3. 环境变量（MICOS_* 变量）
   ↓
4. 命令行参数（最高优先级）
```

---

## 配置文件

### 文件结构

```
config/
├── analysis.yaml          # 主要分析参数
├── databases.yaml         # 数据库路径
├── samples.tsv           # 样本元数据
└── config.conf           # Cromwell 工作流设置
```

### 快速设置

```bash
# 复制模板文件
cp config/analysis.yaml.template config/analysis.yaml
cp config/databases.yaml.template config/databases.yaml
cp config/samples.tsv.template config/samples.tsv

# 编辑配置
nano config/analysis.yaml
nano config/databases.yaml
nano config/samples.tsv
```

---

## 项目配置

### 基本项目信息

```yaml
project:
  name: "肠道微生物组研究_2024"
  description: "治疗与对照的人肠道微生物组分析"
  version: "1.0.0"
  author: "研究团队"
  email: "team@example.com"
```

### 路径配置

```yaml
paths:
  input_dir: "data/raw_input"           # 原始数据目录
  output_dir: "results"                  # 结果目录
  temp_dir: "/tmp/micos"                 # 临时文件（使用快速存储）
  log_dir: "logs"                        # 日志文件目录
  
  # 数据库路径（也可使用 databases.yaml）
  databases:
    kraken2: "/data/databases/kraken2/standard"
    kneaddata: "/data/databases/kneaddata/human_genome"
    humann: "/data/databases/humann"
```

---

## 资源配置

### 计算资源

```yaml
resources:
  max_threads: 16              # 最大并行线程数
  max_memory: "32GB"           # 最大内存分配
  max_time: "24h"              # 每个任务的最大运行时间
  
  # 每个模块的线程分配
  thread_allocation:
    quality_control: 8
    taxonomic_profiling: 16
    functional_annotation: 8
    diversity_analysis: 4
```

### 资源指南

| 数据集规模 | 线程 | 内存 | 临时存储 |
|:---|:---:|:---:|:---:|
| 小型（< 10 个样本） | 8 | 16 GB | 50 GB |
| 中型（10-50 个样本） | 16 | 32 GB | 200 GB |
| 大型（50-200 个样本） | 32 | 64 GB | 1 TB |
| 超大型（> 200 个样本） | 64+ | 128 GB | 2 TB+ |

### 存储优化

```yaml
resources:
  # 对临时文件使用 SSD
  temp_dir: "/ssd/tmp"
  
  # 启用压缩
  compression:
    enabled: true
    level: 6              # gzip 压缩级别 (1-9)
  
  # 清理设置
  cleanup:
    remove_intermediate: true
    keep_logs: true
```

---

## 模块特定参数

### 质量控制模块

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
    
    # 质量过滤
    min_quality: 20           # 最小碱基质量分数
    min_length: 50            # 修剪后最小读长
    
    # Trimmomatic 选项
    trimmomatic_options: "SLIDINGWINDOW:4:20 MINLEN:50"
    
    # 宿主去除
    reference_db: "${paths.databases.kneaddata}"
    
    # 其他选项
    remove_intermediate: true
    bypass_trf: false         # 跳过串联重复过滤
    threads: 8
```

### 物种分类模块

```yaml
taxonomic_profiling:
  enabled: true
  
  kraken2:
    enabled: true
    threads: 16
    
    # 分类参数
    confidence: 0.1           # 置信度阈值 (0-1)
                            # 更低 = 更多分类读数，潜在更多假阳性
                            # 更高 = 更少分类读数，更高精度
    min_base_quality: 20      # 分类的最小碱基质量
    min_hit_groups: 2         # 最小命中组数
    
    # 内存选项
    memory_mapping: true      # 使用内存映射 I/O（更快，更多内存）
    
    # 输出选项
    use_names: true           # 输出中包含分类名称
    report_zeros: false       # 包括计数为零的分类群
  
  kraken_biom:
    enabled: true
    format: "hdf5"            # hdf5 或 json
    
  krona:
    enabled: true
    max_depth: 7              # 可视化的最大分类深度
```

#### Kraken2 置信度参数指南

| 置信度 | 敏感性 | 精确度 | 使用场景 |
|:---:|:---:|:---:|:---|
| 0.0 | 极高 | 较低 | 探索性分析 |
| 0.1 | 高 | 良好 | **默认，平衡** |
| 0.3 | 中等 | 高 | 保守分析 |
| 0.5 | 低 | 极高 | 仅高置信度 |

### 多样性分析模块

```yaml
diversity_analysis:
  enabled: true
  
  qiime2:
    enabled: true
    
    # 特征表过滤
    feature_filtering:
      min_frequency: 10       # 每个特征的最小计数
      min_samples: 3          # 特征必须出现的最小样本数
      
    # 稀疏化深度（如果未指定则自动检测）
    # sampling_depth: 10000
    
    # Alpha 多样性指标
    alpha_metrics:
      - "shannon"            # Shannon 多样性指数
      - "chao1"              # Chao1 丰富度估计
      - "simpson"            # Simpson 指数
      - "observed_features"   # 观测到的 ASV/OTU 数量
      - "pielou_e"           # Pielou 均匀度
      
    # Beta 多样性指标
    beta_metrics:
      - "braycurtis"         # Bray-Curtis 差异性
      - "jaccard"            # Jaccard 距离
      - "unweighted_unifrac" # 非加权 UniFrac
      - "weighted_unifrac"   # 加权 UniFrac
```

### 功能注释模块

```yaml
functional_annotation:
  enabled: true
  
  humann:
    enabled: true
    threads: 8
    
    # 数据库路径
    nucleotide_database: "${paths.databases}/humann/chocophlan"
    protein_database: "${paths.databases}/humann/uniref90"
    
    # 搜索选项
    search_mode: "diamond"    # diamond 或 bowtie2
    
    # 敏感性与速度权衡
    diamond_options: "--mid-sensitive"
    
    # 通路选项
    pathway_coverage: true
    gap_fill: true            # 填充通路缺口
    minpath: true             # 使用 MinPath 进行通路选择
    
    # 输出选项
    remove_temp: true
```

---

## 配置验证

### 自动验证

MICOS-2024 在运行前验证配置：

```bash
# 验证配置
python -m micos.cli validate-config --config config/analysis.yaml

# 干运行测试配置
python -m micos.cli full-run \
  --config config/analysis.yaml \
  --dry-run
```

### 验证检查

| 检查 | 描述 | 失败操作 |
|:---|:---|:---|
| YAML 语法 | 有效的 YAML 格式 | 错误 + 退出 |
| 必需字段 | 所有必填字段存在 | 错误 + 退出 |
| 路径存在 | 输入/输出目录存在 | 警告/错误 |
| 参数范围 | 值在有效范围内 | 警告 |
| 数据库完整性 | 数据库文件有效 | 错误 + 退出 |
| 资源限制 | 内存/线程在系统限制内 | 警告 |

---

## 最佳实践

### 1. 从模板开始

```bash
# 始终从模板开始
cp config/*.template config/
# 然后自定义
```

### 2. 使用相对路径

```yaml
# 好的 - 跨系统可移植
paths:
  input_dir: "data/raw"
  output_dir: "results"

# 可移植性较差
paths:
  input_dir: "/home/user/specific/path/data"
```

### 3. 版本控制配置

```bash
# 跟踪配置模板
git add config/*.template

# 不要跟踪实际配置（可能包含系统特定路径）
echo "config/*.yaml" >> .gitignore
```

### 4. 记录自定义

```yaml
project:
  name: "Study_2024"
  
analysis:
  # 由于高质量数据，提高置信度
  kraken2:
    confidence: 0.15
```

### 5. 用子集测试

```yaml
# test_config.yaml - 仅分析前 3 个样本
samples:
  subset: 3
```

---

## 下一步

- 📖 [用户手册](user_manual.md) - 学习运行分析
- 🧬 [物种分类](taxonomic-profiling.md) - 物种分类详情
- 🧪 [功能注释](functional-profiling.md) - 功能注释详情
