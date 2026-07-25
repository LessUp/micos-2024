# MICOS-2024 结构性问题分析报告

> **用途**：供独立评审模型核验。每条论断附带文件路径 + 行号证据，可直接 `read_file` 验证。
> **分析日期**：2026-07-24
> **分析范围**：GitHub Pages 配置、项目架构、代码结构、CI/CD、文档一致性
> **仓库实际地址**：`https://github.com/LessUp/micos-2024`（`git remote -v` 验证）
> **当前分支**：`master`

---

## 一、GitHub Pages 问题

### 1.1 GitHub 身份不一致（严重性：P0）

**论断**：项目的实际托管身份（`LessUp/micos-2024`，git remote 验证）与多处文档错误引用的组织身份（`BGI-MICOS`）不一致。AGENTS.md 第 11 行错误声明"组织：BGI-MICOS"，但仓库实际托管在 `LessUp` 下，维护者与 BGI 无任何关系。这导致文档中宣称的 Pages URL（`bgi-micos.github.io/MICOS-2024/`）与实际 Pages URL（`lessup.github.io/micos-2024/`）不符。

**归属已确认**：维护者确认 BGI-MICOS 组织不存在，项目归属 `LessUp`。所有 BGI-MICOS 引用均为错误，需统一修正为 LessUp。

**证据**：

实际仓库身份（`git remote -v` 输出）：
```
origin  https://github.com/LessUp/micos-2024.git (fetch)
origin  https://github.com/LessUp/micos-2024.git (push)
```

指向 `BGI-MICOS`（与实际不符）的文件：

| 文件 | 行号 | 内容 |
|------|------|------|
| `pyproject.toml` | 58 | `Documentation = "https://bgi-micos.github.io/MICOS-2024/"` |
| `pyproject.toml` | 11 | `email = "micos-team@bgi-micos.github.io"` |
| `AGENTS.md` | 11 | `\| **组织** \| BGI-MICOS \|`（组织身份声明） |
| `AGENTS.md` | 14 | `https://bgi-micos.github.io/MICOS-2024/` |
| `AGENTS.md` | 97 | `git clone https://github.com/BGI-MICOS/MICOS-2024.git` |
| `CITATION.md` | 11 | `https://github.com/BGI-MICOS/MICOS-2024` |
| `CITATION.md` | 21 | `url = {https://github.com/BGI-MICOS/MICOS-2024}` |
| `CITATION.md` | 30 | `https://github.com/BGI-MICOS/MICOS-2024 (2024)` |
| `CITATION.md` | 110 | `https://github.com/BGI-MICOS/MICOS-2024/issues` |
| `CITATION.md` | 111 | `https://github.com/BGI-MICOS/MICOS-2024/discussions` |
| `CONTRIBUTING.md` | 11 | `https://github.com/BGI-MICOS/MICOS-2024/issues` |
| `CONTRIBUTING.md` | 23 | `git clone https://github.com/BGI-MICOS/MICOS-2024.git` |
| `docs/zh/guides/getting-started.md` | 22 | `git clone https://github.com/BGI-MICOS/MICOS-2024.git` |

指向 `LessUp`（与实际一致）的文件：

| 文件 | 行号 | 内容 |
|------|------|------|
| `pyproject.toml` | 56 | `Homepage = "https://github.com/LessUp/micos-2024"` |
| `pyproject.toml` | 57 | `Repository = "https://github.com/LessUp/micos-2024"` |
| `pyproject.toml` | 59 | `"Bug Tracker" = "https://github.com/LessUp/micos-2024/issues"` |
| `README.md` | 79 | `git clone https://github.com/LessUp/micos-2024.git` |
| `README.md` | 243-244 | Issues / Discussions 链接 |
| `docs/.vitepress/config.ts` | socialLinks | `https://github.com/LessUp/micos-2024` |
| `docs/zh/index.md` | 9 | `https://github.com/LessUp/micos-2024` |

