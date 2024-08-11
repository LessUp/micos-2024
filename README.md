# 宏基因组分析流程

## 概述

本仓库包含一个使用工作流程描述语言（WDL）编写的宏基因组分析流程脚本。该流程集成了多个关键的生物信息学工具，用于处理、分析和可视化宏基因组测序数据。


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


## 流程组件

该流程包括以下几个关键步骤：

1. **KneadData**: 原始测序数据的预处理
2. **Kraken2**: 分类学分类
3. **Kraken-biom**: 生成 BIOM 文件
4. **Krona**: 分类学分类的交互式可视化
5. **QIIME2**: 进一步分析，包括多样性指标和特征表操作

### KneadData

KneadData 是一个设计用于宏基因组测序数据质量控制的工具。它执行以下操作：

- 修剪低质量序列
- 去除人类污染（如果提供了人类基因组数据库）
- 去除技术序列（如接头）

### Kraken2

Kraken2 是一个使用精确 k-mer 匹配的分类学分类系统，可以实现高准确度和快速分类。该工具为宏基因组 DNA 序列分配分类学标签。

### Kraken-biom

Kraken-biom 是一个从 Kraken 输出文件创建 BIOM 格式表格的工具。BIOM（生物观察矩阵）格式在微生物组分析流程中被广泛使用。

### Krona

Krona 是一个可视化工具，允许直观地探索宏基因组分类复杂层次结构中的相对丰度和置信度。

### QIIME2

QIIME2（微生物生态学定量洞察 2）是一个下一代微生物组生物信息学平台，具有可扩展性，免费，开源，并由社区开发。在这个流程中，QIIME2 用于：

- 导入和过滤特征表
- 计算 alpha 和 beta 多样性指标
- 执行主坐标分析（PCoA）

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
    - 输出：交互式 HTML 可视化

5. **QIIME2 分析**
    - 导入特征表和分类学
    - 过滤低丰度和罕见特征
    - 稀疏化特征表
    - 计算 alpha 和 beta 多样性
    - 执行主坐标分析（PCoA）
    - 为成分数据分析添加伪计数

## 使用方法

要运行此流程，您需要安装 Cromwell 或其他兼容 WDL 的工作流引擎。您还需要安装 Docker，因为流程为每个工具使用 Docker 容器。

1. 克隆此仓库：

   ```
   git clone https://github.com/your-username/metagenomic-analysis-pipeline.git
   cd metagenomic-analysis-pipeline
   ```

2. 准备您的输入文件并在 JSON 文件中更新工作流输入（例如，`inputs.json`）。

3. 运行工作流：

   ```
   cromwell run meta-dev.wdl -i inputs.json
   ```

## 输入要求

- 双端 FASTQ 文件
- KneadData 数据库文件
- Kraken2 数据库文件
- QIIME2 样本元数据文件
- 分类学转换脚本

## 输出

该流程生成各种输出，包括：

- 来自 KneadData 的清洗后 FASTQ 文件
- Kraken2 分类报告
- BIOM 文件
- Krona 可视化 HTML 文件
- QIIME2 工件（.qza 文件），用于特征表、多样性指标和 PCoA 结果

## 依赖项

此流程依赖于以下工具：

- KneadData (v0.12.0)
- Kraken2 (v2.1.3)
- Kraken-biom (v1.0.0)
- Krona (v2.8.1)
- QIIME2 (2024.5)

所有工具都使用 Docker 容器化，确保了在不同系统上的可重复性和易用性。

## 自定义

该流程允许自定义各种参数，包括：

- KneadData 和 Kraken2 的线程数
- Kraken2 的置信度阈值
- Kraken2 的最小碱基质量和命中组
- QIIME2 中特征过滤的最小频率和样本存在
- 稀疏化的采样深度（目前在工作流中被注释掉）

要自定义这些参数，请修改输入 JSON 文件中的相应值。

## 贡献

欢迎对改进流程的贡献。如果您有建议或遇到任何问题，请随时提交拉取请求或开启一个问题。

---

本 README 提供了宏基因组分析流程的概述。有关每个工具的更详细信息，请参阅它们各自的文档。