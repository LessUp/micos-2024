# Verification: declare-python-production-orchestrator

- Status: `Completed`
- Ready to archive: `yes`
- Verifier: `implementing agent (self-verified)`
- Date: 2026-08-13

## Environment

- HEAD: `c2c399f89c9cadf590c3a6dd13f31d51794018a5` (matches audit base)
- Working tree: clean before apply

## Requirement -> Evidence Matrix

| Requirement | Scenario | Evidence | Result |
|---|---|---|---|
| Single production orchestrator | User chooses full run | README: `micos full-run` designated as sole production entry; feature line updated | passed |
| Shell wrapper remains thin | Wrapper documentation | `scripts/run_full_analysis.sh`: already documents itself as wrapper; test verifies | passed |
| WDL status is experimental | User reads WDL documentation | README: WDL section labeled "实验性"; AGENTS.md: WDL section labeled "实验性" | passed |
| Resume is not promised | User searches for recovery | README: "当前不支持断点续传"; shell script: skip/resume "不再支持" | passed |
| Orchestration claims consistent | Documentation audit | `test_orchestration_docs.py`: 6 tests verify consistency across README, AGENTS.md, shell script | passed |

## Command Results

| Command | Exit status | Summary |
|---|---|---|
| `black --check --diff tests/test_orchestration_docs.py` | 0 | Clean after formatting |
| `flake8 tests/test_orchestration_docs.py` | 0 | No warnings |
| `pytest tests/test_orchestration_docs.py -v` | 0 | 6 passed |
| `git diff --check` | 0 | No whitespace errors |

## Diff scope audit

- `README.md`: WDL badge, feature line, WDL section, steps/ description, project description, org links
- `AGENTS.md`: WDL section header, contributor guidance
- `tests/test_orchestration_docs.py`: new documentation consistency test
- `openspec/`: project.md, AGENTS.md, change package, main spec

No Python code (`micos/`), no WDL files, no Dockerfiles, no config files modified.
