# MICOS-2024 领域词汇表

> 本文件定义项目的核心概念与领域语言，确保代码和文档使用一致的术语。
> 架构、分析流程、数据流向、配置层次、错误处理等见 [AGENTS.md](AGENTS.md)。

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
- **生成**: Kraken2 -> kraken-biom -> feature-table.biom
- **用途**: 多样性分析的输入

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
- **示例**: `run_command_live()` - 命令执行的统一入口，测试可通过 monkeypatch 替换
- **原则**: 一个 adapter = 假设的接缝；两个 adapter = 真正的接缝

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
