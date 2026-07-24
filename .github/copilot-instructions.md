# MICOS-2024 GitHub Copilot 指令

> 本文件为 GitHub Copilot 提供项目特定上下文。
> **完整项目架构、开发指南和代码模式库见 [AGENTS.md](../AGENTS.md)**，本文件仅补充 Copilot 代码生成相关要点，避免与 AGENTS.md 重复。

## 项目速览

- **MICOS-2024**: 端到端宏基因组综合分析平台 (BGI-MICOS)
- **语言**: Python 3.9+ (主) / R 4.3.0 (统计)
- **工作流**: WDL + Cromwell / 容器: Docker + Singularity / 文档: VitePress
- **核心链路**: 质量控制 (FastQC+KneadData) → 物种分类 (Kraken2+Krona) → 多样性 (QIIME2+Phyloseq) → 功能注释 (HUMAnN3) → 结果汇总 (HTML)

## 代码生成规范

### Python

- 格式化: Black 88 字符 + isort (profile=black)
- 类型注解: 必需 (Python 3.9+ `dict[str, str]` 而非 `Dict[str, str]`)
- 文档字符串: Google 风格
- 路径: `pathlib.Path` 而非字符串拼接
- 日志: `logging.getLogger(__name__)`
- 错误处理: 自定义异常，避免过度 try/catch

```python
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

def process_sample(
    sample_id: str,
    input_path: Path,
    output_dir: Path,
    threads: int = 4,
) -> dict[str, Path]:
    """处理单个样本.

    Args:
        sample_id: 样本标识符
        input_path: 输入 FASTQ 文件路径
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

### CLI (Click 框架)

```python
import click

@click.group()
def cli():
    """MICOS-2024 宏基因组分析平台."""

@cli.command()
@click.option('--input-dir', required=True, help='输入目录')
@click.option('--threads', default=16, help='线程数')
def full_run(input_dir: str, threads: int):
    """运行完整分析流程."""
    ...
```

## 配置系统要点

- **实际生效字段**: `paths.input_dir` / `paths.output_dir` / `paths.databases.{kraken2,kneaddata}` / `resources.max_threads`
- 其他 analysis.yaml 字段为愿景参数，CLI 当前不读取
- 样本发现通过 FASTQ 文件名 (`*_R1.fastq.gz`)，不读 samples.tsv
- 配置模型: `micos.config.AnalysisConfig` (Pydantic)

## 测试

- 框架: pytest，标记 `slow` / `integration` / `unit`
- 覆盖率目标: >80%
- 新功能/Bug 修复必须添加测试

```bash
pytest tests/ -v --cov=micos
pytest -m "not slow" tests/
```

## 提交规范 (Conventional Commits)

```
<type>(<scope>): <description>

feat(qc): add paired-end trimming support
fix(kraken): handle empty classification results
docs: update installation guide
```

## 安全

- 禁止硬编码密钥/密码/PII
- 敏感文件已在 .gitignore: `config/secrets.yaml`, `.secrets/`, `*.env`

## 相关文档

- [AGENTS.md](../AGENTS.md) - 完整项目架构、代码模式库、性能优化指南
- [CLAUDE.md](../CLAUDE.md) - Claude Code 配置
- [CONTRIBUTING.md](../CONTRIBUTING.md) - 贡献指南
