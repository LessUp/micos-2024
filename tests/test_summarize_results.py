# -*- coding: utf-8 -*-
"""测试结果汇总模块。"""

from pathlib import Path

from micos.summarize_results import generate_summary_report


def test_generate_summary_report_supports_named_layout(tmp_path):
    """支持新的命名目录结构。"""
    results_dir = tmp_path / 'results'
    (results_dir / 'quality_control' / 'fastqc_reports').mkdir(parents=True)
    (results_dir / 'taxonomic_profiling').mkdir(parents=True)
    (results_dir / 'diversity_analysis').mkdir(parents=True)
    (results_dir / 'functional_annotation').mkdir(parents=True)

    (results_dir / 'quality_control' / 'fastqc_reports' / 'sample_fastqc.html').write_text('ok', encoding='utf-8')
    (results_dir / 'taxonomic_profiling' / 'feature-table.biom').write_text('biom', encoding='utf-8')
    (results_dir / 'diversity_analysis' / 'alpha.qza').write_text('qza', encoding='utf-8')
    (results_dir / 'functional_annotation' / 'sample_pathabundance.tsv').write_text('path', encoding='utf-8')

    output_file = tmp_path / 'report' / 'summary.html'
    generate_summary_report(results_dir, output_file)

    html_text = output_file.read_text(encoding='utf-8')
    assert 'quality_control/fastqc_reports/sample_fastqc.html' in html_text
    assert 'taxonomic_profiling/feature-table.biom' in html_text
    assert 'diversity_analysis/alpha.qza' in html_text
    assert 'functional_annotation/sample_pathabundance.tsv' in html_text


def test_generate_summary_report_supports_legacy_numbered_layout(tmp_path):
    """兼容旧的编号目录结构。"""
    results_dir = tmp_path / 'results'
    (results_dir / '1_quality_control' / 'fastqc_reports').mkdir(parents=True)
    (results_dir / '2_taxonomic_profiling').mkdir(parents=True)
    (results_dir / '3_diversity_analysis').mkdir(parents=True)
    (results_dir / '4_functional_annotation').mkdir(parents=True)

    (results_dir / '1_quality_control' / 'fastqc_reports' / 'sample_fastqc.html').write_text('ok', encoding='utf-8')
    (results_dir / '2_taxonomic_profiling' / 'feature-table.biom').write_text('biom', encoding='utf-8')
    (results_dir / '3_diversity_analysis' / 'alpha.qza').write_text('qza', encoding='utf-8')
    (results_dir / '4_functional_annotation' / 'sample_pathcoverage.tsv').write_text('path', encoding='utf-8')

    output_file = tmp_path / 'summary.html'
    generate_summary_report(results_dir, output_file)

    html_text = output_file.read_text(encoding='utf-8')
    assert '1_quality_control/fastqc_reports/sample_fastqc.html' in html_text
    assert '2_taxonomic_profiling/feature-table.biom' in html_text
    assert '3_diversity_analysis/alpha.qza' in html_text
    assert '4_functional_annotation/sample_pathcoverage.tsv' in html_text
