# -*- coding: utf-8 -*-
"""测试 utils 模块."""

from pathlib import Path

import yaml

from micos.utils import get_full_run_defaults, load_config


def test_load_config_prefers_analysis_yaml(tmp_path, monkeypatch):
    """优先读取 config/analysis.yaml。"""
    config_dir = tmp_path / 'config'
    config_dir.mkdir()

    analysis_config = {
        'paths': {
            'input_dir': 'data/raw_input',
            'output_dir': 'results',
            'databases': {
                'kneaddata': '/analysis/kneaddata',
                'kraken2': '/analysis/kraken2',
            },
        },
        'resources': {'max_threads': 12},
    }
    legacy_config = {
        'KNEADDATA_DB': '/legacy/kneaddata',
        'KRAKEN2_DB': '/legacy/kraken2',
        'THREADS': 8,
    }

    (config_dir / 'analysis.yaml').write_text(yaml.safe_dump(analysis_config), encoding='utf-8')
    (tmp_path / 'config.yaml').write_text(yaml.safe_dump(legacy_config), encoding='utf-8')

    monkeypatch.chdir(tmp_path)

    config = load_config()
    assert config == analysis_config


def test_load_config_falls_back_to_legacy_config(tmp_path, monkeypatch):
    """兼容读取根目录 config.yaml。"""
    legacy_config = {
        'KNEADDATA_DB': '/test/kneaddata',
        'KRAKEN2_DB': '/test/kraken2',
        'THREADS': 8,
    }
    (tmp_path / 'config.yaml').write_text(yaml.safe_dump(legacy_config), encoding='utf-8')

    monkeypatch.chdir(tmp_path)

    config = load_config()
    assert config['KNEADDATA_DB'] == '/test/kneaddata'
    assert config['KRAKEN2_DB'] == '/test/kraken2'
    assert config['THREADS'] == 8


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
