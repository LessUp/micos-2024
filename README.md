# 宏基因组分析流程 (Metagenomic Analysis Workflow)

<!-- Optional: Add badges here (e.g., license, build status) -->
<!-- [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) -->

## 概述 (Overview)

`metagenomic_analysis_workflow` (建议将仓库重命名为此或类似的描述性名称) 设计用于通过一系列生物信息学工具处理成对的宏基因组测序数据。该流程包括以下主要步骤：

1.  **使用 KneadData 进行质量控制**: 去除污染物并进行质量过滤。
2.  **使用 Kraken2 进行分类学分类**: 将序列分配到分类学标签。
3.  **生成 BIOM 文件**: 用于下游分析 (如 QIIME2)。
4.  **Krona 可视化**: 创建交互式分类组成图。
5.  **QIIME2 分析**: 进行特征表过滤、多样性分析等。
6.  **(可选) 功能分析**: (例如使用 HUMAnN，根据 `origin-HUMAnN.wdl` 推断)
7.  **(可选) 其他分析**: (例如 Phyloseq, MEGAN，根据目录推断)

## 项目结构 (Project Structure)

```
.
├── .gitignore               # Git 忽略规则
├── README.md                # 项目入口和文档
├── LICENSE                  # 开源许可证
├── CONTRIBUTING.md          # 贡献指南
├── CODE_OF_CONDUCT.md       # 社区行为准则
├── config/                  # 配置文件
│   └── config.conf
├── data/                    # 数据 (通常不提交到 Git)
│   └── raw_input/           # 原始输入数据
├── docs/                    # 详细文档和图片
│   ├── taxonomic-profiling.md
│   ├── functional-profiling.md
│   └── images/
│       └── img.png
├── results/                 # 分析结果 (通常不提交到 Git)
├── scripts/                 # 通用或遗留脚本
│   └── legacy_scripts/
├── workflows/               # 工作流定义 (WDL)
│   ├── origin-HUMAnN.wdl
│   └── wdl_scripts/         # 其他 WDL 相关脚本
├── steps/                   # 各分析步骤的脚本/说明
│   ├── 01_quality_control/
│   ├── 02_read_cleaning/
│   ├── 03_taxonomic_profiling_kraken/
│   ├── 04_taxonomic_conversion_biom/
│   ├── 05_taxonomic_visualization_krona/
│   ├── 06_qiime2_analysis/
│   ├── 07_phyloseq_analysis/
│   ├── 08_megan_analysis/
│   ├── 09_qiime2_whole_analysis/
│   └── ...                  # 其他步骤
└── containers/              # 容器构建文件
    └── sif_build/
```

## 安装 (Installation)

描述安装项目所需的依赖项和步骤。

1.  **克隆仓库:**
    ```bash
    git clone <repository-url>
    cd <repository-name>
    ```
2.  **依赖软件:**
    列出需要的核心软件及其版本 (根据 `Description.md` 推断):
    *   KneadData (v0.12.0)
    *   Kraken2 (v2.1.3)
    *   Kraken-biom (v1.0.0)
    *   Krona (v2.8.1)
    *   QIIME2 (2024.5)
    *   HUMAnN (如果使用)
    *   Phyloseq (R 包)
    *   MEGAN
    *   WDL 运行环境 (如 Cromwell)
    *   Singularity/Apptainer (如果使用 sif 文件)
    *   ...(其他依赖)

    建议使用 Conda 或 Mamba 来管理环境。可以提供一个 `environment.yml` 文件。
    ```bash
    # conda env create -f environment.yml
    # conda activate <env_name>
    ```
3.  **容器 (Containers):**
    如果项目依赖 Singularity/Apptainer 镜像，说明如何构建或拉取它们。参考 `containers/` 目录。
    ```bash
    # cd containers/sif_build
    # singularity build <image_name>.sif <definition_file>
    ```
4.  **数据库 (Databases):**
    说明需要下载哪些数据库以及放置在何处。
    *   KneadData 数据库 (例如：人类参考基因组)
    *   Kraken2 数据库
    *   HUMAnN 数据库 (如果使用)

## 配置 (Configuration)

说明如何配置分析流程。

*   主要的配置文件位于 `config/config.conf`。根据需要修改其中的参数，例如：
    *   输入文件路径 (`data/raw_input/`)
    *   输出目录 (`results/`)
    *   数据库路径
    *   线程数
    *   Kraken2 置信度阈值等
*   QIIME2 分析可能需要一个样本元数据文件 (Metadata)。说明其格式和位置。

## 使用方法 (Usage)

描述如何运行分析流程。

1.  **准备输入数据:**
    将成对的 FASTQ 文件放入 `data/raw_input/` 目录。
    准备 QIIME2 元数据文件。

2.  **运行完整流程 (示例):**
    如果使用 WDL 工作流:
    ```bash
    # java -jar cromwell.jar run workflows/origin-HUMAnN.wdl --inputs config/config.conf
    ```
    或者，如果流程是通过一系列脚本组织的：
    ```bash
    # cd steps/01_quality_control && ./run_fastqc.sh ../../config/config.conf
    # cd ../02_read_cleaning && ./run_kneaddata.sh ../../config/config.conf
    # ... etc.
    ```
    请根据你的实际运行方式详细说明。

3.  **运行单个步骤:**
    说明如何独立运行 `steps/` 目录下的某个特定分析步骤。

## 输出 (Output)

描述流程生成的主要输出文件及其位置 (`results/`)。

*   清洗后的 FASTQ 文件
*   Kraken2 分类报告 (`*.kraken`, `*.report`)
*   BIOM 文件 (`*.biom`)
*   Krona 可视化 HTML 文件 (`*.krona.html`)
*   QIIME2 工件 (`*.qza`, `*.qzv`)
*   HUMAnN 功能谱文件 (如果运行)
*   ...(其他结果)

参考 `docs/` 目录下的文档获取更详细的分析说明。

## 如何贡献 (Contributing)

请参考 `CONTRIBUTING.md`。

## 行为准则 (Code of Conduct)

请参考 `CODE_OF_CONDUCT.md`。

## 许可证 (License)

本项目使用 MIT 许可证。详情请见 `LICENSE` 文件。