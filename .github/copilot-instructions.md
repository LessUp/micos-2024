# MICOS-2024 GitHub Copilot 指令

> 本文件为 GitHub Copilot 提供项目上下文和编码规范指导

## 项目概述

MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite) 是一个端到端的宏基因组综合分析平台，由 BGI-MICOS 团队开发维护。

### 核心功能

- 质量控制 (FastQC, KneadData)
- 物种分类 (Kraken2, Krona)
- 多样性分析 (QIIME2, Phyloseq)
- 功能注释 (HUMAnN3)
- 结果汇总 (HTML 报告)

### 技术栈

- **语言**: Python 3.9+ (主要), R 4.3.0 (统计分析)
- **工作流**: WDL + Cromwell
- **容器**: Docker / Singularity
- **文档**: MkDocs Material

## 代码规范

### Python

```python
# 使用 Black 格式化 (88 字符)
# 使用 isort 排序导入
# 使用类型注解

from typing import Dict, List, Optional
import pandas as pd

def process_sample(
    sample_id: str,
    input_path: str,
    output_dir: str,
    threads: int = 4,
) -> Dict[str, str]:
    """处理单个样本.
    
    Args:
        sample_id: 样本标识符
        input_path: 输入文件路径
        output_dir: 输出目录
        threads: 线程数
        
    Returns:
        包含输出文件路径的字典
        
    Raises:
        FileNotFoundError: 输入文件不存在
    """
    ...
```

### 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 模块 | snake_case | `quality_control.py` |
| 类 | PascalCase | `FastQCRunner` |
| 函数 | snake_case | `run_quality_control` |
| 常量 | UPPER_SNAKE_CASE | `DEFAULT_THREADS` |
| 变量 | snake_case | `sample_count` |

### 文档字符串

使用 Google 风格的文档字符串：

```python
def calculate_alpha_diversity(
    table: pd.DataFrame,
    metric: str = "shannon",
) -> pd.Series:
    """计算 Alpha 多样性指数.
    
    支持的多样性指数包括:
    - shannon: Shannon 指数
    - simpson: Simpson 指数
    - observed: 观测特征数
    
    Args:
        table: 样本-特征丰度表 (样本为行)
        metric: 多样性指数类型
        
    Returns:
        每个样本的多样性指数值
        
    Raises:
        ValueError: 不支持的多样性指数类型
        
    Example:
        >>> table = pd.DataFrame({"taxa1": [10, 20], "taxa2": [5, 15]})
        >>> calculate_alpha_diversity(table, "shannon")
    """
    ...
```

## 项目结构

```
micos-2024/
├── micos/           # 核心 Python 包
│   ├── cli.py       # 命令行入口
│   ├── full_run.py  # 完整流程编排
│   └── *.py         # 功能模块
├── steps/           # WDL 分析步骤
├── scripts/         # 辅助脚本 (Python/R)
├── tests/           # 测试套件
├── config/          # 配置模板
└── docs/            # 文档源码
```

## 生物信息学领域知识

### 常见文件格式

| 格式 | 描述 | 扩展名 |
|------|------|--------|
| FASTQ | 测序数据 | .fastq, .fq, .fastq.gz |
| BIOM | 生物多样性矩阵 | .biom |
| QZA/QZV | QIIME2 数据 | .qza, .qzv |
| Kraken | 分类报告 | .kreport |

### 分析流程

1. **质量控制**: FastQC → KneadData (去除宿主、质量过滤)
2. **物种分类**: Kraken2 → Kraken-BIOM → Krona
3. **多样性分析**: QIIME2 (Alpha/Beta) → Phyloseq
4. **功能注释**: HUMAnN3 (MetaCyc 通路)

### 数据库

- Kraken2: 标准数据库 (~16GB) 或 MiniKraken (~8GB)
- HUMAnN: ChocoPhlAn + UniRef90
- QIIME2: SILVA 或 Greengenes

## 测试要求

### 单元测试

```python
# tests/test_module.py
import pytest
from micos.module import function

class TestFunction:
    def test_normal_case(self):
        """测试正常输入"""
        result = function(input_data)
        assert result == expected
        
    def test_edge_case(self):
        """测试边界情况"""
        with pytest.raises(ValueError):
            function(invalid_input)
```

### 运行测试

```bash
# 运行所有测试
pytest tests/ -v

# 运行带覆盖率
pytest tests/ --cov=micos --cov-report=html

# 运行单个测试文件
pytest tests/test_quality_control.py -v
```

## Git 提交规范

使用 Conventional Commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### 类型

| 类型 | 描述 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 文档更新 |
| style | 代码格式 (不影响功能) |
| refactor | 重构 |
| test | 测试相关 |
| chore | 构建/工具 |

### 示例

```
feat(qc): add support for paired-end read trimming

Add automatic detection and handling of paired-end FASTQ files
in the quality control module.

Closes #123
```

## 代码生成提示

### 生成 CLI 命令

```python
# 使用 Click 框架
import click

@click.group()
def cli():
    """MICOS-2024 宏基因组分析平台."""
    pass

@cli.command()
@click.option('--input-dir', required=True, help='输入目录')
@click.option('--output-dir', required=True, help='输出目录')
@click.option('--threads', default=4, help='线程数')
def full_run(input_dir: str, output_dir: str, threads: int):
    """运行完整分析流程."""
    ...
```

### 生成配置文件

```yaml
# config/analysis.yaml.template
project:
  name: "${PROJECT_NAME}"
  
paths:
  input_dir: "${INPUT_DIR}"
  output_dir: "${OUTPUT_DIR}"
  
resources:
  threads: ${THREADS:-4}
```

## 安全注意事项

1. **敏感信息**: 不要硬编码 API 密钥、数据库密码
2. **文件路径**: 使用 `pathlib.Path` 处理路径
3. **输入验证**: 验证所有用户输入
4. **资源清理**: 使用 context manager 管理资源

## 相关文档

- [AGENTS.md](../AGENTS.md) - 项目架构详解
- [openspec/](../openspec/) - 技术规范
- [docs/](../docs/) - 用户文档
