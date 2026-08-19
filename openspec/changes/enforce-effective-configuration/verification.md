# Verification: enforce-effective-configuration

## Metadata

- Verification status: `Implemented — evidence recorded, awaiting reviewer`
- Implementation HEAD: `f7f58969fe1e736e591249063650de26b95c490d`
- Verifier: `(implementer; independent reviewer pending)`
- Verified at: `2026-08-19`
- Ready to archive: `no`

## Scope audit

- Expected files/modules: `micos/config.py`、`micos/cli.py`、`config/*.template`、
  配置文档、`tests/`
- Actual changed files:
  - `micos/config.py`（extra=forbid、去 memory_gb、相对路径解析、优先级 resolve）
  - `micos/cli.py`（fail-closed 加载、validate-config、dry-run resolved plan、来源输出）
  - `config/analysis.yaml.template`、`config/databases.yaml.template`（只留已接入字段）
  - `docs/zh/configuration.md`、`docs/zh/roadmap.md`（配置文档）
  - `tests/test_config.py`、`tests/test_cli.py`、`tests/test_utils.py`（测试）
  - `openspec/changes/enforce-effective-configuration/`（tasks.md、verification.md）
- Unexpected changes: 无；未触碰 `steps/`、生信工具、容器/环境版本、`scripts/` R 脚本
- Existing user changes preserved: 是——apply 前工作区仅有未跟踪的
  `openspec/changes/enforce-effective-configuration/`（本 change 的 spec 文件），
  已保留；无其他用户改动被覆盖

## Requirement traceability

| Requirement | Scenario | Test/command | Result | Evidence summary |
|---|---|---|---|---|
| Production configuration rejects unknown fields | Unknown field in YAML | `pytest tests/test_config.py` | pass | `TestStrictValidation::test_rejects_unknown_top_level_field` 等；`extra="forbid"` 报字段名并抛 ValidationError |
| Production configuration rejects unknown fields | Wrong field type | `pytest tests/test_config.py` | pass | `test_rejects_wrong_field_type`：`max_threads: "not-an-int"` 被拒 |
| Templates contain only wired fields | User copies the template | dry-run plan 检查 | pass | 模板仅含 input_dir/output_dir/databases.{kneaddata,kraken2}/max_threads 与 human_genome/standard；dry-run 可观察到全部字段 |
| Unimplemented resource fields are absent | User reads the active template | `grep` template | pass | `config/analysis.yaml.template` 无 `max_memory`/`memory_gb`/`max_time`；已迁至 `docs/zh/roadmap.md` |
| Configuration failures fail closed | Corrupted YAML | `pytest tests/test_config.py` | pass | `test_from_yaml_corrupted_raises`（YAMLError）；`test_from_yaml_empty_raises`（ConfigError） |
| Configuration precedence is explicit and traceable | CLI overrides file | `pytest tests/test_cli.py` | pass | `test_full_run_dry_run_cli_override_reports_cli_source`：`threads: cli` |
| Configuration precedence is explicit and traceable | Conflicting database sources | `pytest tests/test_config.py` | pass | `TestConfigPriority::test_analysis_overrides_databases_for_db_paths`：analysis.yaml 优先，来源可报 |
| Relative paths resolve against the containing config file | Config in another directory | `pytest tests/test_config.py` | pass | `TestRelativePathResolution`：input/results/db 相对配置文件目录解析 |
| validate-config fails on invalid configuration | Invalid configuration | `validate-config` CLI | pass | 未知字段/损坏 YAML/缺失必需 DB → exit 3；占位符 → exit 0 + warning（端到端验证） |
| Dry-run emits a resolved plan without executing tools | Dry-run on valid config | `--dry-run` CLI | pass | `test_full_run_dry_run_prints_resolved_plan_with_sources`；输出阶段/输入/输出/threads/数据库/参数来源，不执行工具 |
| Configuration errors surface at the CLI boundary | Configuration exception | `pytest tests/test_cli.py` | pass | `test_config_error_at_cli_boundary_exits_stable_code`：损坏配置 → exit 3，不静默回退默认值 |

## Commands

| Command | Exit status | Result summary |
|---|---:|---|
| `pytest tests/test_config.py tests/test_cli.py -v` | 0 | 40 passed |
| `black --check --diff micos tests` | 1 | 本 change 改动的 5 个文件通过；4 个未触碰的既有 `tests/` 文件（test_diversity_analysis/test_shell_wrappers/test_summarize_results/test_sample）不符合 black 26.5.1（项目 pin 版本）——既有问题，CI 实际只检查 `micos scripts`，未改动这些文件 |
| `isort --check-only --diff micos tests` | 1 | 本 change 文件通过；既有 `tests/test_shell_wrappers.py` 不符合（未改动） |
| `flake8 micos tests` | 1 | 本 change 文件通过；既有 `tests/test_sample.py`（E303）与 `tests/test_summarize_results.py`（F401）不符合（未改动） |
| `mypy micos --ignore-missing-imports` | 0 | Success: no issues found in 12 source files（含 python_version 3.9 提示，mypy 2.x 不支持 3.9 target，但不影响结果） |
| `pytest tests/ -v` | 0 | 104 passed |
| `git diff --check` | 0 | 无空白错误 |

## Not run

- `micos` 真实 full-run（会调用外部生信工具）：仅以 `--dry-run` 验证 resolved plan
  不执行工具；不在此环境运行外部工具。
- Archive（4.1–4.3）：需 reviewer 确认 `Ready to archive: yes` 后执行；本次未归档。

## Residual risks

- 收紧 `extra="forbid"` 会影响含未接入字段的既有配置：此类配置在启动前即失败
  （fail-closed），文档已指引迁移到 `docs/zh/roadmap.md`。
- 相对路径语义变化：之前相对 CWD，现在相对配置文件目录；`tests/test_utils.py`
  已更新为新语义。
- `black/isort/flake8` 全量门禁因 4 个既有 `tests/` 文件不符合项目 pin 版本而
  非零；与本次 change 无关，未擅自重排。
- `validate-config` 对缺失 KneadData/Kraken2 数据库从“仅警告”变为“错误退出”；
  占位符路径仍为警告（模板复制后可直接通过校验并收到警告）。

## Verdict

实现完成，delta spec 验收场景全部通过（新增 22 个测试 + 既有 82 个，共 104 通过）；
`Ready to archive` 等待独立 reviewer 确认后置 yes 再归档。
