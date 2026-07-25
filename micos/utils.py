# -*- coding: utf-8 -*-
"""项目通用工具函数。

提供以下能力：
- 日志初始化：`setup_logging()`
- 命令执行：`run_command_live()`（实时输出并检查返回码）
- full-run 默认值提取：`get_full_run_defaults()`（供 shell 包装层调用）

注意：
- 主要配置模型位于 `micos.config` 模块，基于 Pydantic 提供类型安全。
"""

from __future__ import annotations

import logging
import subprocess
import sys
from pathlib import Path
from typing import Any, Sequence

import click

from micos.config import (
    AnalysisConfig,
    load_databases_config_from_yaml,
    merge_databases_config,
)


def setup_logging(level: int = logging.INFO, log_file: str | None = None) -> None:
    """配置日志记录。

    Args:
        level: 日志级别
        log_file: 日志文件路径（可选）
    """
    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stdout)]
    if log_file:
        handlers.append(logging.FileHandler(log_file))

    logging.basicConfig(
        level=level,
        format="[%(asctime)s] [%(levelname)s] - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=handlers,
    )


def run_command_live(command: Sequence[str]) -> None:
    """运行命令并实时打印输出（失败抛出异常）。

    这是一个简化的命令执行函数，适用于需要实时查看输出的场景。

    Args:
        command: 要执行的命令（字符串列表）

    Raises:
        subprocess.CalledProcessError: 命令执行失败时抛出
    """
    logger = logging.getLogger(__name__)
    logger.info(f"执行命令: {' '.join(command)}")
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    if process.stdout:
        for line in iter(process.stdout.readline, ""):
            click.echo(line, nl=False)
        process.stdout.close()

    return_code = process.wait()
    if return_code != 0:
        logger.error(f"命令 {' '.join(command)} 执行失败，返回码: {return_code}")
        raise subprocess.CalledProcessError(return_code, command)


def get_full_run_defaults(config_path: str | None = None) -> dict[str, Any]:
    """提取 full-run 命令需要的默认参数。

    Args:
        config_path: 显式指定的分析配置文件路径。

    Returns:
        包含输入目录、结果目录、线程数和数据库路径的字典。
    """
    analysis_path = Path(config_path) if config_path else Path("config/analysis.yaml")
    analysis_config = AnalysisConfig.from_yaml(analysis_path)
    databases_config = load_databases_config_from_yaml(
        analysis_path.parent / "databases.yaml"
    )
    merged_db_paths = merge_databases_config(analysis_config, databases_config)

    defaults: dict[str, Any] = {
        "input_dir": (
            str(analysis_config.input_dir) if analysis_config.input_dir else ""
        ),
        "results_dir": (
            str(analysis_config.results_dir) if analysis_config.results_dir else ""
        ),
        "threads": analysis_config.threads,
        "kneaddata_db": merged_db_paths.get("kneaddata_db", ""),
        "kraken2_db": merged_db_paths.get("kraken2_db", ""),
    }
    return defaults
