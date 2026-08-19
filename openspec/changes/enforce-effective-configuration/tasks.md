# Tasks: enforce-effective-configuration

## 1. Baseline and tests

- [x] 1.1 记录 `git status --short`、HEAD 与 base commit 差异
      （apply 前仅有未跟踪 `openspec/changes/enforce-effective-configuration/`；
      HEAD = base = `f7f58969fe1e736e591249063650de26b95c490d`，无差异）
- [x] 1.2 运行现有配置/CLI 基线测试：`pytest tests/test_config.py tests/test_cli.py -v`
      ——18 passed
- [x] 1.3 添加失败用例测试：未知字段、错误类型、空 YAML、损坏 YAML、
      相对路径、CLI 覆盖、数据库配置来源冲突
      ——`tests/test_config.py` 新增 TestStrictValidation / TestRelativePathResolution /
      TestConfigPriority；`tests/test_cli.py` 新增 validate-config / dry-run /
      边界退出码测试；`tests/test_utils.py` 更新相对路径断言
- [x] 1.4 确认新增测试在实现前按预期失败
      ——实现前 `pytest` 收集报 `ImportError: cannot import name 'ConfigError'`，确认失败

## 2. Implementation

- [x] 2.1 生产配置 model 改为 `extra="forbid"`；验证：`pytest tests/test_config.py -v`
      ——全部 7 个 model 改为 forbid；测试通过
- [x] 2.2 从活动配置移除 `max_memory`/`memory_gb` 漂移字段（迁至 roadmap 文档）；
      `config/*.template` 只保留已接入 CLI 的字段
      ——移除 `ResourcesConfig.memory_gb` 与模板中 `resources.max_memory`/`max_time`、
      `project`、`paths.temp_dir/log_dir`、QC/分类/多样性/功能愿景字段；迁至
      `docs/zh/roadmap.md`
- [x] 2.3 实现配置优先级（CLI > analysis.yaml > databases.yaml > 默认）与
      resolved value 来源输出；相对路径按所在配置文件目录解析
      ——`config.resolve_full_run_config` + `ResolvedValue`；`AnalysisConfig`/
      `DatabasesConfig` 记录 `_config_dir` 并解析相对路径；CLI dry-run 输出来源
- [x] 2.4 `validate-config` 对语法/未知字段/必需 stage 依赖返回非零；
      占位符与可选数据库仅 warning
      ——语法/未知字段/类型 → exit 3；缺少 kneaddata/kraken2 必需依赖 → exit 3；
      占位符（`/path/to/`、`${...}`）与可选数据库 → warning（exit 0）
- [x] 2.5 `--dry-run` 输出 resolved plan（stage、输入、输出、threads、数据库、
      参数来源），不执行外部工具
      ——full-run dry-run 打印 Resolved Plan + 参数来源 + 执行阶段，无副作用
- [x] 2.6 在 CLI 边界将已知配置异常转换为稳定退出码，不用宽泛 `except Exception`
      吞掉配置失败
      ——`main` 组回调改为 catch 已知配置异常（ConfigError/YAMLError/ValidationError/
      OSError）→ `EXIT_CONFIG_ERROR`（3），删除宽泛 except + 回退默认值

## 3. Verification

- [x] 3.1 运行配置/CLI 测试：`pytest tests/test_config.py tests/test_cli.py -v`
      ——40 passed
- [x] 3.2 运行仓库标准门禁：
      - `black --check --diff micos tests` → 我改动的 5 个文件通过；4 个未触碰的
        既有 `tests/` 文件（test_diversity_analysis/test_shell_wrappers/
        test_summarize_results/test_sample）不符合 black 26.5.1（项目 pin 版本），
        为既有问题（CI 实际只检查 `micos scripts`），未改动
      - `isort --check-only --diff micos tests` → 我改动的文件通过；既有
        `test_shell_wrappers.py` 不符合（未改动）
      - `flake8 micos tests` → 我改动的文件通过；既有 `test_sample.py`(E303) 与
        `test_summarize_results.py`(F401) 不符合（未改动）
      - `mypy micos --ignore-missing-imports` → exit 0，无问题
      - `pytest tests/ -v` → 104 passed
- [x] 3.3 逐条核对 delta spec scenarios 并填写 `verification.md`
- [x] 3.4 运行 `git diff --check`，审查 diff 未超出 allowed surface
      ——exit 0；改动限于 `micos/config.py`、`micos/cli.py`、`config/*.template`、
      配置文档（`docs/zh/configuration.md`、`docs/zh/roadmap.md`）、`tests/`、`openspec/`

## 4. Archive readiness

- [ ] 4.1 Reviewer 确认 `verification.md` 的 `Ready to archive: yes`
- [ ] 4.2 将 delta 同步到主规格
- [ ] 4.3 按日期归档 change
