# 功能注释（HUMAnN）

本文档介绍 MICOS-2024 中的功能注释模块，基于 HUMAnN 完成基因家族与通路层面的功能分析。

- 工具：HUMAnN（Humann 3.x）
- 上游输入：清理后的 reads（来自 KneadData 输出）
- 下游输出：样本级 genefamilies/pathabundance/pathcoverage 等表格

---

## 1. 功能概览（What & Why）

- 目标：将宏基因组测序 reads 映射到参考数据库，量化功能基因与通路丰度。
- 价值：
  - 补充分类学结果之外的“功能层面”信息。
  - 支持后续差异分析与通路富集。

---

## 2. 输入与输出（I/O）

- 输入目录：`results/1_quality_control/kneaddata/`
  - 期望文件模式：`*_paired_1.fastq`、`*_paired_2.fastq` 及 `*_unmatched_*.fastq`
- 输出目录：`results/4_functional_annotation/`
  - 主要产物（每个样本一组）：
    - `*_genefamilies.tsv[.gz]`：基因家族丰度
    - `*_pathabundance.tsv[.gz]`：通路丰度
    - `*_pathcoverage.tsv[.gz]`：通路覆盖
    - `*.log`：运行日志

说明：MICOS 在运行 HUMAnN 前，会对每个样本的多份 reads 进行合并（gzip 压缩），以减少 IO 与调用开销。

---

## 3. 运行方式

你可以通过两种方式运行功能注释：

### 方式 A：通过 MICOS CLI

```bash
python -m micos.cli run functional-annotation \
  --input-dir results/1_quality_control/kneaddata \
  --output-dir results/4_functional_annotation \
  --threads 16
```

参数说明：
- `--input-dir`：KneadData 输出目录
- `--output-dir`：HUMAnN 结果输出目录
- `--threads`：线程数（建议与 CPU 内核匹配）

### 方式 B：完整流程一键运行

```bash
python -m micos.cli full-run \
  --input-dir data/raw_input \
  --results-dir results \
  --threads 16 \
  --kneaddata-db /path/to/kneaddata_db \
  --kraken2-db /path/to/kraken2_db
```

完整流程将依次执行：质量控制 → 物种分类 → 多样性分析 → 功能注释 → 汇总报告。

---

## 4. 依赖与准备（Prerequisites）

- HUMAnN 已正确安装并在 PATH 中可用（`humann --version`）
- 参考数据库已准备（例如 ChocoPhlAn、UniRef/UniRef90 等）。
- 建议使用 Conda/Docker 统一环境，避免依赖冲突。

---

## 5. 结果解释（Interpretation）

- `genefamilies`：描述功能基因家族（如 UniRef90）层面的丰度。
- `pathabundance`：通路丰度，通常用于下游富集与差异分析。
- `pathcoverage`：反映通路是否被完整覆盖，辅助质量评估。

常见操作：
- 合并多样本表格、标准化（如 CPM/TPM）、对数变换、可视化（热图/箱线图）。

---

## 6. 常见问题（FAQ）

- 找不到输入文件
  - 确认上游 KneadData 是否成功；检查 `*_paired_1.fastq` 文件是否存在。
- HUMAnN 报错 `command not found`
  - 确认 `humann` 已安装且在 PATH 中；或在 Conda/Docker 环境内运行。
- 运行缓慢或内存不足
  - 降低并发线程；将中间文件目录放置在高速磁盘；裁剪数据进行测试。

---

## 7. 与项目其他模块的关系

- 上游依赖：`quality_control`（KneadData 输出）
- 并行关系：可与分类可视化（Krona）并行，但通常建议先完成分类与 BIOM 生成。
- 下游输出：可接入差异分析、通路富集与报告汇总。

---

## 8. 参考

- HUMAnN：https://github.com/biobakery/humann
- KneadData：https://github.com/biobakery/kneaddata
- Kraken2：https://ccb.jhu.edu/software/kraken2/

---

## 9. 与汇总报告联动

功能注释完成后，可生成简洁 HTML 汇总报告，便于快速浏览各阶段产物。

- 通过 CLI 生成：

```bash
python -m micos.cli run summarize-results \
  --results-dir results \
  --output-file results/report.html
```

- 或直接调用脚本：

```bash
python scripts/summarize_results.py \
  --results_dir results \
  --output_file results/report.html
```

说明：
- 报告中的链接相对于报告文件所在目录生成（跨盘符无法生成相对路径时会回退为绝对路径）。
- 报告会扫描常见产出（FastQC/KneadData、Kraken2/Krona、BIOM、QIIME2、HUMAnN 等）。

---

## 10. 输出目录结构示例

以下为典型的结果目录结构（示意）：

```
results/
  1_quality_control/
    fastqc_reports/
      sampleA_fastqc.html
    kneaddata/
      sampleA_paired_1.fastq
      sampleA_paired_2.fastq
  2_taxonomic_profiling/
    sampleA.kraken
    sampleA.report
    sampleA.krona.html
    feature-table.biom
  3_diversity_analysis/
    alpha_diversity.qzv
    beta_diversity.qzv
  4_functional_annotation/
    sampleA_genefamilies.tsv.gz
    sampleA_pathabundance.tsv.gz
    sampleA_pathcoverage.tsv.gz
    sampleA.log
  report.html
