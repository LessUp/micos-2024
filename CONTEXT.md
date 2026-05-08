# MICOS-2024 领域词汇表

> 本文件定义项目的核心概念和领域语言，确保代码和文档使用一致的术语。

---

## 核心概念

### 样本 (Sample)

- **定义**: 一个测序样本，包含一个或两个 FASTQ 文件
- **命名规范**:
  - 原始数据: `*_R1.fastq.gz` 和 `*_R2.fastq.gz`
  - 清洗后: `*_paired_1.fastq` 和 `*_paired_2.fastq`
- **相关类**: `micos.sample.Sample`
- **示例**: 样本 `S001` 包含 `S001_R1.fastq.gz` 和 `S001_R2.fastq.gz`

### 清洗后的读长 (Clean Reads)

- **定义**: 经过质量控制和宿主过滤后的测序数据
- **位置**: `quality_control/kneaddata/{sample}_paired_{1,2}.fastq`
- **用途**: 后续分析（物种分类、功能注释）的输入
- **相关方法**: `Sample.discover_cleaned()`

### 特征表 (Feature Table)

- **定义**: 样本 × 物种/功能的计数矩阵
- **格式**: BIOM (Biological Observation Matrix)
- **生成**: Kraken2 → kraken-biom → feature-table.biom
- **用途**: 多样性分析的输入

---

## 分析阶段

### 1. 质量控制 (Quality Control)

- **工具**: FastQC + KneadData
- **输入**: 原始 FASTQ 文件
- **输出**: FastQC 报告、清洗后的读长
- **模块**: `micos.quality_control.run_qc()`

### 2. 物种分类 (Taxonomic Profiling)

- **工具**: Kraken2 + Kraken-BIOM + Krona
- **输入**: 清洗后的读长
- **输出**: 分类报告、BIOM 文件、Krona 图表
- **模块**: `micos.taxonomic_profiling.run_taxonomic_profiling()`

### 3. 多样性分析 (Diversity Analysis)

- **工具**: QIIME2
- **输入**: BIOM 特征表
- **输出**: Alpha/Beta 多样性指标
- **模块**: `micos.diversity_analysis.run_diversity_analysis()`

### 4. 功能注释 (Functional Annotation)

- **工具**: HUMAnN
- **输入**: 清洗后的读长
- **输出**: 功能通路丰度表
- **模块**: `micos.functional_annotation.run_functional_annotation()`

### 5. 结果汇总 (Result Summarization)

- **输出**: HTML 报告
- **模块**: `micos.summarize_results.run_summarize()`

---

## 数据流向

```
原始 FASTQ (input_dir)
    │
    ▼
┌─────────────────────────┐
│  质量控制 (QC)           │
│  FastQC + KneadData     │
└─────────────────────────┘
    │
    ▼
清洗后的读长 (clean reads)
    │
    ├──────────────────────────┐
    │                          │
    ▼                          ▼
┌───────────────────┐  ┌───────────────────┐
│ 物种分类          │  │ 功能注释          │
│ Kraken2 + Krona   │  │ HUMAnN            │
└───────────────────┘  └───────────────────┘
    │
    ▼
特征表 (BIOM)
    │
    ▼
┌───────────────────┐
│ 多样性分析        │
│ QIIME2            │
└───────────────────┘
    │
    ▼
HTML 报告
```

---

## 架构概念

### 深层模块 (Deep Module)

- **定义**: 接口简单但隐藏大量实现细节的模块
- **示例**: `Sample` 类 - 调用者只需知道样本名和路径，样本发现、验证等复杂性被隐藏
- **收益**:
  - **杠杆 (Leverage)**: 调用者获得大量功能
  - **局部性 (Locality)**: 变更集中于一处

### 浅层模块 (Shallow Module)

- **定义**: 接口几乎和实现一样复杂的模块
- **问题**: 没有提供真正的抽象价值
- **改进方向**: 深化接口，隐藏更多实现细节

### 接缝 (Seam)

- **定义**: 接口存在的地方，行为可以在此被修改
- **示例**: `ToolRunner` 接口 - 允许在生产 (`SubprocessToolRunner`) 和测试 (`MockToolRunner`) 之间切换
- **原则**: 一个 adapter = 假设的接缝；两个 adapter = 真正的接缝

---

## 配置层次

### 分析配置 (AnalysisConfig)

- **位置**: `micos.config.AnalysisConfig`
- **格式**: Pydantic 模型
- **字段**:
  - `paths.input_dir`: 输入目录
  - `paths.output_dir`: 输出目录
  - `resources.max_threads`: 最大线程数
- **兼容性**: 同时支持旧格式 (`INPUT_DIR`) 和新格式 (`paths.input_dir`)

### 数据库配置 (DatabasesConfig)

- **位置**: `config/databases.yaml`
- **字段**:
  - `quality_control.kneaddata.human_genome`: KneadData 人类基因组数据库
  - `taxonomy.kraken2.standard`: Kraken2 标准数据库

---

## 错误处理

### 自定义异常

项目使用 Python 标准异常，遵循 KISS 原则：

- `subprocess.CalledProcessError`: 工具执行失败
- `FileNotFoundError`: 文件或工具不存在
- `ValueError`: 参数验证失败

---

## 术语对照表

| 中文 | 英文 | 代码标识 |
|------|------|----------|
| 样本 | Sample | `Sample` |
| 读长 | Reads | `reads`, `fastq` |
| 清洗后读长 | Clean Reads | `clean_reads`, `paired` |
| 特征表 | Feature Table | `feature_table`, `biom` |
| 物种分类 | Taxonomic Profiling | `taxonomic_profiling` |
| 功能注释 | Functional Annotation | `functional_annotation` |
| 多样性 | Diversity | `diversity` |
| 质量控制 | Quality Control | `qc`, `quality_control` |
