# 宏基因组分析流程

## 概述


`metagenomic_analysis_workflow` 设计用于通过一系列生物信息学工具处理成对的宏基因组测序数据，包括 KneadData、Kraken2、Krona 和 QIIME2。该流程包括以下主要步骤：

1. **使用 KneadData 进行质量控制**：
    - 使用 KneadData 对输入的成对读段进行处理，以去除污染物并进行质量过滤。KneadData 尤其适用于人类微生物组研究，因为它可以去除宿主 DNA 序列。

2. **使用 Kraken2 进行分类学分类**：
    - 对经过质量控制的读段使用 Kraken2 进行分类。Kraken2 是一种高度精确且快速的工具，用于将宏基因组序列分配到分类学标签。Kraken2 输出详细报告和汇总的 TSV 文件。

3. **合并 Kraken2 输出**：
    - 合并 Kraken2 输出文件，生成包含所有样本的分类学分类结果的整合 TSV 文件。

4. **生成 BIOM 文件**：
    - 从 Kraken2 报告中生成一个兼容 QIIME2 的 BIOM 文件，以用于下游分析。

5. **Krona 可视化**：
    - 使用 Krona 创建每个样本分类组成的交互式 HTML 可视化文件。

6. **QIIME2 分析**：
    - 将 BIOM 文件和分类学数据导入 QIIME2 进行进一步分析。这包括特征表过滤、分类学导入和各种多样性分析。

7. **功能分析**
    - 基于过滤后的fq，使用humann3进行无组装功能分析，并得到genefamily与metacyc代谢通路的丰度和覆盖度，并将结果转换为相应的eggnog、go、ko、ec信息。

## 工作流程步骤

1. **使用 KneadData 进行数据预处理**
    - 输入：双端 FASTQ 文件
    - 输出：清洗后的 FASTQ 文件

2. **使用 Kraken2 进行分类学分类**
    - 输入：来自 KneadData 的清洗后 FASTQ 文件
    - 输出：Kraken2 报告和 TSV 文件

3. **BIOM 文件生成**
    - 输入：Kraken2 报告
    - 输出：BIOM 文件

4. **Krona 可视化**
    - 输入：Kraken2 报告
    - 输出：交互式 分类可视化HTML

5. **QIIME2 分析**
    - 导入特征表和分类学
    - 过滤低丰度和罕见特征
    - 稀疏化特征表
    - 计算 alpha 和 beta 多样性
    - 执行主坐标分析（PCoA）
    - 为成分数据分析添加伪计数

6. **humann3 分析** 
    - 输入过滤后的fq表格和分组信息
    - 执行gemefamily和代谢通路注释

## 输入要求

- 双端 FASTQ 文件
- KneadData 数据库文件
- Kraken2 数据库文件
- QIIME2 样本元数据文件

## 输出

该流程生成各种输出，包括：

- 来自 KneadData 的清洗后 FASTQ 文件
- Kraken2 分类报告
- BIOM 文件
- Krona 可视化 HTML 文件
- QIIME2 工件（.qza 文件），用于特征表、多样性指标和 PCoA 结果
- 各样本的genefamily.tsv结果表格
- 各样本的代谢通路tsv结果表格
- 各样本的eggnog、go、ko、ec信息

## 依赖项

此流程依赖于以下工具：

- KneadData (v0.12.0)
- Kraken2 (v2.1.3)
- Kraken-biom (v1.0.0)
- Krona (v2.8.1)
- QIIME2 (2024.5)
- humann3（3.9.1）
- metaphlan4（4.0.1）

## 自定义

该流程允许自定义各种参数，包括：

- KneadData 和 Kraken2 的线程数
- Kraken2 的置信度阈值
- Kraken2 的最小碱基质量和命中组
- QIIME2 中特征过滤的最小频率和样本存在

要自定义这些参数，请修改输入 JSON 文件中的相应值。