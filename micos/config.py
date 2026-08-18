# -*- coding: utf-8 -*-
"""配置模型模块。

使用 Pydantic 模型替代字典配置，提供类型验证和 IDE 自动补全。
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, ConfigDict, Field


class PathsConfig(BaseModel):
    """路径配置模型。"""

    model_config = ConfigDict(extra="allow", populate_by_name=True)

    input_dir: Path | None = None
    output_dir: Path | None = None
    databases: dict[str, str] = Field(default_factory=dict)

    @property
    def results_dir(self) -> Path | None:
        """获取结果目录。"""
        return self.output_dir


class ResourcesConfig(BaseModel):
    """资源配置模型。"""

    model_config = ConfigDict(extra="allow")

    max_threads: int = 16
    memory_gb: int | None = None


class DatabasePathConfig(BaseModel):
    """单个数据库路径配置。"""

    model_config = ConfigDict(extra="allow")

    human_genome: str | None = None
    standard: str | None = None


class QCDatabaseConfig(BaseModel):
    """质量控制数据库配置。"""

    model_config = ConfigDict(extra="allow")

    kneaddata: DatabasePathConfig | None = None


class TaxonomyDatabaseConfig(BaseModel):
    """物种分类数据库配置。"""

    model_config = ConfigDict(extra="allow")

    kraken2: DatabasePathConfig | None = None


class DatabasesConfig(BaseModel):
    """数据库配置模型。"""

    model_config = ConfigDict(extra="allow")

    quality_control: QCDatabaseConfig | None = None
    taxonomy: TaxonomyDatabaseConfig | None = None


class AnalysisConfig(BaseModel):
    """分析配置模型。

    这是一个**深层模块**，隐藏了配置加载和验证的复杂性：
    - 调用者只需通过属性访问配置值
    - 多层配置合并、默认值处理等逻辑被隐藏

    Example:
        >>> config = AnalysisConfig.from_yaml("config/analysis.yaml")
        >>> print(config.input_dir)
        >>> print(config.threads)
    """

    model_config = ConfigDict(extra="allow", populate_by_name=True)

    paths: PathsConfig = Field(default_factory=PathsConfig)
    resources: ResourcesConfig = Field(default_factory=ResourcesConfig)

    @property
    def input_dir(self) -> Path | None:
        """获取输入目录。"""
        return self.paths.input_dir

    @property
    def results_dir(self) -> Path | None:
        """获取结果目录。"""
        return self.paths.results_dir

    @property
    def threads(self) -> int:
        """获取线程数。"""
        return self.resources.max_threads

    @property
    def kneaddata_db(self) -> Path | None:
        """获取 KneadData 数据库路径。"""
        if self.paths.databases.get("kneaddata"):
            return Path(self.paths.databases["kneaddata"])
        return None

    @property
    def kraken2_db(self) -> Path | None:
        """获取 Kraken2 数据库路径。"""
        if self.paths.databases.get("kraken2"):
            return Path(self.paths.databases["kraken2"])
        return None

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "AnalysisConfig":
        """从字典创建配置对象。

        Args:
            data: 配置字典

        Returns:
            AnalysisConfig 实例
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
        """
        if not path.exists():
            raise FileNotFoundError(f"配置文件不存在: {path}")

        with path.open("r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}

        return cls.from_dict(data)


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

    # KneadData 数据库
    if analysis_config.kneaddata_db:
        result["kneaddata_db"] = str(analysis_config.kneaddata_db)
    elif databases_config and databases_config.quality_control:
        if databases_config.quality_control.kneaddata:
            db_path = databases_config.quality_control.kneaddata.human_genome
            if db_path:
                result["kneaddata_db"] = db_path

    # Kraken2 数据库
    if analysis_config.kraken2_db:
        result["kraken2_db"] = str(analysis_config.kraken2_db)
    elif databases_config and databases_config.taxonomy:
        if databases_config.taxonomy.kraken2:
            db_path = databases_config.taxonomy.kraken2.standard
            if db_path:
                result["kraken2_db"] = db_path

    return result


def load_databases_config_from_yaml(path: Path) -> DatabasesConfig:
    """从 YAML 文件加载数据库配置。

    Args:
        path: YAML 文件路径

    Returns:
        DatabasesConfig 实例
    """
    if not path.exists():
        return DatabasesConfig()

    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    return DatabasesConfig.model_validate(data)
