# ADR-0003: 依赖版本锚定策略

## 状态

✅ 已采纳

## 背景

MICOS-2024 项目依赖管理存在以下问题：

1. **版本约束过于宽松**: 使用 `>=` 而非精确版本
   ```toml
   dependencies = [
       "numpy>=1.21.0",  # 可能安装任意新版本
       "pandas>=1.3.0",
   ]
   ```

2. **依赖文件重复**: `requirements.txt` 与 `pyproject.toml` 内容重复

3. **缺少真正的 lock 文件**: `requirements-lock.txt` 不是真正的锁定文件

4. **版本不一致风险**: 不同环境可能安装不同版本

## 决策

采用**精确版本锚定**策略：

### 1. 使用精确版本号

```toml
dependencies = [
    "numpy==1.26.4",
    "pandas==2.2.0",
    "scipy==1.12.0",
]
```

### 2. 使用 `pip-compile` 生成 lock 文件

```bash
pip-compile pyproject.toml -o requirements.lock
```

### 3. 简化 `requirements.txt`

```txt
# MICOS-2024 Dependencies
# Install: pip install -e ".[dev]"
# Lock file: requirements.lock
```

### 4. 版本更新流程

1. 更新 `pyproject.toml` 中的版本
2. 运行 `pip-compile` 更新 lock 文件
3. 运行测试验证兼容性
4. 提交更新

## 后果

### 正面

- 环境可重现
- 避免依赖冲突
- CI/CD 结果一致
- 易于问题排查

### 负面

- 需要手动更新版本
- 可能错过安全更新
- 需要定期维护

## 版本选择原则

| 依赖类型 | 版本策略 | 原因 |
|:---|:---|:---|
| 核心依赖 | 最新稳定版 | 功能完整 |
| 开发依赖 | 兼容版本 | 工具稳定 |
| 生物信息学 | 测试通过版本 | 兼容性优先 |

## 参考

- [Python 依赖管理最佳实践](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [pip-tools 文档](https://github.com/jazzband/pip-tools)
