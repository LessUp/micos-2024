---
title: 常见问题
---

# 常见问题

## MICOS-2024 是 workflow engine 吗

不是。它是一个围绕宏基因组工具栈构建的 CLI 平台，同时包含 `steps/` 下的 WDL 工作流资产和 `containers/` 下的环境资产。

## `scripts/` 里的所有脚本都属于稳定公共接口吗

不是。很多脚本是专家扩展或探索性能力。稳定的命令面请看 [CLI 参考](./reference/cli.md)。

## 新项目应该优先用包装脚本还是 Python CLI

优先用 Python CLI。包装脚本适合兼容旧工作流，但不是新项目的事实标准。

## 为什么配置模板看起来比 CLI 大很多

模板反映的是更大的平台视野（包括 `scripts/` 下的扩展分析），而当前稳定 CLI 只覆盖主链路。

## 从哪里开始了解项目

建议顺序：

1. [首页](./)
2. [流程基础](./academy/pipeline-foundations)
3. [系统总览](./architecture/system-overview)
4. [CLI 参考](./reference/cli)
