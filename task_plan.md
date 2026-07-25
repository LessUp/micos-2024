# MICOS-2024 结构性问题修改方案

> **目标**：修复 GitHub 身份不一致、消除文档 404、补齐 CI 文档构建检查、清理遗留代码
> **前置阅读**：`findings.md`（完整分析报告 + 证据链）
> **状态标记**：`[ ]` 待执行 / `[x]` 已完成

---

## Phase 1: 统一 GitHub 身份 `[x]`

**归属已确认**：维护者确认 BGI-MICOS 组织不存在，项目归属 `LessUp/micos-2024`。所有 BGI-MICOS 引用均为错误，统一修正为 LessUp。

### 1.1 修改 `pyproject.toml`

```diff
- Documentation = "https://bgi-micos.github.io/MICOS-2024/"
+ Documentation = "https://lessup.github.io/micos-2024/"
```

```diff
- {name = "MICOS-2024 Team", email = "micos-team@bgi-micos.github.io"},
+ {name = "MICOS-2024 Team", email = "<实际可用邮箱>"},
```

### 1.2 修改 `AGENTS.md`（3 处）

```diff
- | **组织** | BGI-MICOS |
+ | **组织** | LessUp |
```

```diff
- | **文档** | https://bgi-micos.github.io/MICOS-2024/ |
+ | **文档** | https://lessup.github.io/micos-2024/ |
```

```diff
- git clone https://github.com/BGI-MICOS/MICOS-2024.git
+ git clone https://github.com/LessUp/micos-2024.git
```

### 1.3 修改 `CITATION.md`（5 处）

全部 `github.com/BGI-MICOS/MICOS-2024` → `github.com/LessUp/micos-2024`

### 1.4 修改 `CONTRIBUTING.md`（2 处）

```diff
- 搜索[现有Issues](https://github.com/BGI-MICOS/MICOS-2024/issues)
+ 搜索[现有Issues](https://github.com/LessUp/micos-2024/issues)
```

```diff
- git clone https://github.com/BGI-MICOS/MICOS-2024.git
+ git clone https://github.com/LessUp/micos-2024.git
```

### 1.5 修改 `docs/zh/guides/getting-started.md`

```diff
- git clone https://github.com/BGI-MICOS/MICOS-2024.git
+ git clone https://github.com/LessUp/micos-2024.git
```

### 1.6 验证

- `grep -r "BGI-MICOS\|bgi-micos" --include="*.{md,toml,yml,yaml,ts,json}" .` 应返回零结果（排除 package-lock.json 中的第三方 URL）
- 访问 `https://lessup.github.io/micos-2024/` 确认可达

---

## Phase 2: 修复英文 404 `[x]`

**推荐方案 A**（极简，符合项目当前只有中文内容的现实）：

### 2.1 简化 `docs/index.md`

删除 JavaScript 语言检测重定向，改为直接指向 `/zh/`：

```markdown
---
layout: home
hero:
  name: MICOS-2024
  text: ' '
  actions:
    - theme: brand
      text: 简体中文
      link: /zh/
---
```

移除 `<script setup>` 块和 `<template>` / `<style>` 中的 spinner。

### 2.2 删除 `docs/.vitepress/utils/lang.ts`

grep 验证：`lang.ts` 的唯一调用者是 `docs/index.md`（第 14、18 行）。Phase 2.1 移除 index.md 的 `<script setup>` 后，`lang.ts` 中全部 4 个导出函数（`getSavedLangPreference`、`saveLangPreference`、`detectBrowserLang`、`getTargetLang`）均无调用者，整文件成为死代码。

```bash
git rm docs/.vitepress/utils/lang.ts
```

若将来需要支持英文，从零重建 i18n 基建比保留半死不活的模块更干净。

### 2.3 验证

- 非中文浏览器访问首页 → 不再自动跳转 → 显示中文入口按钮
- 无 `/en/` 路径请求

**备选方案 B**（如果计划近期添加英文内容）：
- 创建 `docs/en/index.md` 占位页："English documentation is under construction."
- 在 VitePress config locales 中添加 `en` 定义

---

## Phase 3: CI 加文档构建检查 `[x]`

### 3.1 在 `.github/workflows/ci.yml` 添加 docs job

```yaml
  docs:
    name: Docs Build
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: docs
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: docs/package-lock.json

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          VITEPRESS_BASE: /micos-2024/
```

只验证构建成功，不部署。与 `pages.yml` 的部署职责分离。`VITEPRESS_BASE` 与 `pages.yml` 保持一致，确保 CI 构建产物与部署环境的 base path 相同（`config.ts` 读取此 env）。

### 3.2 验证

- 提交一个破坏 VitePress 构建的改动 → CI docs job 应失败
- 正常改动 → docs job 通过

---

## Phase 4: 处理遗留 WDL `[x]`

### 4.1 归档 `workflows/wdl_scripts/`

**策略：先归档，不直接删除。** 这些 WDL 可能是早期开发的历史记录，直接删除对维护者不友好。

```bash
# 创建归档 tag 保留完整历史
git tag archive/legacy-wdl-scripts

# 然后从 master 移除
git rm -r workflows/wdl_scripts/
```

