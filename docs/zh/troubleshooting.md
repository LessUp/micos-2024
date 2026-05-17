---
title: 故障排除
---

# 故障排除

## `validate-config` 一开始就失败

通常是以下几类问题：

- 模板占位符没有替换，
- `config/databases.yaml` 指向了不存在的路径，
- `config/analysis.yaml` 与数据库配置不一致。

先运行：

```bash
python -m micos.cli validate-config --config config/analysis.yaml
```

## `full-run` 提示缺少数据库路径

当前稳定 CLI 需要明确得到以下数据库路径：

- KneadData
- Kraken2

可以直接通过参数提供：

```bash
python -m micos.cli full-run \
  --kneaddata-db /db/kneaddata/human_genome \
  --kraken2-db /db/kraken2/standard
```

## 包装脚本行为和预期不同

先确认你理解的是“委托层”，而不是旧时代的“第二套流程实现”。现在更应该先检查它委托到的 CLI 命令。

## 容器看起来没问题，但运行仍然失败

这通常意味着你把“环境就绪”和“流程正确”混为一谈了。Compose 示例帮助准备环境，但不能替代配置验证和命令级检查。

## 文档里提到了高级分析，但主 CLI 里找不到

这些能力可能位于 `scripts/` 而不是稳定 CLI 面。请结合“项目结构”和“CLI 参考”一起看，判断它属于哪一层。
