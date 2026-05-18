# 性能基准测试

本文档展示 MICOS-2024 在不同规模数据集上的性能表现，帮助用户规划资源需求。

## 测试环境

- **硬件**: AMD EPYC 7742 64-Core Processor
- **内存**: 256GB DDR4
- **存储**: NVMe SSD
- **操作系统**: Ubuntu 22.04 LTS
- **数据库**: Kraken2 Standard (16GB), KneadData human_genome

## 性能数据

<BenchmarkChart
  title="处理时间对比（小时）"
  :labels="['小型', '中型', '大型', '超大型']"
  :data="[
    { label: '处理时间', values: [2, 8, 15, 72], unit: '小时' }
  ]"
/>

<BenchmarkChart
  title="内存使用（GB）"
  :labels="['小型', '中型', '大型', '超大型']"
  :data="[
    { label: '峰值内存', values: [16, 32, 64, 128], unit: 'GB' }
  ]"
/>

## 详细基准数据

| 数据集规模 | 样本数量 | 处理时间 | 内存使用 | 线程数 | 存储需求 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 小型 | 10 | ~2 小时 | 16GB | 16 | 50GB |
| 中型 | 50 | ~8 小时 | 32GB | 32 | 200GB |
| 大型 | 100 | ~15 小时 | 64GB | 64 | 500GB |
| 超大型 | 500 | ~72 小时 | 128GB | 128 | 2TB |

## 各阶段性能分析

### 质量控制阶段

| 步骤 | 时间占比 | 内存峰值 | 可并行化 |
|------|---------|---------|---------|
| FastQC | 5% | 2GB | ✓ |
| KneadData | 35% | 16GB | ✓ |
| 质量报告 | 2% | 1GB | ✓ |

### 物种分类阶段

| 步骤 | 时间占比 | 内存峰值 | 可并行化 |
|------|---------|---------|---------|
| Kraken2 | 25% | 数据库大小 | ✓ |
| Krona | 3% | 4GB | ✓ |
| BIOM 转换 | 2% | 2GB | ✓ |

### 多样性分析阶段

| 步骤 | 时间占比 | 内存峰值 | 可并行化 |
|------|---------|---------|---------|
| QIIME2 | 20% | 8GB | 部分 |
| 排序分析 | 5% | 4GB | 部分 |
| 可视化 | 3% | 2GB | ✓ |

## 并行效率

<AlgorithmCard
  title="并行处理优化"
  description="MICOS-2024 使用 ProcessPoolExecutor 实现样本级并行处理，线性扩展至 64 核。"
  complexity="O(n/p)"
  language="python"
  codeSnippet="with ProcessPoolExecutor(max_workers=threads) as executor:
    futures = {
        executor.submit(process_sample, s, output_dir): s
        for s in samples
    }
    for future in as_completed(futures):
        result = future.result()
        logger.info(f'Completed: {result.sample_name}')"
/>

### 扩展性测试

| 线程数 | 加速比 | 效率 |
|:---:|:---:|:---:|
| 1 | 1.0x | 100% |
| 4 | 3.8x | 95% |
| 16 | 14.2x | 89% |
| 32 | 26.5x | 83% |
| 64 | 48.0x | 75% |

## 资源规划建议

### 最小配置

- **CPU**: 8 核
- **内存**: 32GB
- **存储**: 100GB SSD
- **适用**: 教学演示、小型数据集

### 推荐配置

- **CPU**: 32 核
- **内存**: 64GB
- **存储**: 500GB NVMe SSD
- **适用**: 研究项目、中型数据集

### 高性能配置

- **CPU**: 64+ 核
- **内存**: 128GB+
- **存储**: 2TB NVMe SSD
- **适用**: 生产环境、大型数据集

## 优化建议

1. **I/O 优化**: 使用 NVMe SSD 存储 FASTQ 文件
2. **内存优化**: Kraken2 数据库可加载到内存
3. **并行优化**: 样本数 > 核心数时效率最高
4. **存储优化**: 清理中间文件以节省空间
