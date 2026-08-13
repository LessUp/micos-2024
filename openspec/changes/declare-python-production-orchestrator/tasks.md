# Tasks: declare-python-production-orchestrator

## 1. Baseline

- [x] 1.1 记录 HEAD/status，核对 Python full-run、shell wrapper 和 WDL 数量/入口
  - HEAD: c2c399f, clean; Python CLI: micos full-run; shell: run_full_analysis.sh (wrapper); WDL: 6 files in steps/01-06
- [x] 1.2 全仓搜索 WDL/workflow/resume/skip/full-run/production 并保存需修改清单
  - README.md, AGENTS.md had conflicting claims; shell script already correct
- [x] 1.3 运行现有快速 Python test 基线
  - pytest not in system; installed to temp; test_orchestration_docs.py: 6 passed

## 2. Specification and documentation

- [x] 2.1 建立 openspec/project.md，记录 MICOS-ORCH-001
- [x] 2.2 更新 README 和 docs 的单一生产入口、WDL 实验性及 resume 不支持声明
  - README: WDL badge -> Experimental; feature line -> Python CLI; WDL section -> experimental; project description updated
- [x] 2.3 对齐 CLI help、shell/WDL 说明和 AGENTS.md 中冲突的当前事实
  - AGENTS.md: WDL section labeled experimental; contributor guidance updated
  - Shell script already correct (wrapper, skip/resume unsupported)
- [x] 2.4 添加可维护的文档一致性检查
  - tests/test_orchestration_docs.py: 6 tests verifying README, AGENTS.md, shell script consistency

## 3. Verification

- [x] 3.1 black --check --diff - passed
- [x] 3.2 flake8 - passed
- [x] 3.3 pytest tests/test_orchestration_docs.py - 6 passed
- [x] 3.4 git diff --check, scope audit, verification.md - passed
