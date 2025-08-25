# -*- coding: utf-8 -*-
"""项目通用工具函数（KISS）。

提供三类最小且实用的能力：
- 日志初始化：`setup_logging()`
- 配置加载：`load_config()`（读取项目根目录下的 `config.yaml`，可为空）
- 命令执行：`run_command()`（实时输出并检查返回码）

注意：仅依赖标准库与 `click`/`yaml`，易于在不同环境复用。
"""

import subprocess
import click
import yaml
from pathlib import Path
import logging
import sys
from typing import Optional, Sequence

def setup_logging(level: int = logging.INFO, log_file: Optional[str] = None) -> None:
    """配置日志记录。

参数：
- level: 日志级别，默认 INFO（可传入 `logging.DEBUG` 获取更详细输出）
- log_file: 可选的日志文件路径；若提供，则同时输出到文件与标准输出

设计：
- 使用 `logging.basicConfig` 一次性初始化，避免重复配置
- 输出格式统一，便于排查
"""
    handlers = [logging.StreamHandler(sys.stdout)]
    if log_file:
        handlers.append(logging.FileHandler(log_file))
    
    logging.basicConfig(
        level=level,
        format='[%(asctime)s] [%(levelname)s] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=handlers
    )

def load_config() -> dict:
    """加载项目根目录下的 `config.yaml` 配置。

返回：
- dict: 若存在且解析成功，返回字典；否则返回空字典 `{}`。

行为：
- 当 `config.yaml` 不存在或解析失败时，不中断，仅提示并返回 `{}`。
- 解析使用 `yaml.safe_load`
"""
    config_path = Path.cwd() / "config.yaml"
    if config_path.exists():
        with open(config_path, 'r') as f:
            try:
                return yaml.safe_load(f) or {}
            except yaml.YAMLError as e:
                click.secho(f"警告: 无法解析 config.yaml 文件: {e}", fg="yellow")
                return {}
    return {}

def run_command(command: Sequence[str]) -> None:
    """运行命令并实时打印输出（失败抛出异常）。

参数：
- command: 字符串序列，例如 `["kraken2", "--db", "/path", ...]`

异常：
- subprocess.CalledProcessError: 进程返回码非 0
- FileNotFoundError: 可执行程序不存在

说明：
- 行为与 `subprocess.Popen` 一致，但封装了日志与实时输出
- 返回值为 `None`，失败时抛出异常，便于上层统一处理
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
    # 实时读取输出
    if process.stdout:
        for line in iter(process.stdout.readline, ''):
            click.echo(line, nl=False)
        process.stdout.close()
    
    # 等待命令完成并检查返回码
    return_code = process.wait()
    if return_code != 0:
        logger.error(f"命令 {' '.join(command)} 执行失败，返回码: {return_code}")
        raise subprocess.CalledProcessError(return_code, command)
