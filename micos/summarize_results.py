# -*- coding: utf-8 -*-
"""结果汇总模块。"""

from __future__ import annotations

import argparse
import datetime
import html
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)

SECTION_PATTERNS = {
    "质量控制": [
        "quality_control/fastqc_reports/*.html",
        "quality_control/fastqc_reports/*.zip",
        "quality_control/kneaddata/*_kneaddata*log*",
        "quality_control/kneaddata/*_paired_*.fastq",
        "1_quality_control/fastqc_reports/*.html",
        "1_quality_control/fastqc_reports/*.zip",
        "1_quality_control/kneaddata/*_kneaddata*log*",
        "1_quality_control/kneaddata/*_paired_*.fastq",
    ],
    "物种分类 (Kraken2)": [
        "taxonomic_profiling/*.kraken",
        "taxonomic_profiling/*.report",
        "2_taxonomic_profiling/*.kraken",
        "2_taxonomic_profiling/*.report",
    ],
    "分类可视化 (Krona)": [
        "taxonomic_profiling/*.krona.html",
        "2_taxonomic_profiling/*.krona.html",
    ],
    "BIOM 表": [
        "taxonomic_profiling/feature-table.biom",
        "2_taxonomic_profiling/feature-table.biom",
    ],
    "多样性分析 (QIIME2)": [
        "diversity_analysis/*.qza",
        "diversity_analysis/*.qzv",
        "diversity_analysis/*.txt",
        "3_diversity_analysis/*.qza",
        "3_diversity_analysis/*.qzv",
        "3_diversity_analysis/*.txt",
    ],
    "功能注释 (HUMAnN)": [
        "functional_annotation/*genefamilies*.tsv*",
        "functional_annotation/*pathabundance*.tsv*",
        "functional_annotation/*pathcoverage*.tsv*",
        "functional_annotation/*.log",
        "4_functional_annotation/*genefamilies*.tsv*",
        "4_functional_annotation/*pathabundance*.tsv*",
        "4_functional_annotation/*pathcoverage*.tsv*",
        "4_functional_annotation/*.log",
    ],
}


def find_files(root: Path, patterns: list[str]) -> list[Path]:
    """按模式查找文件并去重。"""
    found: list[Path] = []
    seen: set[Path] = set()
    for pattern in patterns:
        for file_path in sorted(root.glob(pattern)):
            resolved = file_path.resolve()
            if resolved in seen:
                continue
            seen.add(resolved)
            found.append(file_path)
    return found


def render_html(
    title: str,
    results_dir: Path,
    report_dir: Path,
    sections: dict[str, list[Path]],
) -> str:
    """渲染汇总 HTML。"""
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

    for section_name, files in sections.items():
        parts.append(f"<h2>{html.escape(section_name)}（{len(files)}）</h2>")
        if not files:
            parts.append('<p class="empty">未找到相关文件。</p>')
            continue
        parts.append("<ul>")
        for file_path in files:
            if file_path.is_relative_to(report_dir):
                rel = file_path.relative_to(report_dir)
            else:
                try:
                    rel = Path(os.path.relpath(file_path, start=report_dir))
                except ValueError:
                    rel = file_path
            parts.append(
                f'<li><a class="path" href="{html.escape(rel.as_posix())}" target="_blank">'
                f'{html.escape(rel.as_posix())}</a></li>'
            )
        parts.append("</ul>")

    parts.append("</body></html>")
    return "\n".join(parts)


def generate_summary_report(results_dir: Path, output_file: Path) -> None:
    """生成结果汇总 HTML 报告。"""
    output_file.parent.mkdir(parents=True, exist_ok=True)

    if not results_dir.exists():
        raise FileNotFoundError(f"结果目录不存在: {results_dir}")

    sections: dict[str, list[Path]] = {}
    for section_name, patterns in SECTION_PATTERNS.items():
        sections[section_name] = find_files(results_dir, patterns)

    html_text = render_html(
        "MICOS-2024 结果汇总报告",
        results_dir,
        output_file.parent,
        sections,
    )
    output_file.write_text(html_text, encoding="utf-8")


def run_summarize(results_dir: str, output_file: str) -> None:
    """执行结果汇总并生成 HTML 报告。"""
    logger.info("步骤 5: 开始生成总结报告...")
    results_path = Path(results_dir).resolve()
    output_path = Path(output_file).resolve()
    generate_summary_report(results_path, output_path)
    logger.info(f"结果报告已生成: {output_path}")


def main(argv: list[str] | None = None) -> int:
    """命令行入口。"""
    parser = argparse.ArgumentParser(description="生成 MICOS-2024 分析结果的简洁 HTML 汇总报告")
    parser.add_argument("--results_dir", required=True, help="分析结果根目录")
    parser.add_argument("--output_file", required=True, help="输出 HTML 文件路径")
    args = parser.parse_args(argv)

    try:
        generate_summary_report(
            Path(args.results_dir).resolve(),
            Path(args.output_file).resolve(),
        )
    except FileNotFoundError as exc:
        parser.exit(status=2, message=f"错误：{exc}\n")

    print(f"报告已生成：{Path(args.output_file).resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
