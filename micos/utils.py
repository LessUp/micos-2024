# -*- coding: utf-8 -*-
"""项目通用工具函数。

提供三类兼容且实用的能力：
- 日志初始化：`setup_logging()`
- 命令执行：`run_command_live()`（实时输出并检查返回码）
- 配置兼容层：`load_config()` / `get_full_run_defaults()`

注意：
- 主要配置模型位于 `micos.config` 模块，基于 Pydantic 提供类型安全。
- 这里保留对旧脚本和测试仍然需要的轻量兼容接口。
- 对于需要返回结果或可测试的命令执行，请使用 `micos.tool_runner` 模块。
"""

import logging
from pathlib import Path
import subprocess
import sys
from typing import Any, Optional, Sequence

import click
import yaml

from micos.config import AnalysisConfig, load_databases_config_from_yaml, merge_databases_config


def setup_logging(level: int = logging.INFO, log_file: Optional[str] = None) -> None:
    """配置日志记录。

    Args:
        level: 日志级别
        log_file: 日志文件路径（可选）
    """
    handlers = [logging.StreamHandler(sys.stdout)]
    if log_file:
        handlers.append(logging.FileHandler(log_file))

    logging.basicConfig(
        level=level,
        format='[%(asctime)s] [%(levelname)s] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=handlers,
    )


def run_command_live(command: Sequence[str]) -> None:
    """运行命令并实时打印输出（失败抛出异常）。

    这是一个简化的命令执行函数，适用于需要实时查看输出的场景。
    对于需要返回结果或可测试的场景，请使用 `micos.tool_runner` 模块。

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
        universal_newlines=True,
    )
    if process.stdout:
        for line in iter(process.stdout.readline, ''):
            click.echo(line, nl=False)
        process.stdout.close()

    return_code = process.wait()
    if return_code != 0:
        logger.error(f"命令 {' '.join(command)} 执行失败，返回码: {return_code}")
        raise subprocess.CalledProcessError(return_code, command)


def load_config(config_path: Optional[str] = None) -> dict[str, Any]:
    """加载 YAML 配置，并兼容旧版 `config.yaml` 位置。

    Args:
        config_path: 显式指定的配置文件路径。

    Returns:
        原始配置字典。

    Raises:
        FileNotFoundError: 当找不到任何可用配置文件时抛出。
    """
    candidate_paths: list[Path] = []
    if config_path:
        candidate_paths.append(Path(config_path))
    else:
        candidate_paths.extend([Path('config/analysis.yaml'), Path('config.yaml')])

    for candidate in candidate_paths:
        if candidate.exists():
            with candidate.open('r', encoding='utf-8') as handle:
                return yaml.safe_load(handle) or {}

    raise FileNotFoundError('未找到可用配置文件，预期位置: config/analysis.yaml 或 config.yaml')


def get_full_run_defaults(config_path: Optional[str] = None) -> dict[str, Any]:
    """提取 full-run 命令需要的默认参数。

    Args:
        config_path: 显式指定的分析配置文件路径。

    Returns:
        包含输入目录、结果目录、线程数和数据库路径的字典。
    """
    analysis_path = Path(config_path) if config_path else Path('config/analysis.yaml')
    analysis_config = AnalysisConfig.from_yaml(analysis_path)
    databases_config = load_databases_config_from_yaml(analysis_path.parent / 'databases.yaml')
    merged_db_paths = merge_databases_config(analysis_config, databases_config)

    defaults: dict[str, Any] = {
        'input_dir': str(analysis_config.input_dir) if analysis_config.input_dir else '',
        'results_dir': str(analysis_config.results_dir) if analysis_config.results_dir else '',
        'threads': analysis_config.threads,
        'kneaddata_db': merged_db_paths.get('kneaddata_db', ''),
        'kraken2_db': merged_db_paths.get('kraken2_db', ''),
    }
    return defaults


# 向后兼容别名
run_command = run_command_live
