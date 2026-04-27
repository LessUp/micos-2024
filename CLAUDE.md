# CLAUDE.md - Claude Code 项目配置

> 本文件为 Claude Code 提供项目级配置和行为指南

## 项目识别

**项目**: MICOS-2024 (Metagenomic Intelligence and Comprehensive Omics Suite)
**类型**: 生物信息学分析平台
**语言**: Python 3.9+ / R 4.3.0
**仓库**: https://github.com/BGI-MICOS/MICOS-2024

---

## Claude Code 行为配置

### 上下文管理

- **优先阅读**: `AGENTS.md` 获取完整项目上下文
- **技术规范**: `openspec/specs/` 目录
- **架构决策**: `openspec/adr/` 目录

### 代码生成偏好

1. **类型注解**: 所有函数必须有类型注解
2. **文档字符串**: 使用 Google 风格
3. **错误处理**: 使用自定义异常类
4. **日志记录**: 使用 `logging` 模块

### 工具使用策略

| 任务类型 | 首选工具 | 说明 |
|----------|----------|------|
| 文件搜索 | Glob | 比 find 更高效 |
| 内容搜索 | Grep | 比 grep 命令更好用 |
| 代码编辑 | Edit | 增量修改，保留历史 |
| 新文件 | Write | 完整文件创建 |
| Shell 命令 | Bash | 系统操作 |

---

## 项目特定规则

### 生物信息学数据处理

1. **大文件处理**: FASTQ 文件可能很大，避免全部读入内存
2. **路径处理**: 使用 `pathlib.Path` 而非字符串拼接
3. **并发处理**: 使用 `concurrent.futures` 进行样本级并行
4. **资源限制**: 注意内存和线程配置

### 代码规范

```python
# ✅ 正确示例
from pathlib import Path
from typing import Dict, List, Optional
import logging

logger = logging.getLogger(__name__)

def process_fastq(
    input_path: Path,
    output_dir: Path,
    quality_threshold: int = 20,
) -> Dict[str, Path]:
    """处理 FASTQ 文件.
    
    Args:
        input_path: 输入 FASTQ 文件路径
        output_dir: 输出目录
        quality_threshold: 质量阈值
        
    Returns:
        包含输出文件路径的字典
    """
    logger.info(f"Processing {input_path}")
    ...
```

### 测试要求

- 新功能必须添加测试
- Bug 修复必须添加回归测试
- 使用 `pytest` 框架
- 覆盖率目标: >80%

---

## 常用命令

### 开发

```bash
# 安装开发依赖
pip install -e ".[dev]"

# 运行 pre-commit
pre-commit run --all-files

# 运行测试
pytest tests/ -v --cov=micos

# 类型检查
mypy micos/
```

### 分析

```bash
# 完整分析流程
python -m micos.cli full-run \
    --input-dir data/raw_input \
    --results-dir results \
    --threads 16

# 单个模块
python -m micos.cli qc --input-dir data/raw_input
```

### 文档

```bash
# 本地文档服务
mkdocs serve

# 构建文档
mkdocs build
```

---

## OpenSpec 工作流

当处理非平凡任务时，遵循 OpenSpec 流程：

1. **探索**: 理解需求和现有代码
2. **变更提案**: 在 `openspec/changes/` 创建提案
3. **实施**: 按提案执行
4. **审查**: 阶段边界审查
5. **归档**: 完成后清理提案

---

## 安全与敏感信息

### 禁止硬编码

- API 密钥
- 数据库密码
- 个人身份信息
- 服务器地址

### 敏感文件 (已在 .gitignore)

- `config/secrets.yaml`
- `.secrets/`
- `*.env`

---

## MCP 工具集成

### 可用 MCP 工具

| 工具 | 用途 |
|------|------|
| `lsp_*` | 代码导航、重构 |
| `ast_grep_*` | AST 模式搜索替换 |
| `project_memory_*` | 项目知识持久化 |
| `wiki_*` | 项目 Wiki 管理 |

### LSP 使用场景详解

#### 代码导航

```python
# 查找函数定义
# 文件: micos/cli.py, 行: 45, 字符: 5
lsp_goto_definition(file="micos/cli.py", line=45, character=5)
# 返回: 定义位置

# 查找所有引用
lsp_find_references(file="micos/cli.py", line=45, character=5)
# 返回: 所有调用该函数的位置

# 查找符号定义
lsp_workspace_symbols(query="process_fastq", file="micos/cli.py")
# 返回: 项目中所有匹配符号
```