**后果**：
- 实际 Pages URL 应为 `https://lessup.github.io/micos-2024/`
- 文档宣称的 `https://bgi-micos.github.io/MICOS-2024/` 不可达
- 同一文档站内存在矛盾：`docs/zh/index.md` 指向 LessUp，`docs/zh/guides/getting-started.md` 指向 BGI-MICOS
- `pyproject.toml` 作者邮箱 `micos-team@bgi-micos.github.io` 不是可送达地址（GitHub Pages 不提供邮件托管）

### 1.2 Base Path 与宣称 URL 矛盾（严重性：P0 附属）

**论断**：VitePress base path 配置与实际仓库匹配，但与宣称的文档 URL 矛盾。

**证据**：
- `.github/workflows/pages.yml` 第 48 行：`VITEPRESS_BASE: /micos-2024/`（小写）
- 实际仓库名 `micos-2024`（小写）→ base `/micos-2024/` 正确
- 宣称 URL `bgi-micos.github.io/MICOS-2024/` → 需要 base `/MICOS-2024/`（大写）
- 两者不可能同时正确

**判定**：base path 对当前实际仓库是正确的。问题出在宣称 URL 错误（1.1 的衍生）。

### 1.3 幽灵英文站 / 非中文用户 404（严重性：P1）

**论断**：非中文浏览器访问首页会被重定向到不存在的 `/en/` 路径，导致 404。

**证据链**：
1. `docs/index.md` 第 20 行：`window.location.replace(withBase('/${targetLang}/'))`
2. `docs/.vitepress/utils/lang.ts` 第 48-57 行：`detectBrowserLang()` 对非 `zh` 开头的浏览器语言返回 `'en'`
3. `docs/.vitepress/utils/lang.ts` 第 64-65 行：`getTargetLang()` 返回 `getSavedLangPreference() ?? detectBrowserLang()`
4. `glob docs/en/**/*` 返回空——`docs/en/` 目录不存在
5. `docs/.vitepress/config.ts` locales 只定义了 `zh` 一个 locale

**后果**：英文/日文/其他非中文浏览器用户 → 首页 → 自动跳转 `/en/` → 404。

### 1.4 CI 不验证文档构建（严重性：P2）

**论断**：Python CI 和 Pages 部署完全割裂，文档构建错误只在部署时暴露。

**证据**：
- `.github/workflows/ci.yml`：只有 `lint`（Black/isort/Flake8/MyPy）和 `test`（pytest 矩阵）两个 job，无 Node.js/VitePress 相关步骤
- `.github/workflows/pages.yml`：只在 push 到 main/master 且 `docs/**` 变更时触发构建+部署
- 一个破坏 VitePress 构建的 PR 可以通过 CI 合并，然后在 Pages 部署时才失败

### 1.5 分支触发不一致（严重性：P6，微小）

**论断**：两个 workflow 监听的分支不一致。

**证据**：
- `.github/workflows/pages.yml` 第 8-10 行：`branches: [main, master]`
- `.github/workflows/ci.yml`：只监听 `master`
- `git branch` 显示当前分支为 `master`
- `main` 是死配置，无害但增加认知噪音

---

## 二、项目架构问题

### 2.1 遗留 WDL 代码无文档说明（严重性：P3）

**论断**：`workflows/wdl_scripts/` 下 10 个文件（6 个 `.wdl` + 4 个 `.json` 输入模板）与 `steps/` 的关系无任何文档说明。

**证据**：
- `workflows/wdl_scripts/` 包含：`humann3.wdl`、`origin-HUMAnN.wdl`、`meta-dev.wdl`、`meta-dev.json`、`meta-dev-update.wdl`、`meta-dev-update.json`、`version-1/meta-stomics-v1.wdl`、`version-1/meta-stomics-v1.json`、`version-2/meta-stomics-v2.wdl`、`version-2/meta-stomics-v2.json`
- `steps/` 包含 9 个按工具拆分的 WDL 工作流（01-09）
- 无任何 README、注释或文档说明两套 WDL 的关系、哪个是权威版本
- AGENTS.md 的 WDL 表格只列了 `steps/` 下的目录，未提及 `workflows/`

**注意**：`micos/` Python CLI 与 `steps/` WDL 的共存本身是生信领域常见模式（本地编排 vs. HPC 容器化），不是缺陷。问题仅在于遗留 WDL 缺乏状态说明。

