---
title: 故障排除
---

# 故障排除

## `validate-config` 一开始就失败

通常是以下问题：

- 模板占位符没有替换
- `config/databases.yaml` 指向了不存在的路径
- `config/analysis.yaml` 与数据库配置不一致

先运行：

```bash
micos validate-config --config config/analysis.yaml
```

## `full-run` 提示缺少数据库路径

稳定 CLI 需要明确提供 KneadData 和 Kraken2 数据库路径：

```bash
micos full-run \
  --kneaddata-db /db/kneaddata/human_genome \
  --kraken2-db /db/kraken2/standard
```

## 包装脚本行为和预期不同

包装脚本是委托层，委托给 CLI 命令。先检查它委托到的 CLI 命令。

## 容器就绪但运行仍然失败

环境就绪不等于流程正确。Compose 示例帮助准备环境，但不能替代配置验证和命令级检查。

## 文档里提到了高级分析，但主 CLI 里找不到

这些能力可能位于 `scripts/` 而不是稳定 CLI。请结合[项目结构](./reference/project-structure)和 [CLI 参考](./reference/cli)判断它属于哪一层。
