# Design: enforce-effective-configuration

## Context

`micos/config.py` 用 Pydantic 模型做类型验证，但多个 model 使用
`ConfigDict(extra="allow")`，未知字段被静默允许；`ResourcesConfig` 含
`memory_gb` 等未实现资源限制的字段；模板与 CLI 接入关系没有强制校验。
`declare-python-production-orchestrator` 已确认 Python CLI 是唯一生产编排器，
本 change 在其配置语义上收紧为 fail-closed 且可追踪。

## Goals

- 未知字段、错误类型、损坏 YAML 在外部工具启动前失败；
- 模板只保留已接入 CLI 的字段；
- 明确优先级（CLI > analysis.yaml > databases.yaml > 默认）并报告 resolved 来源；
- 相对路径相对所在配置文件解析；
- `validate-config` 对无效配置返回非零；
- `--dry-run` 输出 resolved plan 且不执行外部工具。

## Non-goals

- 不实现 `record-run-manifest`；
- 不一次性接入全部愿景参数；
- 不实现资源限制本身。

## Current flow

```text
config/*.yaml --(yaml.safe_load + Pydantic, extra="allow")--> dict/model
未知字段: 静默允许; 类型错误: 可能抛异常; 相对路径: 相对 CWD
```

## Target flow

```text
config/*.yaml --(yaml.safe_load + Pydantic extra="forbid")--> model (fail on unknown/type)
  --> 相对路径按所在配置目录解析 --> 按优先级合并 CLI 覆盖 --> resolved plan
  --> full-run 使用 resolved plan; --dry-run 仅打印 plan; validate-config 校验并退出码
```

## Decisions

### extra="forbid" on production models

- Choice: 生产配置 model 统一 `extra="forbid"`
- Reason: 拼错字段立即失败，避免静默忽略
- Alternatives rejected: `extra="allow"` 加告警（仍可能漏过，且难保证 fail-closed）

### Remove unimplemented resource fields from active config

- Choice: `max_memory`/`memory_gb` 从活动配置移除，移至 roadmap 文档
- Reason: 未实现的资源限制字段会造成“配置了但未生效”的假象

## Allowed change surface

- `micos/config.py`：Pydantic 模型、校验、优先级合并、路径解析；
- `micos/cli.py`：`validate-config`、`--dry-run`、配置错误退出码；
- `config/*.template`、配置文档；
- `tests/`：配置与 CLI 测试。

Files/modules outside this list require proposal revision and renewed approval.

## Contract and compatibility

配置格式收紧为 fail-closed：此前可被静默忽略的未知字段现在失败。合法既有配置
（字段均已接入、类型正确）不受影响。退出码在 CLI 边界稳定化。

## Failure, resource and security behavior

- 配置失败不吞异常、不启动外部工具；
- `--dry-run` 不产生副作用；
- 相对路径不依赖进程 CWD，避免跨目录误解析。

## Test and fixture design

| Requirement/scenario | Test level | Expected result |
|---|---|---|
| 未知字段 | unit | `extra="forbid"` 拒绝并报字段名 |
| 错误类型 | unit | 校验失败 |
| 空 YAML / 损坏 YAML | unit | 配置错误退出 |
| 相对路径 | unit | 相对所在配置目录解析 |
| CLI 覆盖 | unit | 优先级 CLI > 文件，来源可报告 |
| 数据库配置来源冲突 | unit | 按优先级或报错 |
| `--dry-run` 不执行工具 | integration | 只打印 plan，无外部调用 |
| `validate-config` 非零 | integration | 语法/未知字段/缺 stage 依赖返回非零 |

## Risks and mitigations

| Risk | Likelihood/impact | Mitigation |
|---|---|---|
| 收紧破坏既有合法配置 | 中/低 | 只拒绝未接入字段；文档说明迁移 |
| 模板字段遗漏 | 中/中 | 验收条件：模板字段都能在 dry-run plan 中观察到 |

## Rollback details

还原 `micos/config.py`、`micos/cli.py`、模板与测试即可；无已生成数据需要兼容。