### 2.2 已记录的未集成步骤（严重性：低，已知状态）

**论断**：steps/08（MEGAN）和 09（QIIME2 全流程）未集成到主流水线。

**证据**：
- AGENTS.md WDL 表格明确标注"未集成"
- `steps/08_megan_analysis/` 只有 `docker-compose.yaml` 和 `readme.txt`
- `steps/09_qiime2_whole_analysis/` 只有 `docker-compose.yaml` 和 `run.sh`
- `steps/07_phyloseq_analysis/` 有 Dockerfile 但无 WDL 文件

**判定**：这是已记录的已知状态，不是隐藏的架构问题。是否清理是维护者决策。

### 2.3 核心流水线模块无专属单元测试（严重性：P4）

**论断**：5 个流水线模块中 4 个没有专属测试文件，命令行拼装逻辑从未被直接验证。

**证据**：
- `tests/` 目录包含：`test_cli.py`、`test_config.py`、`test_sample.py`、`test_full_run.py`、`test_utils.py`、`test_shell_wrappers.py`、`test_summarize_results.py`、`test_docs_whitepaper.py`
- 无 `test_quality_control.py`、`test_taxonomic_profiling.py`、`test_diversity_analysis.py`、`test_functional_annotation.py`
- `test_full_run.py` 通过 monkeypatch 替换所有阶段函数（`quality_control.run_qc` 等），不执行实际命令拼装
- CI 覆盖率阈值 55%（`.github/workflows/ci.yml`），恰好绕过这个空洞

**上下文**：这 4 个模块是薄封装层（拼装命令行参数 → 调用 `run_command_live()`），每个核心逻辑不超过 100 行。测试价值主要在验证命令行参数拼装正确性（参数顺序、flag 名称、路径传递），而非复杂业务逻辑。

### 2.4 `load_config()` 死代码（严重性：P5）

**论断**：`micos/utils.py` 中的 `load_config()` 在生产代码中无调用者。

**证据**：
- `micos/utils.py` 第 82 行定义 `load_config()`
- grep `load_config` 结果：
  - `micos/utils.py:82`（定义）
  - `tests/test_utils.py:8,11,38,42,53`（测试）
  - `scripts/network_analysis.py:83` 和 `scripts/metatranscriptome_analysis.py:79`（各自有独立的 `_load_config` 方法，与 `utils.load_config` 无关）
- 无任何 `micos/` 模块或 `scripts/*.sh` 调用 `utils.load_config()`

**注意**：同文件的 `get_full_run_defaults()`（第 110 行）被 `scripts/run_module.sh` 第 42-45 行通过内联 Python 调用，是 bash 到 Pydantic 的合理适配层，不是死代码。其内部调用 `AnalysisConfig.from_yaml()` + `merge_databases_config()`，与 CLI 走同一套模型。

### 2.5 `run_command_live()` 耦合 Click（严重性：微小）

**论断**：子进程执行工具函数依赖 Click 库进行输出。

**证据**：
- `micos/utils.py` 第 73 行：`click.echo(line, nl=False)`
- 该函数被 4 个分析模块导入使用（`quality_control.py:16`、`taxonomic_profiling.py:15`、`diversity_analysis.py:15`、`functional_annotation.py:18`）
- `click.echo` 在 Click 命令上下文外也能正常工作（本质是带 Unicode 处理的 print），所以不会导致运行时错误
- 但架构上，一个通用子进程工具不应依赖 CLI 框架

---

## 三、自审中撤回/降级的论断

### 撤回：「Sample 模型不对称」

原始论断声称 `diversity_analysis.py` 不使用 `Sample` dataclass 是架构缺陷。

**撤回原因**：验证 `micos/diversity_analysis.py` 后确认，该模块接收 `input_biom`（聚合后的 BIOM 特征表），是上游 `taxonomic_profiling.py` 中 `kraken-biom` 将多样本 Kraken2 报告聚合后的产物。多样性分析的输入粒度是群落级特征表，不是单样本。不使用 `Sample` 是正确的领域建模。

### 降级：「版本固定策略自相矛盾」→ 微小瑕疵

