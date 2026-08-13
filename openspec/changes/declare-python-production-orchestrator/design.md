# Design: declare-python-production-orchestrator

## Evidence

- `micos full-run` 调用 `micos/full_run.py` 串联主要 stages；
- `scripts/run_full_analysis.sh` 是 Python CLI 薄包装，并拒绝旧 skip/resume 参数；
- `steps/` 包含分散 WDL，但没有受验证的顶层全流程；
- README 的 WDL/resume 宣称高于当前实现。

## Documentation model

所有入口使用同一支持矩阵：

| Entry | Status | Promise |
|---|---|---|
| `micos full-run` | production | 当前唯一全流程参数语义和执行入口 |
| `scripts/run_full_analysis.sh` | supported wrapper | 参数转发到 Python，不形成第二套语义 |
| `steps/**/*.wdl` | experimental | 单步骤参考，不保证与 Python 全流程等价 |
| resume/skip | unsupported | 不宣称目录存在即可恢复 |

## Allowed surface

- `openspec/`
- `README.md`, `docs/`
- CLI help/docstrings 中能力描述
- `scripts/run_full_analysis.sh` 的说明文字（不改执行语义）
- `steps/` 中 README/注释性的状态说明
- `AGENTS.md` 中与编排事实冲突的指导

## Verification

建立关键词审计列表：WDL、workflow、full-run、resume、断点、skip、production。每个命中人工归类，确保历史说明可以保留，但当前能力不能过度承诺。运行 Python tests 证明纯文档/change 没有意外影响。
