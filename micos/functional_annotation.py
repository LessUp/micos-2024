# -*- coding: utf-8 -*-
"""功能注释模块 (HUMAnN)."""

from pathlib import Path
import glob
import gzip
import shutil
import logging
import subprocess
from micos.utils import run_command

logger = logging.getLogger(__name__)

def run_functional_annotation(input_dir, output_dir, threads):
    """执行功能注释 (HUMAnN)."""
    logger.info("步骤 4: 开始功能注释分析...")

    input_path = Path(input_dir)
    output_path = Path(output_dir)
    temp_input_path = output_path / "temp_humann_input"
    temp_input_path.mkdir(parents=True, exist_ok=True)
    output_path.mkdir(parents=True, exist_ok=True)

    # 1. 准备 HUMAnN 的输入文件 (合并所有 reads)
    logger.info("--> 正在准备 HUMAnN 输入文件...")
    paired_files = sorted(glob.glob(str(input_path / "*_paired_1.fastq")))
    if not paired_files:
        logger.warning("警告: 在输入目录中未找到 *_paired_1.fastq 文件，跳过 HUMAnN。")
        return

    for r1_file_str in paired_files:
        r1_file = Path(r1_file_str)
        base = r1_file.name.replace("_paired_1.fastq", "")
        r2_file = r1_file.with_name(f"{base}_paired_2.fastq")
        unmatched1_file = r1_file.with_name(f"{base}_unmatched_1.fastq")
        unmatched2_file = r1_file.with_name(f"{base}_unmatched_2.fastq")
        
        concatenated_file = temp_input_path / f"{base}_concatenated.fastq.gz"
        logger.info(f"合并样本 {base} 的 reads 到 {concatenated_file}")

        files_to_concat = [r1_file, r2_file, unmatched1_file, unmatched2_file]
        with gzip.open(concatenated_file, 'wb') as f_out:
            for f_in_path in files_to_concat:
                if f_in_path.exists():
                    with open(f_in_path, 'rb') as f_in:
                        shutil.copyfileobj(f_in, f_out)

        # 2. 运行 HUMAnN
        logger.info(f"--> 正在为样本 {base} 运行 HUMAnN...")
        humann_cmd = [
            "humann",
            "--input", str(concatenated_file),
            "--output", str(output_path),
            "--threads", str(threads),
            "--output-basename", base
        ]
        try:
            run_command(humann_cmd)
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            logger.error(f"HUMAnN 运行失败: {e}")
            logger.error("请确保 humann 已安装并位于系统的 PATH 中。")
            raise

    # 清理临时文件
    shutil.rmtree(temp_input_path)
    logger.info("功能注释分析完成。")
