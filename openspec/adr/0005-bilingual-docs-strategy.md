# ADR-0005: 文档双语策略

## 状态

✅ 已采纳

## 背景

MICOS-2024 项目文档存在以下问题：

1. **中英文档不同步**: 英文完整，中文缺失 4 个核心文档
2. **冗余文件**: docs/ 根目录有 7 个重复文件
3. **维护困难**: 无明确的双语维护流程
4. **链接失效**: README.md 引用不存在的文件

## 决策

采用**双语同步维护**策略：

### 1. 目录结构

```
docs/
├── README.md              # 文档索引
├── en/                    # 英文文档（主）
│   ├── index.md
│   ├── installation.md
│   ├── configuration.md
│   ├── taxonomic-profiling.md
│   ├── functional-profiling.md
│   ├── diversity-analysis.md
│   ├── troubleshooting.md
│   ├── faq.md
│   └── api-reference.md
├── zh/                    # 中文文档
│   ├── index.md
│   ├── installation.md
│   ├── configuration.md
│   ├── taxonomic-profiling.md
│   ├── functional-profiling.md
│   ├── diversity-analysis.md
│   ├── troubleshooting.md
│   ├── faq.md
│   ├── api-reference.md
│   └── user_manual.md
├── images/                # 共享图片
├── includes/              # 共享内容
└── overrides/             # MkDocs 自定义
```

### 2. 同步规则

| 规则 | 说明 |
|:---|:---|
| 英文为主 | 新功能先写英文文档 |
| 中文跟进 | 1 周内完成翻译 |
| 版本同步 | 中英文档版本号一致 |
| 链接检查 | CI 自动检查断链 |

### 3. 翻译流程

1. 创建/更新英文文档
2. 创建对应的中文文档
3. 更新 `mkdocs.yml` 导航
4. 检查所有链接有效
5. 提交 PR 审查

### 4. 删除冗余

删除 docs/ 根目录的所有 MD 文件（除 README.md）

## 后果

### 正面

- 文档覆盖完整
- 结构清晰
- 易于维护
- 用户体验一致

### 负面

- 需要翻译工作量
- 需要保持同步
- 增加文档体积

## 文档覆盖目标

| 指标 | 当前 | 目标 |
|:---|:---:|:---:|
| 英文覆盖率 | 100% | 100% |
| 中文覆盖率 | 60% | 100% |
| 断链数 | 6 | 0 |
| 冗余文件 | 7 | 0 |

## 参考

- [MkDocs 多语言支持](https://squidfunk.github.io/mkdocs-material/setup/changing-the-language/)
- [文档最佳实践](https://www.writethedocs.org/guide/)
