# -*- coding: utf-8 -*-
"""测试配置模型模块。"""

from __future__ import annotations

from pathlib import Path

import pytest
import yaml

from micos.config import (
    AnalysisConfig,
    DatabasesConfig,
    merge_databases_config,
    load_databases_config_from_yaml,
    PathsConfig,
    ResourcesConfig,
)


class TestPathsConfig:
    """测试 PathsConfig 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        config = PathsConfig()

        assert config.input_dir is None
        assert config.results_dir is None
        assert config.databases == {}

    def test_from_dict(self) -> None:
        """从字典创建。"""
        config = PathsConfig(
            input_dir=Path("/data/input"),
            output_dir=Path("/data/results"),
            databases={"kraken2": "/db/kraken2"},
        )

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")

    def test_accepts_output_dir_alias(self) -> None:
        """接受 output_dir 别名。"""
        config = PathsConfig(output_dir=Path("/data/results"))

        assert config.results_dir == Path("/data/results")


class TestResourcesConfig:
    """测试 ResourcesConfig 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        config = ResourcesConfig()

        assert config.max_threads == 16
        assert config.memory_gb is None

    def test_custom_values(self) -> None:
        """测试自定义值。"""
        config = ResourcesConfig(max_threads=32, memory_gb=64)

        assert config.max_threads == 32
        assert config.memory_gb == 64


class TestAnalysisConfig:
    """测试 AnalysisConfig 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        config = AnalysisConfig()

        assert config.input_dir is None
        assert config.results_dir is None
        assert config.threads == 16

    def test_new_format_properties(self) -> None:
        """新格式属性访问。"""
        config = AnalysisConfig(
            paths=PathsConfig(
                input_dir=Path("/data/input"),
                output_dir=Path("/data/results"),
            ),
            resources=ResourcesConfig(max_threads=24),
        )

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")
        assert config.threads == 24

    def test_legacy_format_properties(self) -> None:
        """旧格式属性访问。"""
        config = AnalysisConfig(
            INPUT_DIR="/data/input",
            OUTPUT_DIR="/data/results",
            THREADS=32,
        )

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")
        assert config.threads == 32

    def test_new_format_takes_precedence(self) -> None:
        """新格式优先于旧格式。"""
        config = AnalysisConfig(
            paths=PathsConfig(input_dir=Path("/new/input")),
            INPUT_DIR="/old/input",
        )

        assert config.input_dir == Path("/new/input")

    def test_from_dict(self) -> None:
        """从字典创建。"""
        data = {
            "paths": {
                "input_dir": "/data/input",
                "output_dir": "/data/results",
            },
            "resources": {
                "max_threads": 16,
            },
        }

        config = AnalysisConfig.from_dict(data)

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")
        assert config.threads == 16

    def test_from_yaml(self, tmp_path: Path) -> None:
        """从 YAML 文件创建。"""
        yaml_content = """
paths:
  input_dir: /data/input
  output_dir: /data/results
resources:
  max_threads: 16
"""
        yaml_file = tmp_path / "config.yaml"
        yaml_file.write_text(yaml_content, encoding="utf-8")

        config = AnalysisConfig.from_yaml(yaml_file)

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")

    def test_from_yaml_raises_on_missing_file(self, tmp_path: Path) -> None:
        """文件不存在时抛出异常。"""
        with pytest.raises(FileNotFoundError):
            AnalysisConfig.from_yaml(tmp_path / "nonexistent.yaml")

    def test_databases_property(self) -> None:
        """数据库路径属性。"""
        config = AnalysisConfig(
            KNEADDATA_DB="/db/kneaddata",
            KRAKEN2_DB="/db/kraken2",
        )

        assert config.kneaddata_db == Path("/db/kneaddata")
        assert config.kraken2_db == Path("/db/kraken2")

    def test_results_dir_accepts_results_dir_alias(self) -> None:
        """RESULTS_DIR 别名。"""
        config = AnalysisConfig(RESULTS_DIR="/data/results")

        assert config.results_dir == Path("/data/results")


class TestDatabasesConfig:
    """测试 DatabasesConfig 类。"""

    def test_from_dict(self) -> None:
        """从字典创建。"""
        data = {
            "quality_control": {
                "kneaddata": {
                    "human_genome": "/db/kneaddata/human",
                }
            },
            "taxonomy": {
                "kraken2": {
                    "standard": "/db/kraken2/standard",
                }
            }
        }

        config = DatabasesConfig.model_validate(data)

        assert config.quality_control is not None
        assert config.quality_control.kneaddata is not None
        assert config.quality_control.kneaddata.human_genome == "/db/kneaddata/human"


class TestMergeDatabasesConfig:
    """测试 merge_databases_config 函数。"""

    def test_uses_analysis_config_first(self) -> None:
        """优先使用 analysis_config 中的路径。"""
        analysis = AnalysisConfig(
            KNEADDATA_DB="/analysis/kneaddata",
            KRAKEN2_DB="/analysis/kraken2",
        )
        databases = DatabasesConfig(
            quality_control={"kneaddata": {"human_genome": "/db/kneaddata"}},
            taxonomy={"kraken2": {"standard": "/db/kraken2"}},
        )

        result = merge_databases_config(analysis, databases)

        assert result["kneaddata_db"] == "/analysis/kneaddata"
        assert result["kraken2_db"] == "/analysis/kraken2"

    def test_falls_back_to_databases_config(self) -> None:
        """回退到 databases_config。"""
        analysis = AnalysisConfig()
        databases = DatabasesConfig.model_validate({
            "quality_control": {
                "kneaddata": {
                    "human_genome": "/db/kneaddata/human",
                }
            },
            "taxonomy": {
                "kraken2": {
                    "standard": "/db/kraken2/standard",
                }
            }
        })

        result = merge_databases_config(analysis, databases)

        assert result["kneaddata_db"] == "/db/kneaddata/human"
        assert result["kraken2_db"] == "/db/kraken2/standard"

    def test_returns_empty_when_no_config(self) -> None:
        """无配置时返回空字典。"""
        analysis = AnalysisConfig()

        result = merge_databases_config(analysis, None)

        assert result == {}


class TestLoadDatabasesConfigFromYaml:
    """测试 load_databases_config_from_yaml 函数。"""

    def test_loads_valid_yaml(self, tmp_path: Path) -> None:
        """加载有效的 YAML 文件。"""
        yaml_content = """
quality_control:
  kneaddata:
    human_genome: /db/kneaddata/human
taxonomy:
  kraken2:
    standard: /db/kraken2/standard
"""
        yaml_file = tmp_path / "databases.yaml"
        yaml_file.write_text(yaml_content, encoding="utf-8")

        config = load_databases_config_from_yaml(yaml_file)

        assert config.quality_control is not None
        assert config.quality_control.kneaddata is not None
        assert config.quality_control.kneaddata.human_genome == "/db/kneaddata/human"

    def test_returns_empty_on_missing_file(self, tmp_path: Path) -> None:
        """文件不存在时返回空配置。"""
        config = load_databases_config_from_yaml(tmp_path / "nonexistent.yaml")

        assert isinstance(config, DatabasesConfig)
