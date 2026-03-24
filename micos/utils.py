# -*- coding: utf-8 -*-
"""项目通用工具函数（KISS）。

提供三类最小且实用的能力：
- 日志初始化：`setup_logging()`
- 配置加载：`load_config()`（优先读取 `config/analysis.yaml`，兼容 `config.yaml`）
- 命令执行：`run_command()`（实时输出并检查返回码）
"""

from pathlib import Path
import logging
import subprocess
import sys
from typing import Any, Optional, Sequence

import click
import yaml

CONFIG_CANDIDATES = (
    Path("config") / "analysis.yaml",
    Path("config.yaml"),
)
DATABASES_CONFIG_PATH = Path("config") / "databases.yaml"


def setup_logging(level: int = logging.INFO, log_file: Optional[str] = None) -> None:
    """配置日志记录。"""
    handlers = [logging.StreamHandler(sys.stdout)]
    if log_file:
        handlers.append(logging.FileHandler(log_file))

    logging.basicConfig(
        level=level,
        format='[%(asctime)s] [%(levelname)s] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=handlers,
    )


def _read_yaml_file(config_path: Path) -> dict[str, Any]:
    with config_path.open('r', encoding='utf-8') as handle:
        try:
            return yaml.safe_load(handle) or {}
        except yaml.YAMLError as exc:
            click.secho(f"警告: 无法解析配置文件 {config_path}: {exc}", fg="yellow")
            return {}


def load_config(config_path: Optional[str] = None) -> dict[str, Any]:
    """加载分析配置。

    优先读取 `config/analysis.yaml`，如不存在则兼容读取旧的 `config.yaml`。
    """
    if config_path:
        candidate = Path(config_path)
        return _read_yaml_file(candidate) if candidate.exists() else {}

    for candidate in CONFIG_CANDIDATES:
        resolved = Path.cwd() / candidate
        if resolved.exists():
            return _read_yaml_file(resolved)
    return {}


def load_databases_config(config_path: Optional[str] = None) -> dict[str, Any]:
    """加载数据库配置文件。"""
    candidates: list[Path] = []
    if config_path:
        analysis_path = Path(config_path)
        if analysis_path.name == 'analysis.yaml':
            candidates.append(analysis_path.with_name('databases.yaml'))
    candidates.append(Path.cwd() / DATABASES_CONFIG_PATH)

    for candidate in candidates:
        if candidate.exists():
            return _read_yaml_file(candidate)
    return {}


def _nested_get(data: dict[str, Any], *keys: str) -> Any:
    current: Any = data
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return None
        current = current[key]
    return current


def _first_value(*values: Any) -> Any:
    for value in values:
        if value not in (None, ""):
            return value
    return None


def get_full_run_defaults(config_path: Optional[str] = None) -> dict[str, Any]:
    """提取 full-run 命令使用的默认参数。"""
    config = load_config(config_path)
    databases_config = load_databases_config(config_path)

    defaults = {
        'input_dir': _first_value(
            config.get('INPUT_DIR'),
            _nested_get(config, 'paths', 'input_dir'),
        ),
        'results_dir': _first_value(
            config.get('RESULTS_DIR'),
            config.get('OUTPUT_DIR'),
            _nested_get(config, 'paths', 'output_dir'),
        ),
        'threads': _first_value(
            config.get('THREADS'),
            _nested_get(config, 'resources', 'max_threads'),
        ),
        'kneaddata_db': _first_value(
            config.get('KNEADDATA_DB'),
            _nested_get(config, 'paths', 'databases', 'kneaddata'),
            _nested_get(databases_config, 'quality_control', 'kneaddata', 'human_genome'),
        ),
        'kraken2_db': _first_value(
            config.get('KRAKEN2_DB'),
            _nested_get(config, 'paths', 'databases', 'kraken2'),
            _nested_get(databases_config, 'taxonomy', 'kraken2', 'standard'),
        ),
    }
    return {key: value for key, value in defaults.items() if value not in (None, '')}


def run_command(command: Sequence[str]) -> None:
    """运行命令并实时打印输出（失败抛出异常）。"""
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
