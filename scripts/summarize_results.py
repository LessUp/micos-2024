# -*- coding: utf-8 -*-
"""
汇总结果脚本（供 micos.summarize_results.run_summarize 调用）

功能：
- 扫描结果目录，收集关键输出（FastQC/KneadData、Kraken2/Krona、BIOM、QIIME2、HUMAnN 等）。
- 生成一个简洁的 HTML 报告，包含链接与文件数量统计。

用法：
python scripts/summarize_results.py --results_dir <结果根目录> --output_file <输出HTML路径>
"""

from __future__ import annotations
import argparse
from pathlib import Path
import datetime
import html
import sys
import os

SECTION_PATTERNS = {
    "质量控制": [
        "1_quality_control/fastqc_reports/*.html",
        "1_quality_control/fastqc_reports/*.zip",
        "1_quality_control/kneaddata/*_kneaddata*log*",
        "1_quality_control/kneaddata/*_paired_*.fastq",
    ],
    "物种分类 (Kraken2)": [
        "2_taxonomic_profiling/*.kraken",
        "2_taxonomic_profiling/*.report",
    ],
    "分类可视化 (Krona)": [
        "2_taxonomic_profiling/*.krona.html",
    ],
    "BIOM 表": [
        "2_taxonomic_profiling/feature-table.biom",
    ],
    "多样性分析 (QIIME2)": [
        "3_diversity_analysis/*.qza",
        "3_diversity_analysis/*.qzv",
        "3_diversity_analysis/*.txt",
    ],
    "功能注释 (HUMAnN)": [
        "4_functional_annotation/*genefamilies*.tsv*",
        "4_functional_annotation/*pathabundance*.tsv*",
        "4_functional_annotation/*pathcoverage*.tsv*",
        "4_functional_annotation/*.log",
    ],
}


def find_files(root: Path, patterns: list[str]) -> list[Path]:
    found = []
    for pat in patterns:
        found.extend(sorted(root.glob(pat)))
    return found


def render_html(title: str, results_dir: Path, report_dir: Path, sections: dict[str, list[Path]]) -> str:
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    head = f"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{html.escape(title)}</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', 'PingFang SC', 'Microsoft Yahei', sans-serif; margin: 24px; color: #333; }}
    h1 {{ font-size: 22px; }}
    h2 {{ font-size: 18px; margin-top: 24px; }}
    .meta {{ color: #666; font-size: 12px; margin-bottom: 16px; }}
    .empty {{ color: #999; }}
    ul {{ line-height: 1.6; }}
    code {{ background: #f6f8fa; padding: 2px 6px; border-radius: 4px; }}
    .path {{ color: #0366d6; text-decoration: none; }}
  </style>
</head>
<body>
<h1>{html.escape(title)}</h1>
<div class="meta">生成时间：{now} ｜ 结果目录：<code>{html.escape(str(results_dir))}</code></div>
"""
    parts = [head]

    for sec, files in sections.items():
        parts.append(f"<h2>{html.escape(sec)}（{len(files)}）</h2>")
        if not files:
            parts.append('<p class="empty">未找到相关文件。</p>')
            continue
        parts.append("<ul>")
        for f in files:
            # 建立相对路径展示
            if f.is_relative_to(report_dir):
                rel = f.relative_to(report_dir)
            else:
                try:
                    rel = Path(os.path.relpath(f, start=report_dir))
                except ValueError:
                    # Windows 跨盘符等情况，退回到绝对路径
                    rel = f
            parts.append(f'<li><a class="path" href="{html.escape(rel.as_posix())}" target="_blank">{html.escape(rel.as_posix())}</a></li>')
        parts.append("</ul>")

    parts.append("</body></html>")
    return "\n".join(parts)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="生成 MICOS-2024 分析结果的简洁 HTML 汇总报告")
    parser.add_argument("--results_dir", required=True, help="分析结果根目录")
    parser.add_argument("--output_file", required=True, help="输出 HTML 文件路径")
    args = parser.parse_args(argv)

    results_dir = Path(args.results_dir).resolve()
    output_file = Path(args.output_file).resolve()
    output_file.parent.mkdir(parents=True, exist_ok=True)

    if not results_dir.exists():
        print(f"错误：结果目录不存在：{results_dir}", file=sys.stderr)
        return 2

    sections: dict[str, list[Path]] = {}
    for sec, patterns in SECTION_PATTERNS.items():
        sections[sec] = find_files(results_dir, patterns)

    html_text = render_html("MICOS-2024 结果汇总报告", results_dir, output_file.parent, sections)
    output_file.write_text(html_text, encoding="utf-8")
    print(f"报告已生成：{output_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
