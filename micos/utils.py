# -*- coding: utf-8 -*-
"""项目范围内的通用辅助函数."""

import subprocess
import click
import yaml
from pathlib import Path
import logging
import sys

def setup_logging(level=logging.INFO, log_file=None):
    """配置日志记录."""
    handlers = [logging.StreamHandler(sys.stdout)]
    if log_file:
        handlers.append(logging.FileHandler(log_file))
    
    logging.basicConfig(
        level=level,
        format='[%(asctime)s] [%(levelname)s] - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        handlers=handlers
    )

def load_config():
    """加载根目录下的 config.yaml 文件."""
    config_path = Path.cwd() / "config.yaml"
    if config_path.exists():
        with open(config_path, 'r') as f:
            try:
                return yaml.safe_load(f) or {}
            except yaml.YAMLError as e:
                click.secho(f"警告: 无法解析 config.yaml 文件: {e}", fg="yellow")
                return {}
    return {}

def run_command(command):
    """运行一个 shell 命令并实时打印输出."""
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