#### 代码重构

```python
# 检查是否可重命名
lsp_prepare_rename(file="micos/cli.py", line=45, character=5)

# 执行重命名（跨文件）
lsp_rename(
    file="micos/cli.py",
    line=45,
    character=5,
    newName="process_fastq_file"
)
```

#### 类型信息

```python
# 获取类型信息和文档
lsp_hover(file="micos/cli.py", line=45, character=5)
# 返回: 类型签名和 docstring
```

#### 诊断

```python
# 获取文件诊断
lsp_diagnostics(file="micos/cli.py", severity="error")
# 返回: 错误和警告列表

# 项目级诊断
lsp_diagnostics_directory(directory="micos/", strategy="tsc")
```

### AST 模式搜索替换

#### 搜索代码模式

```python
# 查找所有 print 语句
ast_grep_search(
    pattern="print($MSG)",
    language="python",
    path="micos/"
)

# 查找所有 subprocess.run 调用
ast_grep_search(
    pattern="subprocess.run($ARGS)",
    language="python",
    path="micos/"
)
```

#### 批量替换

```python
# 替换 print 为 logger
ast_grep_replace(
    pattern="print($MSG)",
    replacement="logger.info($MSG)",
    language="python",
    path="micos/",
    dryRun=True  # 先预览
)
```

### 项目记忆管理

```python
# 读取项目记忆
project_memory_read(section="all")

# 添加技术栈信息
project_memory_write(
    memory={
        "techStack": "Python 3.9+ / Click CLI / pytest",
        "build": "pip install -e '.[dev]'",
        "test": "pytest tests/"
    }
)

# 添加开发笔记
project_memory_add_note(
    category="build",
    content="使用 pyproject.toml 管理依赖，避免 requirements.txt 重复"
)

# 添加用户指令
project_memory_add_directive(
    directive="所有 Shell 命令必须使用 subprocess.run(check=True)",
    priority="normal"
)
```

### Wiki 管理

```python
# 列出所有 Wiki 页面
wiki_list()

# 查询 Wiki
wiki_query(query="Kraken2 数据库配置")

# 添加 Wiki 页面
wiki_add(
    title="Kraken2 配置指南",
    content="...",
    category="reference",
    tags=["kraken2", "database", "configuration"]
)
```

---

## MCP vs CLI Skills 权衡

| 功能 | 推荐 | 原因 |
|------|------|------|
| 代码导航 (lsp_*) | MCP | 深度集成，精确结果 |
| AST 重构 (ast_grep_*) | MCP | 精确模式匹配 |
| 项目记忆 (project_memory_*) | MCP | 持久化存储 |
| Wiki 管理 (wiki_*) | MCP | 结构化知识库 |
| Git 提交 | Skills (zcf:git-commit) | 流程化，轻量级 |
| 分支管理 | Skills (zcf:git-worktree) | 工作流自动化 |
| 测试驱动 | Skills (superpowers:tdd) | TDD 流程 |
| 调试 | Skills (superpowers:debugging) | 系统化调试 |

---

## Wiki 管理流程

### 创建新页面

```python
# 添加架构决策
wiki_ingest(
    title="使用 Kraken2 进行物种分类",
    content="...",
    category="architecture",
    tags=["kraken2", "taxonomy", "classification"],
    confidence="high"
)
```

### 查询知识库

```python
# 搜索相关文档
wiki_query(
    query="如何配置数据库路径",
    category="reference",
    limit=5
)
```

### 维护 Wiki

```python
# 检查 Wiki 健康状态
wiki_lint()

# 统计信息
wiki_stats()
```

---

## 项目记忆

使用 `project_memory` 工具持久化重要信息：

```yaml
techStack:
  language: Python 3.9+
  framework: Click CLI
  testing: pytest
  docs: MkDocs Material

build:
  command: pip install -e ".[dev]"
  test: pytest tests/

conventions:
  formatter: Black (88 chars)
  imports: isort
  types: MyPy basic
```

---

## 相关文件索引

| 文件 | 用途 |
|------|------|
| [AGENTS.md](AGENTS.md) | 完整项目上下文 |
| [copilot-instructions.md](.github/copilot-instructions.md) | Copilot 指令 |
| [openspec/README.md](openspec/README.md) | OpenSpec 索引 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献指南 |
