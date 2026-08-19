# -*- coding: utf-8 -*-
"""配置模型模块。

使用 Pydantic 模型替代字典配置，提供类型验证和 IDE 自动补全。

配置语义（`enforce-effective-configuration`）：
- 生产配置模型统一 `extra="forbid"`：未知字段立即失败，避免静默忽略；
- 相对路径按所在配置文件目录解析（不依赖进程 CWD）；
- 配置优先级：CLI > analysis.yaml > databases.yaml > 默认值；
- resolved value 来源可追踪（`resolve_full_run_config`）。
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, ConfigDict, Field, PrivateAttr

# 默认线程数（与 cli.py 的默认值保持一致）
DEFAULT_THREADS = 16

# 数据库路径占位符前缀 / 变量插值占位符
_PLACEHOLDER_PREFIX = "/path/to/"
_PLACEHOLDER_PATTERN = re.compile(r"\$\{")


class ConfigError(ValueError):
    """配置加载或校验错误。"""


@dataclass(frozen=True)
class ResolvedValue:
    """解析后的配置值及其来源。

    source 取值：``cli`` / ``analysis.yaml`` / ``databases.yaml`` / ``default``。
    """

    value: Any
    source: str


class PathsConfig(BaseModel):
    """路径配置模型。"""

    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    input_dir: Path | None = None
    output_dir: Path | None = None
    databases: dict[str, str] = Field(default_factory=dict)

    @property
    def results_dir(self) -> Path | None:
        """获取结果目录。"""
        return self.output_dir


class ResourcesConfig(BaseModel):
    """资源配置模型（仅保留已接入 CLI 的字段）。"""

    model_config = ConfigDict(extra="forbid")

    max_threads: int = DEFAULT_THREADS


class DatabasePathConfig(BaseModel):
    """单个数据库路径配置。"""

    model_config = ConfigDict(extra="forbid")

    human_genome: str | None = None
    standard: str | None = None


class QCDatabaseConfig(BaseModel):
    """质量控制数据库配置。"""

    model_config = ConfigDict(extra="forbid")

    kneaddata: DatabasePathConfig | None = None


class TaxonomyDatabaseConfig(BaseModel):
    """物种分类数据库配置。"""

    model_config = ConfigDict(extra="forbid")

    kraken2: DatabasePathConfig | None = None


class DatabasesConfig(BaseModel):
    """数据库配置模型。"""

    model_config = ConfigDict(extra="forbid")

    quality_control: QCDatabaseConfig | None = None
    taxonomy: TaxonomyDatabaseConfig | None = None

    _config_dir: Path | None = PrivateAttr(default=None)

    def resolve_path(self, value: str | None) -> str | None:
        """将相对路径相对本配置文件所在目录解析为绝对路径。

        Args:
            value: 原始路径字符串

        Returns:
            绝对路径字符串；绝对路径或 None 原样返回。
        """
        if value is None:
            return None
        path = Path(value)
        if self._config_dir is not None and not path.is_absolute():
            return str((self._config_dir / path).resolve())
        return value


class AnalysisConfig(BaseModel):
    """分析配置模型。

    这是一个**深层模块**，隐藏了配置加载和验证的复杂性：
    - 调用者只需通过属性访问配置值
    - 多层配置合并、默认值处理等逻辑被隐藏
    - 相对路径相对配置文件所在目录解析

    Example:
        >>> config = AnalysisConfig.from_yaml("config/analysis.yaml")
        >>> print(config.input_dir)
        >>> print(config.threads)
    """

    model_config = ConfigDict(extra="forbid", populate_by_name=True)

    paths: PathsConfig = Field(default_factory=PathsConfig)
    resources: ResourcesConfig = Field(default_factory=ResourcesConfig)

    _config_dir: Path | None = PrivateAttr(default=None)

    def _resolve(self, value: Path | None) -> Path | None:
        """将相对路径相对配置文件所在目录解析为绝对路径。"""
        if value is None:
            return None
        if self._config_dir is not None and not value.is_absolute():
            return (self._config_dir / value).resolve()
        return value

    @property
    def input_dir(self) -> Path | None:
        """获取输入目录（相对路径按配置目录解析）。"""
        return self._resolve(self.paths.input_dir)

    @property
    def results_dir(self) -> Path | None:
        """获取结果目录（相对路径按配置目录解析）。"""
        return self._resolve(self.paths.results_dir)

    @property
    def threads(self) -> int:
        """获取线程数。"""
        return self.resources.max_threads

    @property
    def kneaddata_db(self) -> Path | None:
        """获取 KneadData 数据库路径（相对路径按配置目录解析）。"""
        value = self.paths.databases.get("kneaddata")
        if value:
            return self._resolve(Path(value))
        return None

    @property
    def kraken2_db(self) -> Path | None:
        """获取 Kraken2 数据库路径（相对路径按配置目录解析）。"""
        value = self.paths.databases.get("kraken2")
        if value:
            return self._resolve(Path(value))
        return None

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "AnalysisConfig":
        """从字典创建配置对象。

        Args:
            data: 配置字典

        Returns:
            AnalysisConfig 实例

        Raises:
            ValidationError: 字段未知或类型错误
        """
        return cls.model_validate(data)

    @classmethod
    def from_yaml(cls, path: Path) -> "AnalysisConfig":
        """从 YAML 文件创建配置对象。

        Args:
            path: YAML 文件路径

        Returns:
            AnalysisConfig 实例

        Raises:
            FileNotFoundError: 文件不存在
            ConfigError: 文件为空或顶层不是映射
            yaml.YAMLError: YAML 语法损坏
            ValidationError: 字段未知或类型错误
        """
        if not path.exists():
            raise FileNotFoundError(f"配置文件不存在: {path}")

        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f)

        if data is None:
            raise ConfigError(f"配置文件为空: {path}")
        if not isinstance(data, dict):
            raise ConfigError(f"配置文件顶层必须是键值映射: {path}")

        config = cls.from_dict(data)
        config._config_dir = path.parent.resolve()
        return config


def _resolve_kneaddata_db(
    analysis_config: AnalysisConfig | None,
    databases_config: DatabasesConfig | None,
) -> tuple[str | None, str]:
    """解析 KneadData 数据库路径及其来源。

    Returns:
        (路径, 来源)，来源为 ``analysis.yaml`` / ``databases.yaml`` / ``default``。
    """
    if analysis_config is not None:
        db = analysis_config.kneaddata_db
        if db:
            return str(db), "analysis.yaml"
    if databases_config is not None and databases_config.quality_control is not None:
        kneaddata = databases_config.quality_control.kneaddata
        if kneaddata is not None and kneaddata.human_genome:
            return (
                databases_config.resolve_path(kneaddata.human_genome),
                "databases.yaml",
            )
    return None, "default"


def _resolve_kraken2_db(
    analysis_config: AnalysisConfig | None,
    databases_config: DatabasesConfig | None,
) -> tuple[str | None, str]:
    """解析 Kraken2 数据库路径及其来源。

    Returns:
        (路径, 来源)，来源为 ``analysis.yaml`` / ``databases.yaml`` / ``default``。
    """
    if analysis_config is not None:
        db = analysis_config.kraken2_db
        if db:
            return str(db), "analysis.yaml"
    if databases_config is not None and databases_config.taxonomy is not None:
        kraken2 = databases_config.taxonomy.kraken2
        if kraken2 is not None and kraken2.standard:
            return databases_config.resolve_path(kraken2.standard), "databases.yaml"
    return None, "default"


def merge_databases_config(
    analysis_config: AnalysisConfig,
    databases_config: DatabasesConfig | None = None,
) -> dict[str, str]:
    """合并分析配置和数据库配置，提取完整路径参数。

    Args:
        analysis_config: 分析配置
        databases_config: 数据库配置

    Returns:
        包含 kneaddata_db 和 kraken2_db 的字典
    """
    result: dict[str, str] = {}

    kneaddata, _ = _resolve_kneaddata_db(analysis_config, databases_config)
    if kneaddata:
        result["kneaddata_db"] = kneaddata

    kraken2, _ = _resolve_kraken2_db(analysis_config, databases_config)
    if kraken2:
        result["kraken2_db"] = kraken2

    return result


def load_databases_config_from_yaml(path: Path) -> DatabasesConfig:
    """从 YAML 文件加载数据库配置。

    Args:
        path: YAML 文件路径

    Returns:
        DatabasesConfig 实例

    Raises:
        yaml.YAMLError: YAML 语法损坏
        ValidationError: 字段未知或类型错误
    """
    if not path.exists():
        return DatabasesConfig()

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    config = DatabasesConfig.model_validate(data)
    config._config_dir = path.parent.resolve()
    return config


def resolve_full_run_config(
    config_path: Path,
    cli_values: dict[str, Any] | None = None,
) -> dict[str, ResolvedValue]:
    """按优先级 CLI > analysis.yaml > databases.yaml > 默认 解析 full-run 配置。

    Args:
        config_path: 分析配置文件路径（其同目录下的 databases.yaml 也会被读取）
        cli_values: 用户显式传入的 CLI 值（只读已知键）

    Returns:
        键到 ResolvedValue（value + source）的映射，键为
        ``input_dir`` / ``results_dir`` / ``threads`` / ``kneaddata_db`` /
        ``kraken2_db``。
    """
    cli = cli_values or {}
    analysis_path = Path(config_path)
    analysis: AnalysisConfig | None = (
        AnalysisConfig.from_yaml(analysis_path) if analysis_path.exists() else None
    )
    databases = load_databases_config_from_yaml(analysis_path.parent / "databases.yaml")

    def first(*pairs: tuple[Any, str]) -> ResolvedValue:
        for value, source in pairs:
            if value is not None:
                return ResolvedValue(value, source)
        return ResolvedValue(None, "default")

    resolved: dict[str, ResolvedValue] = {
        "input_dir": first(
            (cli.get("input_dir"), "cli"),
            (
                (
                    str(analysis.input_dir)
                    if analysis is not None and analysis.input_dir
                    else None
                ),
                "analysis.yaml",
            ),
        ),
        "results_dir": first(
            (cli.get("results_dir"), "cli"),
            (
                (
                    str(analysis.results_dir)
                    if analysis is not None and analysis.results_dir
                    else None
                ),
                "analysis.yaml",
            ),
        ),
        "kneaddata_db": first(
            (cli.get("kneaddata_db"), "cli"),
            _resolve_kneaddata_db(analysis, databases),
        ),
        "kraken2_db": first(
            (cli.get("kraken2_db"), "cli"),
            _resolve_kraken2_db(analysis, databases),
        ),
    }

    threads = cli.get("threads")
    if threads is not None:
        resolved["threads"] = ResolvedValue(threads, "cli")
    elif analysis is not None:
        resolved["threads"] = ResolvedValue(analysis.threads, "analysis.yaml")
    else:
        resolved["threads"] = ResolvedValue(DEFAULT_THREADS, "default")

    return resolved
