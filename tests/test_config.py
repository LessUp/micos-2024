# -*- coding: utf-8 -*-
"""测试配置模型模块。"""

from __future__ import annotations

from pathlib import Path

import pytest
import yaml
from pydantic import ValidationError

from micos.config import (
    AnalysisConfig,
    ConfigError,
    DatabasesConfig,
    PathsConfig,
    ResourcesConfig,
    load_databases_config_from_yaml,
    merge_databases_config,
    resolve_full_run_config,
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

    def test_custom_values(self) -> None:
        """测试自定义值。"""
        config = ResourcesConfig(max_threads=32)

        assert config.max_threads == 32

    def test_rejects_unimplemented_memory_gb_field(self) -> None:
        """未实现的 memory_gb 漂移字段应被拒绝（extra=forbid）。"""
        with pytest.raises(ValidationError):
            ResourcesConfig(max_threads=32, memory_gb=64)


class TestAnalysisConfig:
    """测试 AnalysisConfig 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        config = AnalysisConfig()

        assert config.input_dir is None
        assert config.results_dir is None
        assert config.threads == 16

    def test_properties(self) -> None:
        """属性访问。"""
        config = AnalysisConfig(
            paths=PathsConfig(
                input_dir=Path("/data/input"),
                output_dir=Path("/data/results"),
                databases={
                    "kneaddata": "/db/kneaddata",
                    "kraken2": "/db/kraken2",
                },
            ),
            resources=ResourcesConfig(max_threads=24),
        )

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")
        assert config.threads == 24
        assert config.kneaddata_db == Path("/db/kneaddata")
        assert config.kraken2_db == Path("/db/kraken2")

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
            },
        }

        config = DatabasesConfig.model_validate(data)

        assert config.quality_control is not None
        assert config.quality_control.kneaddata is not None
        assert config.quality_control.kneaddata.human_genome == "/db/kneaddata/human"


class TestMergeDatabasesConfig:
    """测试 merge_databases_config 函数。"""

    def test_uses_analysis_config_paths_first(self) -> None:
        """优先使用 analysis_config.paths.databases 中的路径。"""
        analysis = AnalysisConfig(
            paths=PathsConfig(
                databases={
                    "kneaddata": "/analysis/kneaddata",
                    "kraken2": "/analysis/kraken2",
                },
            ),
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
        databases = DatabasesConfig.model_validate(
            {
                "quality_control": {
                    "kneaddata": {
                        "human_genome": "/db/kneaddata/human",
                    }
                },
                "taxonomy": {
                    "kraken2": {
                        "standard": "/db/kraken2/standard",
                    }
                },
            }
        )

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


class TestStrictValidation:
    """测试 extra=forbid 的严格配置校验。"""

    def test_rejects_unknown_top_level_field(self) -> None:
        """未知顶层字段应被拒绝。"""
        with pytest.raises(ValidationError):
            AnalysisConfig.from_dict({"paths": {}, "typo_field": 1})

    def test_rejects_unknown_paths_field(self) -> None:
        """未知 paths 字段应被拒绝。"""
        with pytest.raises(ValidationError):
            AnalysisConfig.from_dict(
                {"paths": {"input_dir": "/data/input", "typo_dir": "/tmp"}}
            )

    def test_rejects_wrong_field_type(self) -> None:
        """错误类型应被拒绝。"""
        with pytest.raises(ValidationError):
            AnalysisConfig.from_dict({"resources": {"max_threads": "not-an-int"}})

    def test_rejects_unknown_resources_field(self) -> None:
        """未知 resources 字段（如 max_memory）应被拒绝。"""
        with pytest.raises(ValidationError):
            AnalysisConfig.from_dict({"resources": {"max_memory": "32GB"}})

    def test_rejects_unknown_database_field(self) -> None:
        """未知数据库字段应被拒绝。"""
        with pytest.raises(ValidationError):
            DatabasesConfig.model_validate(
                {
                    "quality_control": {
                        "kneaddata": {"human_genome": "/db", "mouse_genome": "/db2"}
                    }
                }
            )

    def test_from_yaml_empty_raises(self, tmp_path: Path) -> None:
        """空 YAML 应作为配置错误抛出。"""
        yaml_file = tmp_path / "empty.yaml"
        yaml_file.write_text("# 只有注释\n", encoding="utf-8")

        with pytest.raises(ConfigError):
            AnalysisConfig.from_yaml(yaml_file)

    def test_from_yaml_corrupted_raises(self, tmp_path: Path) -> None:
        """损坏的 YAML 应抛出 YAMLError。"""
        yaml_file = tmp_path / "broken.yaml"
        yaml_file.write_text("paths:\n  input_dir: [unclosed\n", encoding="utf-8")

        with pytest.raises(yaml.YAMLError):
            AnalysisConfig.from_yaml(yaml_file)


class TestRelativePathResolution:
    """测试相对路径按所在配置文件目录解析。"""

    def _write_analysis(self, tmp_path: Path, content: str) -> Path:
        config_dir = tmp_path / "config"
        config_dir.mkdir(parents=True, exist_ok=True)
        yaml_file = config_dir / "analysis.yaml"
        yaml_file.write_text(content, encoding="utf-8")
        return yaml_file

    def test_relative_input_and_results_resolve_against_config_dir(
        self, tmp_path: Path
    ) -> None:
        """相对 input_dir/output_dir 相对分析配置文件所在目录解析。"""
        yaml_file = self._write_analysis(
            tmp_path,
            "paths:\n"
            "  input_dir: data/raw_input\n"
            "  output_dir: results\n"
            "resources:\n"
            "  max_threads: 8\n",
        )

        config = AnalysisConfig.from_yaml(yaml_file)

        assert (
            config.input_dir == (tmp_path / "config" / "data" / "raw_input").resolve()
        )
        assert config.results_dir == (tmp_path / "config" / "results").resolve()

    def test_absolute_paths_unchanged(self, tmp_path: Path) -> None:
        """绝对路径保持不变。"""
        yaml_file = self._write_analysis(
            tmp_path,
            "paths:\n" "  input_dir: /data/input\n" "  output_dir: /data/results\n",
        )

        config = AnalysisConfig.from_yaml(yaml_file)

        assert config.input_dir == Path("/data/input")
        assert config.results_dir == Path("/data/results")

    def test_database_paths_resolve_against_databases_yaml_dir(
        self, tmp_path: Path
    ) -> None:
        """databases.yaml 中的相对数据库路径相对该文件所在目录解析。"""
        config_dir = tmp_path / "config"
        config_dir.mkdir(parents=True)
        db_file = config_dir / "databases.yaml"
        db_file.write_text(
            "quality_control:\n"
            "  kneaddata:\n"
            "    human_genome: db/kneaddata\n"
            "taxonomy:\n"
            "  kraken2:\n"
            "    standard: db/kraken2\n",
            encoding="utf-8",
        )

        db_config = load_databases_config_from_yaml(db_file)
        analysis = AnalysisConfig()
        merged = merge_databases_config(analysis, db_config)

        assert merged["kneaddata_db"] == str(
            (tmp_path / "config" / "db" / "kneaddata").resolve()
        )
        assert merged["kraken2_db"] == str(
            (tmp_path / "config" / "db" / "kraken2").resolve()
        )


class TestConfigPriority:
    """测试配置优先级：CLI > analysis.yaml > databases.yaml > 默认。"""

    def _write_configs(
        self, tmp_path: Path, analysis: dict, databases: dict | None = None
    ) -> Path:
        config_dir = tmp_path / "config"
        config_dir.mkdir(parents=True, exist_ok=True)
        analysis_path = config_dir / "analysis.yaml"
        analysis_path.write_text(yaml.safe_dump(analysis), encoding="utf-8")
        if databases is not None:
            (config_dir / "databases.yaml").write_text(
                yaml.safe_dump(databases), encoding="utf-8"
            )
        return analysis_path

    def test_cli_overrides_analysis(self, tmp_path: Path) -> None:
        """CLI 值优先于 analysis.yaml。"""
        analysis_path = self._write_configs(
            tmp_path,
            {
                "paths": {
                    "input_dir": "data/raw_input",
                    "output_dir": "results",
                },
                "resources": {"max_threads": 8},
            },
        )

        resolved = resolve_full_run_config(
            analysis_path,
            cli_values={"threads": 32, "input_dir": "/cli/input"},
        )

        assert resolved["threads"].value == 32
        assert resolved["threads"].source == "cli"
        assert resolved["input_dir"].value == "/cli/input"
        assert resolved["input_dir"].source == "cli"

    def test_analysis_overrides_databases_for_db_paths(self, tmp_path: Path) -> None:
        """analysis.yaml 的数据库路径优先于 databases.yaml（来源冲突）。"""
        analysis_path = self._write_configs(
            tmp_path,
            {
                "paths": {
                    "input_dir": "data/raw_input",
                    "output_dir": "results",
                    "databases": {
                        "kneaddata": "/analysis/kneaddata",
                        "kraken2": "/analysis/kraken2",
                    },
                },
            },
            databases={
                "quality_control": {"kneaddata": {"human_genome": "/db/kneaddata"}},
                "taxonomy": {"kraken2": {"standard": "/db/kraken2"}},
            },
        )

        resolved = resolve_full_run_config(analysis_path)

        assert resolved["kneaddata_db"].value == "/analysis/kneaddata"
        assert resolved["kneaddata_db"].source == "analysis.yaml"
        assert resolved["kraken2_db"].value == "/analysis/kraken2"
        assert resolved["kraken2_db"].source == "analysis.yaml"

    def test_databases_yaml_fills_when_analysis_lacks_db(self, tmp_path: Path) -> None:
        """analysis.yaml 未配置数据库时回退到 databases.yaml。"""
        analysis_path = self._write_configs(
            tmp_path,
            {"paths": {"input_dir": "data/raw_input", "output_dir": "results"}},
            databases={
                "quality_control": {"kneaddata": {"human_genome": "/db/kneaddata"}},
                "taxonomy": {"kraken2": {"standard": "/db/kraken2"}},
            },
        )

        resolved = resolve_full_run_config(analysis_path)

        assert resolved["kneaddata_db"].value == "/db/kneaddata"
        assert resolved["kneaddata_db"].source == "databases.yaml"
        assert resolved["kraken2_db"].value == "/db/kraken2"
        assert resolved["kraken2_db"].source == "databases.yaml"

    def test_defaults_when_no_config(self, tmp_path: Path) -> None:
        """无配置文件时返回默认值，来源为 default。"""
        analysis_path = tmp_path / "config" / "analysis.yaml"

        resolved = resolve_full_run_config(analysis_path)

        assert resolved["input_dir"].value is None
        assert resolved["input_dir"].source == "default"
        assert resolved["threads"].value == 16
        assert resolved["threads"].source == "default"
