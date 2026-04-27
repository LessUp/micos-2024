# ADR-0004: CI/CD 精简策略

## 状态

✅ 已采纳

## 背景

MICOS-2024 项目 GitHub Workflows 存在过度设计问题：

1. **测试矩阵过大**: 2 OS × 3 Python = 6 个任务
2. **缺少缓存**: 每次重新安装依赖
3. **过度设计的清理**: `gh-pages-cleanup.yml` 每月运行但项目无多版本需求
4. **无效配置**: Safety 检查需要 API key

## 决策

采用**精简高效**策略：

### 1. 精简测试矩阵

```yaml
strategy:
  matrix:
    python: ['3.9', '3.11']  # 仅最低和最高版本
    os: [ubuntu-latest]      # 主要支持 Linux
```

### 2. 添加 pip 缓存

```yaml
- uses: actions/setup-python@v5
  with:
    python-version: ${{ matrix.python-version }}
    cache: 'pip'
```

### 3. 删除过度设计的 workflow

- 删除 `gh-pages-cleanup.yml`（无多版本需求）
- 简化 `pages.yml` 版本管理

### 4. 优化依赖安装

```yaml
- name: Install dependencies
  run: |
    pip install -e ".[dev]"
    # 而非单独安装每个工具
```

## 后果

### 正面

- CI 运行时间减少 50%+
- 减少资源消耗
- 维护成本降低
- 更快的反馈周期

### 负面

- 减少平台覆盖（无 macOS 测试）
- 可能错过某些兼容性问题

## 性能目标

| 指标 | 当前 | 目标 |
|:---|:---:|:---:|
| CI 运行时间 | ~15 min | <10 min |
| 测试任务数 | 6 | 2 |
| 缓存命中 | 0% | >80% |

## 参考

- [GitHub Actions 缓存](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [CI/CD 最佳实践](https://docs.github.com/en/actions/using-workflows/about-workflows)
