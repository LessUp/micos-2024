# -*- coding: utf-8 -*-
"""结果汇总模块."""

import subprocess
import logging
from pathlib import Path
import sys
from micos.utils import run_command

logger = logging.getLogger(__name__)

def run_summarize(results_dir, output_file):
    """执行结果汇总，生成 HTML 报告."""
    logger.info("步骤 5: 开始生成总结报告...")

    results_path = Path(results_dir)
    output_path = Path(output_file)

    # 动态定位 summarize_results.py 脚本的路径
    # 假设脚本位于项目根目录下的 scripts/ 文件夹中
    project_root = Path(__file__).parent.parent
    script_path = Path(__file__).parent.parent.parent / "scripts" / "summarize_results.py"

    if not script_path.exists():
        logger.error(f"总结脚本未找到: {script_path}")
        raise FileNotFoundError(f"总结脚本未找到: {script_path}")

    # 使用与当前 micos 包相同的 Python 解释器来运行脚本
    python_executable = sys.executable

    summarize_cmd = [
        python_executable,
        str(script_path),
        "--results_dir", str(results_path),
        "--output_file", str(output_path)
    ]

    try:
        run_command(summarize_cmd)
        logger.info(f"结果报告已生成: {output_path}")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logger.error(f"结果报告生成失败: {e}")
        raise
