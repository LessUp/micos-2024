# 模块设计原理

本文档深入探讨 MICOS-2024 的软件架构设计，面向贡献者和架构评审者。

## 设计哲学

MICOS-2024 遵循 **深层模块 (Deep Modules)** 设计原则：

> "好的模块应该有简单的接口和强大的实现。" — John Ousterhout

### 接口与实现分离

每个模块提供：
- **简洁的公开接口**：少量参数，清晰的语义
- **隐藏的实现复杂性**：错误处理、并发、资源管理

## 核心模块架构

<ArchitectureDiagram />

### CLI 层 (`micos/cli.py`)

CLI 是用户的主要交互入口，负责：
- 参数解析和验证
- 配置加载
- 模块调度

```python
@click.group()
def cli():
    """MICOS-2024: Metagenomic Intelligence and Comprehensive Omics Suite."""
    pass

@cli.command()
@click.option('--input-dir', required=True, type=click.Path())
@click.option('--results-dir', required=True, type=click.Path())
@click.option('--threads', default=16)
def full_run(input_dir, results_dir, threads):
    """Run the complete analysis pipeline."""
    config = AnalysisConfig.from_paths(input_dir, results_dir)
    orchestrator = PipelineOrchestrator(config, threads)
    orchestrator.run()
```

### 核心处理层

每个处理模块遵循统一的模式：

<AlgorithmCard
  title="模块处理模式"
  description="统一的模块处理流程：验证输入 → 执行处理 → 验证输出 → 返回结果"
  language="python"
  codeSnippet="def process(input_path, output_dir, config, runner):
    validate_input(input_path)
    result = runner.execute(build_command(input_path, output_dir, config))
    output_files = validate_output(output_dir)
    return ModuleResult(success=True, output_files=output_files)"
/>

## 双执行器模式

MICOS-2024 实现了 **双执行器模式**，支持生产/测试环境切换：

### 抽象接口

```python
from abc import ABC, abstractmethod

class ToolRunner(ABC):
    @abstractmethod
    def run(
        self,
        command: list[str],
        output_dir: Path,
        check: bool = True,
        capture: bool = True,
    ) -> ToolResult:
        """执行外部工具命令。"""
        pass
```

### 生产执行器

```python
class SubprocessToolRunner(ToolRunner):
    """真实执行外部工具。"""

    def run(self, command, output_dir, check=True, capture=True):
        result = subprocess.run(
            command,
            cwd=output_dir,
            check=check,
            capture_output=capture,
            text=True,
        )
        return ToolResult(
            returncode=result.returncode,
            stdout=result.stdout,
            stderr=result.stderr,
        )
```

### 测试执行器

```python
class MockToolRunner(ToolRunner):
    """模拟执行，用于测试。"""

    def __init__(self, responses: dict[str, ToolResult]):
        self.responses = responses

    def run(self, command, output_dir, check=True, capture=True):
        key = ' '.join(command[:3])  # 使用命令前缀作为键
        return self.responses.get(key, ToolResult.success())
```

### 依赖注入

```python
# 生产环境
runner = SubprocessToolRunner()
result = process_fastq(input_path, output_dir, runner=runner)

# 测试环境
mock_runner = MockToolRunner({
    'kraken2 --db': ToolResult(stdout='mock_output'),
})
result = process_fastq(input_path, output_dir, runner=mock_runner)
```

## 配置系统

### Pydantic 模型

使用 Pydantic 实现类型安全的配置：

```python
from pydantic import BaseModel, Field, field_validator

class PathsConfig(BaseModel):
    input_dir: Path
    results_dir: Path

    @field_validator('input_dir')
    @classmethod
    def input_dir_exists(cls, v: Path) -> Path:
        if not v.exists():
            raise ValueError(f'Input directory does not exist: {v}')
        return v

class AnalysisConfig(BaseModel):
    paths: PathsConfig
    resources: ResourcesConfig
    databases: DatabasesConfig
```

### 兼容层

支持新旧配置格式：

```python
@classmethod
def from_yaml(cls, config_path: Path) -> 'AnalysisConfig':
    data = yaml.safe_load(config_path.read_text())

    # 新格式
    if 'paths' in data:
        return cls(**data)

    # 旧格式兼容
    return cls(
        paths=PathsConfig(
            input_dir=Path(data['INPUT_DIR']),
            results_dir=Path(data['RESULTS_DIR']),
        ),
        ...
    )
```

## 样本数据模型

### Sample 类

Sample 类封装样本数据，隐藏文件发现和验证的复杂性：

```python
class Sample:
    """样本数据模型。"""

    def __init__(self, name: str, directory: Path):
        self.name = name
        self.directory = directory
        self._files: list[Path] | None = None
        self._is_paired: bool | None = None

    @property
    def files(self) -> list[Path]:
        if self._files is None:
            self._files = self._discover_files()
        return self._files

    @property
    def is_paired(self) -> bool:
        if self._is_paired is None:
            self._is_paired = len(self.files) == 2
        return self._is_paired

    def validate(self) -> None:
        """验证样本文件完整性。"""
        for f in self.files:
            if not f.exists():
                raise SampleValidationError(f'Missing file: {f}')
```

## 并行处理

### 样本级并行

使用 `ProcessPoolExecutor` 实现样本级并行：

```python
from concurrent.futures import ProcessPoolExecutor, as_completed

def process_samples(
    samples: list[Sample],
    output_dir: Path,
    max_workers: int = 16,
) -> list[ModuleResult]:
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(process_single_sample, s, output_dir): s.name
            for s in samples
        }

        results = []
        for future in as_completed(futures):
            sample_name = futures[future]
            try:
                result = future.result()
                results.append(result)
                logger.info(f'Completed: {sample_name}')
            except Exception as e:
                logger.error(f'Failed: {sample_name}: {e}')

        return results
```

## 错误处理

### 自定义异常层次

```python
class MICosError(Exception):
    """MICOS 基础异常。"""
    pass

class ConfigurationError(MICosError):
    """配置错误。"""
    pass

class DatabaseError(MICosError):
    """数据库错误。"""
    pass

class SampleValidationError(MICosError):
    """样本验证错误。"""
    pass
```

### 返回码定义

| 返回码 | 含义 |
|:---:|------|
| 0 | 成功 |
| 1 | 一般错误 |
| 2 | 参数无效 |
| 3 | 配置错误 |
| 4 | 依赖缺失 |
| 5 | 数据库错误 |
| 6 | I/O 错误 |
| 130 | 被中断 (SIGINT) |

## 扩展点

### 添加新模块

1. 在 `micos/` 下创建新模块文件
2. 实现 `process()` 函数
3. 在 `cli.py` 中添加命令
4. 添加单元测试
5. 更新文档

### 添加新工具

1. 在 `tool_runner.py` 中添加命令构建函数
2. 在 `config.py` 中添加工具配置
3. 在 `tests/` 中添加测试用例
