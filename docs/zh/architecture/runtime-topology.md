---
title: 运行时拓扑
---

# 运行时拓扑

运行时拓扑回答的是一个实践问题：**MICOS-2024 究竟在哪些层上运行，谁把工作交给谁？**

<ThemeAsset
  light="/illustrations/runtime-topology-light.svg"
  dark="/illustrations/runtime-topology-dark.svg"
  alt="运行时拓扑图"
  caption="项目横跨入口命令、Python 编排模块、工作流资产、配置模板与扩展分析脚本。"
/>

## 执行面

### 稳定 CLI 路径

最干净的运行路径是：

```bash
micos full-run --input-dir data/raw_input --results-dir results
```

这是当前最值得推荐的主入口。

### Shell 包装路径

仓库中有两个包装脚本：

- `scripts/run_full_analysis.sh`
- `scripts/run_module.sh`

它们现在更接近“兼容入口”，而不是独立流程引擎。这是健康的演进方向。

### 工作流资产路径

`steps/` 中的 WDL 文件表达了步骤级工作流关系。它们不是 CLI 的别名，而是另一层集成能力。

### 容器路径

`deploy/docker-compose.example.yml` 与 `containers/singularity/*.def` 描述的是环境策略。对于生信平台来说，这一层非常关键，因为很多失败发生在环境边界，而不是算法边界。

## 按职责划分

| 关注点 | 主负责层 | 辅助层 |
| --- | --- | --- |
| 命令体验 | `micos/cli.py` | shell wrappers |
| 流程编排 | `micos/full_run.py` | 其他 `micos/` 模块 |
| 可重现环境 | `deploy/`, `containers/` | workflow assets |
| 配置模板 | `config/*.template` | CLI 配置加载 |
| 扩展分析 | `scripts/` | 结果目录 |

## 典型故障模式

### 配置不一致

最常见的问题通常不是算法本身，而是：

- 分析模板，
- 数据库模板，
- 命令行参数

三者之间没有对齐。

### 包装层漂移

如果 Shell 包装层逐渐长成第二套逻辑，维护成本会急速上升。当前仓库正在把包装层收缩成委托层，这是好事。

### 环境漂移

当容器、工作流和直接 CLI 描述的是不同现实，项目的可重现性就会被削弱。文档要把这些层分开说明，不能混写。
