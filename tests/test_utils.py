# -*- coding: utf-8 -*-
"""测试 utils 模块."""

import yaml

from micos.utils import get_full_run_defaults


def test_get_full_run_defaults_merges_analysis_and_databases_config(tmp_path, monkeypatch):
    """提取 full-run 所需默认值。"""
    config_dir = tmp_path / 'config'
    config_dir.mkdir()

    analysis_config = {
        'paths': {
            'input_dir': 'data/raw_input',
            'output_dir': 'results',
        },
        'resources': {'max_threads': 24},
    }
    databases_config = {
        'quality_control': {
            'kneaddata': {
                'human_genome': '/db/kneaddata/human_genome',
            }
        },
        'taxonomy': {
            'kraken2': {
                'standard': '/db/kraken2/standard',
            }
        },
    }

    (config_dir / 'analysis.yaml').write_text(yaml.safe_dump(analysis_config), encoding='utf-8')
    (config_dir / 'databases.yaml').write_text(yaml.safe_dump(databases_config), encoding='utf-8')

    monkeypatch.chdir(tmp_path)

    defaults = get_full_run_defaults()
    assert defaults == {
        'input_dir': 'data/raw_input',
        'results_dir': 'results',
        'threads': 24,
        'kneaddata_db': '/db/kneaddata/human_genome',
        'kraken2_db': '/db/kraken2/standard',
    }