原始论断声称 AGENTS.md 的"禁止浮动版本号"策略与 `pyproject.toml` 的 `>=` 依赖矛盾。

**降级原因**：AGENTS.md 原文为"所有**生信工具**版本固定"，固定表格只列了 FastQC、Kraken2、KneadData 等生信工具和 Python/R 运行时。`click>=8.0.0`、`numpy>=1.21.0` 等通用库不在策略覆盖范围。`environment.yml` conda 段的生信工具确实全部精确固定。

微小瑕疵：`environment.yml` conda 段中 `click`、`pyyaml` 无版本约束，`pydantic>=2` 浮动——但这些不在 AGENTS.md 固定表格中，未违反成文策略。

### 降级：「双轨执行模型」→ 文档缺失

原始论断将 Python CLI + WDL 工作流的共存定性为"结构性问题"。

**降级原因**：生信领域同时提供本地 CLI 编排器和 WDL/Nextflow 工作流用于 HPC 容器化执行是常见且合理的模式。共存本身不是缺陷。真正的问题是 `workflows/wdl_scripts/` 遗留 WDL 缺乏状态说明（已归入 2.1）。

---

## 四、遗漏补充

1. **`pyproject.toml:11` 作者邮箱不可送达**：`micos-team@bgi-micos.github.io` — GitHub Pages 不提供邮件托管。
2. **文档站内链接自相矛盾**：`docs/zh/index.md:9` 指向 LessUp，`docs/zh/guides/getting-started.md:22` 指向 BGI-MICOS。
3. **`environment.yml` conda 段 `click`、`pyyaml` 无版本约束**：与 `pyproject.toml` 的 `click>=8.0.0`、`pyyaml>=6.0` 存在微妙差异（conda 段无下界）。

---

## 五、验证方法索引

供评审模型快速验证的关键文件：

| 验证目标 | 文件路径 | 关键行号 |
|----------|----------|----------|
| 仓库实际地址 | `git remote -v` | — |
| Pages base path | `.github/workflows/pages.yml` | 48 |
| Pages 分支触发 | `.github/workflows/pages.yml` | 8-10 |
| CI 分支触发 | `.github/workflows/ci.yml` | on.push.branches |
| CI 无 docs job | `.github/workflows/ci.yml` | 全文 |
| 英文重定向逻辑 | `docs/index.md` | 20 |
| 语言检测 | `docs/.vitepress/utils/lang.ts` | 48-57, 64-65 |
| lang.ts 唯一调用者 | `docs/index.md` | 14, 18 |
| 无 en 目录 | `glob docs/en/**/*` | 返回空 |
| VitePress locales | `docs/.vitepress/config.ts` | locales 段 |
| 身份声明 (BGI) | `AGENTS.md` | 11 |
| 身份不一致 (BGI) | `AGENTS.md` | 14, 97 |
| 身份不一致 (BGI) | `pyproject.toml` | 11, 58 |
| 身份不一致 (BGI) | `CITATION.md` | 11, 21, 30, 110, 111 |
| 身份不一致 (BGI) | `CONTRIBUTING.md` | 11, 23 |
| 身份不一致 (BGI) | `docs/zh/guides/getting-started.md` | 22 |
| 身份一致 (LessUp) | `pyproject.toml` | 56, 57, 59 |
| 身份一致 (LessUp) | `README.md` | 79, 243-244 |
| 死代码 load_config | `micos/utils.py` | 82 |
| 适配层 get_full_run_defaults | `micos/utils.py` | 110 |
| shell wrapper 调用 | `scripts/run_module.sh` | 42-45 |
| click.echo 耦合 | `micos/utils.py` | 73 |
| 无模块测试 | `tests/` 目录 | 无 test_quality_control.py 等 |
| 覆盖率阈值 | `.github/workflows/ci.yml` | `--cov-fail-under=55` |
| 版本固定策略 | `AGENTS.md` | "生信工具版本固定" 段 |
| 版本固定实际 | `environment.yml` | conda 段全部精确固定 |
| 遗留 WDL 文件 | `workflows/wdl_scripts/` | 10 个文件（6 .wdl + 4 .json） |
