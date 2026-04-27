# OpenSpec 规范索引

> MICOS-2024 项目的技术规范与架构决策记录

## 目录结构

```
openspec/
├── README.md           # 本文件 - OpenSpec 索引
├── adr/                # 架构决策记录 (Architecture Decision Records)
│   ├── 0001-record-architecture.md
│   └── template.md
├── specs/              # 技术规范文档
│   ├── analysis-pipeline.md
│   ├── container-strategy.md
│   └── configuration-schema.md
└── changes/            # 变更提案模板
    └── template.md
```

## 架构决策记录 (ADR)

| 编号 | 标题 | 状态 | 日期 |
|------|------|------|------|
| [0001](adr/0001-record-architecture.md) | 架构决策记录体系 | ✅ 已采纳 | 2024-04 |

## 技术规范

| 规范 | 描述 |
|------|------|
| [analysis-pipeline.md](specs/analysis-pipeline.md) | 分析流程架构规范 |
| [container-strategy.md](specs/container-strategy.md) | 容器化部署策略 |
| [configuration-schema.md](specs/configuration-schema.md) | 配置文件模式定义 |

## OpenSpec 工作流

### 创建变更提案

1. 复制 `changes/template.md` 创建新提案
2. 填写提案内容
3. 提交 PR 进行评审
4. 合并后执行实施

### 记录架构决策

1. 复制 `adr/template.md` 创建新 ADR
2. 编号递增 (0002, 0003, ...)
3. 填写决策背景、选项、结果
4. 提交并更新本索引

## 相关资源

- [项目文档](https://bgi-micos.github.io/MICOS-2024/)
- [贡献指南](../CONTRIBUTING.md)
- [变更日志](../CHANGELOG.md)
