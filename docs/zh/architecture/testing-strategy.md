# 测试策略

本文档描述 MICOS-2024 的测试方法论和覆盖率目标。

## 测试哲学

MICOS-2024 追求 **>80% 的测试覆盖率**，采用测试金字塔策略：

```
            /\
           /  \    E2E Tests (少量)
          /____\   - 完整流程验证
         /      \
        /        \ Integration Tests (中等)
       /__________\ - 模块间交互
      /            \
     /              \ Unit Tests (大量)
    /________________\ - 函数级别验证
```

## 测试层次

### 单元测试

测试单个函数和类的行为：

```python
# tests/test_sample.py
import pytest
from micos.sample import Sample

def test_sample_discover_paired():
    """测试配对样本发现。"""
    sample = Sample('test_sample', Path('tests/fixtures/paired'))
    assert sample.is_paired is True
    assert len(sample.files) == 2

def test_sample_validate_missing_file():
    """测试缺失文件验证。"""
    sample = Sample('missing', Path('tests/fixtures/empty'))
    with pytest.raises(SampleValidationError):
        sample.validate()
```

### 集成测试

测试模块间的交互：

```python
# tests/test_integration.py
@pytest.fixture
def mock_runner():
    return MockToolRunner({
        'kraken2 --db': ToolResult(stdout='classified:100'),
    })

def test_taxonomic_profiling_pipeline(mock_runner, tmp_path):
    """测试物种分类完整流程。"""
    result = run_taxonomic_profiling(
        input_dir=Path('tests/fixtures/cleaned'),
        output_dir=tmp_path,
        runner=mock_runner,
    )
    assert result.success is True
    assert (tmp_path / 'kraken_report.txt').exists()
```

### 端到端测试

测试完整的分析流程：

```python
# tests/test_e2e.py
@pytest.mark.slow
@pytest.mark.integration
def test_full_run_small_dataset(tmp_path):
    """测试小型数据集的完整流程。"""
    result = subprocess.run(
        ['micos', 'full-run',
         '--input-dir', 'tests/fixtures/small',
         '--results-dir', str(tmp_path),
         '--threads', '4'],
        capture_output=True,
    )
    assert result.returncode == 0
    assert (tmp_path / 'results_summary.html').exists()
```

## Mock 策略

### ToolRunner Mock

使用 `MockToolRunner` 隔离外部依赖：

```python
class MockToolRunner(ToolRunner):
    """用于测试的模拟执行器。"""

    def __init__(self, responses: dict[str, ToolResult] | None = None):
        self.responses = responses or {}
        self.calls: list[list[str]] = []

    def run(self, command, output_dir, check=True, capture=True):
        self.calls.append(command)

        # 创建预期的输出文件
        for pattern, result in self.responses.items():
            if ' '.join(command[:3]).startswith(pattern):
                if result.output_files:
                    for f in result.output_files:
                        (output_dir / f).touch()
                return result

        return ToolResult.success()
```

### 文件系统 Mock

使用 `tmp_path` fixture 创建临时文件：

```python
def test_with_temp_files(tmp_path):
    input_file = tmp_path / 'sample_R1.fastq'
    input_file.write_text('@read1\nACGT\n+\nIIII\n')

    result = process_fastq(input_file, tmp_path)
    assert result.success
```

## 测试标记

使用 pytest 标记分类测试：

```python
# pytest.ini
[pytest]
markers =
    unit: Unit tests (fast)
    integration: Integration tests (medium)
    slow: Slow tests (skip by default)
```

运行特定类型的测试：

```bash
# 运行单元测试
pytest -m unit

# 跳过慢测试
pytest -m "not slow"

# 运行所有测试
pytest
```

## 覆盖率报告

### 配置

```toml
# pyproject.toml
[tool.pytest.ini_options]
addopts = "--cov=micos --cov-report=term-missing --cov-fail-under=80"

[tool.coverage.run]
source = ["micos"]
omit = ["micos/_version.py", "micos/__main__.py"]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise NotImplementedError",
    "if TYPE_CHECKING:",
]
```

### 生成报告

```bash
# 终端报告
pytest --cov=micos --cov-report=term-missing

# HTML 报告
pytest --cov=micos --cov-report=html
open htmlcov/index.html
```

## CI/CD 集成

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -e ".[dev]"

      - name: Run tests
        run: pytest --cov=micos --cov-fail-under=80

      - name: Upload coverage
        uses: codecov/codecov-action@v4
```

## 测试最佳实践

1. **每个 Bug 一个测试**：修复 bug 前先写失败的测试
2. **测试行为而非实现**：关注输出，而非内部状态
3. **使用描述性名称**：`test_validate_rejects_negative_values`
4. **保持测试独立**：不依赖其他测试的执行顺序
5. **快速失败**：使用断言而非条件判断

## 测试数据管理

```
tests/
├── fixtures/
│   ├── small/          # 小型测试数据集
│   ├── paired/         # 配对样本
│   └── cleaned/        # 预处理后的样本
├── conftest.py         # pytest 配置和 fixtures
└── test_*.py           # 测试文件
```
