# -*- coding: utf-8 -*-
"""测试 CLI 默认配置行为。"""

from pathlib import Path

import yaml
from click.testing import CliRunner

from micos.cli import main


def test_full_run_uses_config_defaults(tmp_path, monkeypatch):
    """full-run 从标准配置文件提取默认参数。"""
    config_dir = tmp_path / 'config'
    config_dir.mkdir()
    input_dir = tmp_path / 'data' / 'raw_input'
    input_dir.mkdir(parents=True)
    results_dir = tmp_path / 'results'
    kneaddata_db = tmp_path / 'db' / 'kneaddata'
    kraken2_db = tmp_path / 'db' / 'kraken2'
    kneaddata_db.mkdir(parents=True)
    kraken2_db.mkdir(parents=True)

    analysis_config = {
        'paths': {
            'input_dir': str(input_dir),
            'output_dir': str(results_dir),
        },
        'resources': {'max_threads': 6},
    }
    databases_config = {
        'quality_control': {'kneaddata': {'human_genome': str(kneaddata_db)}},
        'taxonomy': {'kraken2': {'standard': str(kraken2_db)}},
    }

    (config_dir / 'analysis.yaml').write_text(yaml.safe_dump(analysis_config), encoding='utf-8')
    (config_dir / 'databases.yaml').write_text(yaml.safe_dump(databases_config), encoding='utf-8')

    captured = {}

    def fake_run_full_pipeline(input_dir_arg, results_dir_arg, threads, kneaddata_db_arg, kraken2_db_arg):
        captured.update(
            {
                'input_dir': input_dir_arg,
                'results_dir': results_dir_arg,
                'threads': threads,
                'kneaddata_db': kneaddata_db_arg,
                'kraken2_db': kraken2_db_arg,
            }
        )

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr('micos.cli.run_full_pipeline', fake_run_full_pipeline)

    runner = CliRunner()
    result = runner.invoke(main, ['full-run'])

    assert result.exit_code == 0, result.output
    assert captured == {
        'input_dir': str(input_dir),
        'results_dir': str(results_dir),
        'threads': 6,
        'kneaddata_db': str(kneaddata_db),
        'kraken2_db': str(kraken2_db),
    }