10 个文件（6 `.wdl` + 4 `.json` 输入模板）：
- `humann3.wdl`
- `origin-HUMAnN.wdl`
- `meta-dev.wdl`、`meta-dev.json`
- `meta-dev-update.wdl`、`meta-dev-update.json`
- `version-1/meta-stomics-v1.wdl`、`version-1/meta-stomics-v1.json`
- `version-2/meta-stomics-v2.wdl`、`version-2/meta-stomics-v2.json`

归档 tag 确保随时可恢复，比依赖 git 历史翻找更友好。

### 4.2 决策：steps/08、09 的处理

三个选项（需维护者决定）：
- **A. 保留现状**（推荐）：AGENTS.md 已标注"未集成"，不影响主流水线，无需额外操作
- **B. 归档到 tag**：`git tag archive/unintegrated-steps`，然后从 master 删除
- **C. 直接删除**：git 历史保留

### 4.3 验证

- `workflows/` 目录不再存在
- `git tag -l "archive/*"` 确认归档 tag 存在
- AGENTS.md WDL 表格无需修改（只列了 steps/）

---

## Phase 5: 补流水线模块测试 `[x]`

为 4 个无测试的模块各创建测试文件，核心策略：mock `run_command_live`，断言传入的命令行参数列表。

### 5.1 创建测试文件

- `tests/test_quality_control.py`
- `tests/test_taxonomic_profiling.py`
- `tests/test_diversity_analysis.py`
- `tests/test_functional_annotation.py`

### 5.2 测试重点

每个模块验证：
1. 命令行参数拼装正确性（工具名、flag 名称、参数顺序）
2. 输出目录创建逻辑
3. 输入文件不存在时的行为（跳过 or 报错）
4. 样本发现逻辑与 `Sample` 类的交互（diversity_analysis 除外，它接收 BIOM）

### 5.3 示例（diversity_analysis）

```python
def test_diversity_analysis_commands(tmp_path, monkeypatch):
    """验证 QIIME2 命令拼装."""
    commands = []
    def fake_run(cmd):
        commands.append(cmd)
    monkeypatch.setattr("micos.diversity_analysis.run_command_live", fake_run)

    biom = tmp_path / "feature-table.biom"
    biom.write_text("{}")
    out = tmp_path / "output"

    run_diversity_analysis(biom, out)

    assert len(commands) == 3  # import + alpha + beta
    assert commands[0][:3] == ["qiime", "tools", "import"]
    assert commands[1][:3] == ["qiime", "diversity", "alpha"]
    assert commands[2][:3] == ["qiime", "diversity", "beta"]
```

### 5.4 验证

- `pytest tests/ -v` 全部通过
- 覆盖率提升（目标：超过 55% 阈值，理想 >70%）

---

## Phase 6: 删除死代码 `[x]`

### 6.1 删除 `micos/utils.py` 中的 `load_config()`

删除第 82-107 行的 `load_config()` 函数。保留 `get_full_run_defaults()`（被 `scripts/run_module.sh` 使用）。

### 6.2 删除 `tests/test_utils.py` 中对应测试

删除 `test_load_config_prefers_analysis_yaml` 和 `test_load_config_falls_back_to_legacy_config` 两个测试函数。保留 `test_get_full_run_defaults_merges_analysis_and_databases_config`。

### 6.3 更新 `micos/utils.py` 模块 docstring

移除对 `load_config()` 的提及。

### 6.4 验证

- `pytest tests/test_utils.py -v` 通过
- `grep -r "load_config" micos/ scripts/*.sh` 无结果（scripts/ 中的 `_load_config` 是独立方法，不受影响）

---

## Phase 7: 清理分支触发 `[x]`

### 7.1 修改 `.github/workflows/pages.yml`

```diff
     branches:
-      - main
       - master
```

### 7.2 验证

- `pages.yml` 和 `ci.yml` 都只监听 `master`
- 手动 `workflow_dispatch` 仍可用

---

## 执行顺序与依赖

```
Phase 1 (身份统一) ──→ Phase 2 (英文404)
                              │
Phase 3 (CI docs) ───────────┤
Phase 4 (归档WDL) ───────────┤
Phase 5 (补测试) ────────────┤
Phase 6 (删死代码) ──────────┤
Phase 7 (分支触发) ──────────┘
```

- Phase 1 必须最先执行（归属已确认为 LessUp）
- Phase 2 依赖 Phase 1（docs 文件可能在 Phase 1 中被修改）
- Phase 3-7 互相独立，可并行执行
- 每个 Phase 完成后运行 `pytest tests/ -v` 确认无回归

## 不在本方案范围内

- `scripts/` 独立分析脚本的归属（接入 CLI vs. 独立仓库）——需要维护者决策
- `environment.yml` conda 段 `click`/`pyyaml` 无版本约束——不违反成文策略，优先级极低
- `run_command_live()` 的 Click 解耦——功能正常，重构收益低
- steps/07 补 WDL、steps/08/09 集成——属于功能开发，不是结构修复
