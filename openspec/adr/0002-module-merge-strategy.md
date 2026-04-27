# ADR-0002: 模块合并策略

## 状态

✅ 已采纳

## 背景

MICOS-2024 项目存在两个 Python 代码目录：
- `micos/` - 核心 Python 包 (1,081 行)
- `scripts/` - 辅助脚本 (2,544 行)

这两个目录存在功能重叠：
- 同名模块: `functional_annotation.py`, `summarize_results.py`
- `scripts/` 包含实际业务逻辑，`micos/` 只是包装层

问题：
1. 代码重复导致维护困难
2. 职责边界不清晰
3. 测试覆盖不明确
4. 导入路径混乱

## 决策

采用**分离策略**，明确职责边界：

### `micos/` - 核心库
- 所有可复用的业务逻辑
- 类型注解和文档字符串
- 单元测试覆盖
- 作为 Python 包发布

### `scripts/` - 命令行入口
- 仅包含 Shell/R 脚本
- 独立工具脚本（如 `amplicon_analysis.py`）
- 数据库下载脚本
- 不包含核心业务逻辑

### 迁移规则

| 文件类型 | 目标位置 | 原因 |
|:---|:---|:---|
| Python 业务逻辑 | `micos/` | 可复用、可测试 |
| Shell 脚本 | `scripts/` | 系统操作 |
| R 脚本 | `scripts/` | 统计分析 |
| 独立工具 | `scripts/` | 单次使用 |

## 后果

### 正面

- 职责清晰，易于维护
- 测试覆盖明确
- 包结构规范
- 避免代码重复

### 负面

- 需要重构现有代码
- 可能影响现有工作流
- 需要更新导入路径

## 实施计划

1. **阶段 1**: 分析 `scripts/*.py` 功能映射
2. **阶段 2**: 将核心逻辑迁移到 `micos/`
3. **阶段 3**: 更新 CLI 入口点
4. **阶段 4**: 补充单元测试
5. **阶段 5**: 清理 `scripts/` 目录

## 参考

- [Python 包结构最佳实践](https://packaging.python.org/en/latest/guides/)
- [单体仓库与多包仓库](https://docs.google.com/document/d/1U6pnWjN0TsY5LWw-4xqLJqZn3A4Y5Z6Y7Y8Y9Y/)
