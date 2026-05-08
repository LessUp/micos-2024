# -*- coding: utf-8 -*-
"""项目通用工具函数。

提供两类最小且实用的能力：
- 日志初始化：`setup_logging()`
- 命令执行：`run_command_live()`（实时输出并检查返回码）

注意：
- 配置加载功能已迁移到 `micos.config` 模块，使用 Pydantic 模型提供类型安全。
- 对于需要返回结果或可测试的命令执行，请使用 `micos.tool_runner` 模块。
"""

from pathlib import Path
import logging
import subprocess
import sys
from typing import Optional, Sequence

import click


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


# 向后兼容别名
run_command = run_command_live
