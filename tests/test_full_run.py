# -*- coding: utf-8 -*-
"""测试完整流程编排模块。"""

from pathlib import Path

from micos import full_run


def test_run_full_pipeline_uses_named_output_layout(tmp_path, monkeypatch):
    """full-run 应输出到新的命名目录。"""
    calls = []

    def fake_run_qc(input_dir, output_dir, threads, kneaddata_db, metadata_path=None):
        calls.append(('qc', input_dir, output_dir, threads, kneaddata_db, metadata_path))
        kneaddata_dir = Path(output_dir) / 'kneaddata'
        kneaddata_dir.mkdir(parents=True, exist_ok=True)
        (kneaddata_dir / 'sample_paired_1.fastq').write_text('r1', encoding='utf-8')
        (kneaddata_dir / 'sample_paired_2.fastq').write_text('r2', encoding='utf-8')

    def fake_run_taxonomic_profiling(input_dir, output_dir, threads, kraken2_db, confidence=0.1, metadata_path=None):
        calls.append(('tax', input_dir, output_dir, threads, kraken2_db, metadata_path))
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        (output_path / 'feature-table.biom').write_text('biom', encoding='utf-8')

    def fake_run_diversity_analysis(input_biom, output_dir):
        calls.append(('div', input_biom, output_dir))

    def fake_run_functional_annotation(input_dir, output_dir, threads, metadata_path=None):
        calls.append(('func', input_dir, output_dir, threads, metadata_path))

    def fake_run_summarize(results_dir, output_file):
        calls.append(('summary', results_dir, output_file))

    monkeypatch.setattr(full_run, 'run_qc', fake_run_qc)
    monkeypatch.setattr(full_run, 'run_taxonomic_profiling', fake_run_taxonomic_profiling)
    monkeypatch.setattr(full_run, 'run_diversity_analysis', fake_run_diversity_analysis)
    monkeypatch.setattr(full_run, 'run_functional_annotation', fake_run_functional_annotation)
    monkeypatch.setattr(full_run, 'run_summarize', fake_run_summarize)

    results_dir = tmp_path / 'results'
    full_run.run_full_pipeline(
        input_dir=str(tmp_path / 'input'),
        results_dir=str(results_dir),
        threads=16,
        kneaddata_db='/db/kneaddata',
        kraken2_db='/db/kraken2',
    )

    assert calls == [
        ('qc', str(tmp_path / 'input'), str(results_dir / 'quality_control'), 16, '/db/kneaddata', None),
        ('tax', str(results_dir / 'quality_control' / 'kneaddata'), str(results_dir / 'taxonomic_profiling'), 16, '/db/kraken2', None),
        ('div', str(results_dir / 'taxonomic_profiling' / 'feature-table.biom'), str(results_dir / 'diversity_analysis')),
        ('func', str(results_dir / 'quality_control' / 'kneaddata'), str(results_dir / 'functional_annotation'), 16, None),
        ('summary', str(results_dir), str(results_dir / 'micos_summary_report.html')),
    ]


def test_run_full_pipeline_passes_metadata_path(tmp_path, monkeypatch):
    """full-run 应将 metadata_path 传递给各模块。"""
    captured = {}

    def fake_run_qc(input_dir, output_dir, threads, kneaddata_db, metadata_path=None):
        captured['qc_metadata'] = metadata_path
        kneaddata_dir = Path(output_dir) / 'kneaddata'
        kneaddata_dir.mkdir(parents=True, exist_ok=True)
        (kneaddata_dir / 'sample_paired_1.fastq').write_text('r1', encoding='utf-8')
        (kneaddata_dir / 'sample_paired_2.fastq').write_text('r2', encoding='utf-8')

    def fake_run_taxonomic_profiling(input_dir, output_dir, threads, kraken2_db, confidence=0.1, metadata_path=None):
        captured['tax_metadata'] = metadata_path
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        (output_path / 'feature-table.biom').write_text('biom', encoding='utf-8')

    def fake_run_diversity_analysis(input_biom, output_dir):
        pass

    def fake_run_functional_annotation(input_dir, output_dir, threads, metadata_path=None):
        captured['func_metadata'] = metadata_path

    def fake_run_summarize(results_dir, output_file):
        pass

    monkeypatch.setattr(full_run, 'run_qc', fake_run_qc)
    monkeypatch.setattr(full_run, 'run_taxonomic_profiling', fake_run_taxonomic_profiling)
    monkeypatch.setattr(full_run, 'run_diversity_analysis', fake_run_diversity_analysis)
    monkeypatch.setattr(full_run, 'run_functional_annotation', fake_run_functional_annotation)
    monkeypatch.setattr(full_run, 'run_summarize', fake_run_summarize)

    results_dir = tmp_path / 'results'
    full_run.run_full_pipeline(
        input_dir=str(tmp_path / 'input'),
        results_dir=str(results_dir),
        threads=4,
        kneaddata_db='/db/kneaddata',
        kraken2_db='/db/kraken2',
        metadata_path='config/samples.tsv',
    )

    assert captured['qc_metadata'] == 'config/samples.tsv'
    assert captured['tax_metadata'] == 'config/samples.tsv'
    assert captured['func_metadata'] == 'config/samples.tsv'
