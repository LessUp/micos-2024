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
python -m micos.cli run quality-control \
    --input-dir data/raw_input \
    --output-dir results/quality_control \
    --kneaddata-db /path/to/db
```

### 文档

```bash
# 本地文档服务 (VitePress)
cd docs && npm run dev

# 构建文档
cd docs && npm run build
```

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

## 相关文件索引

| 文件 | 用途 |
|------|------|
| [AGENTS.md](AGENTS.md) | 完整项目上下文 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 贡献指南 |
