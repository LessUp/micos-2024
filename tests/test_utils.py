# -*- coding: utf-8 -*- 
"""测试 utils 模块."""

import yaml
from pathlib import Path
from micos.utils import load_config
import pytest

def test_load_config(tmp_path, monkeypatch):
    """测试 load_config 函数."""
    config_data = {
        'KNEADDATA_DB': '/test/kneaddata',
        'KRAKEN2_DB': '/test/kraken2',
        'THREADS': 8
    }
    config_file = tmp_path / "config.yaml"
    with open(config_file, 'w') as f:
        yaml.dump(config_data, f)

    # 切换当前工作目录到临时目录
    monkeypatch.chdir(tmp_path)

    config = load_config()
    assert config['KNEADDATA_DB'] == '/test/kneaddata'
    assert config['KRAKEN2_DB'] == '/test/kraken2'
    assert config['THREADS'] == 8
