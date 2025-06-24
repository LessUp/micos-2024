# -*- coding: utf-8 -*-
"""质量控制模块，包含 FastQC 和 KneadData 的功能."""

import subprocess
import logging
from pathlib import Path
import glob
from micos.utils import run_command

logger = logging.getLogger(__name__)

def run_qc(input_dir, output_dir, threads, kneaddata_db):
    """
    执行质量控制 (FastQC + KneadData).
    """
    logger.info("步骤 1: 开始质量控制分析...")
    
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    # 1. 创建输出目录
    fastqc_output_dir = output_path / "fastqc_reports"
    kneaddata_output_dir = output_path / "kneaddata"
    fastqc_output_dir.mkdir(parents=True, exist_ok=True)
    kneaddata_output_dir.mkdir(parents=True, exist_ok=True)
    
    # 2. 运行 FastQC
    logger.info("--> 正在运行 FastQC...")
    fastq_files = glob.glob(str(input_path / "*.fastq.gz"))
    if not fastq_files:
        logger.warning("在输入目录中未找到 .fastq.gz 文件。")
        return

    fastqc_cmd = [
        "fastqc",
        *fastq_files,
        "-o", str(fastqc_output_dir),
        "-t", str(threads)
    ]
    try:
        run_command(fastqc_cmd)
        logger.info("FastQC 运行成功。")
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logger.error(f"FastQC 运行失败: {e}")
        logger.error("请确保 fastqc 已安装并位于系统的 PATH 中。")
        raise
        
    # 3. 运行 KneadData
    logger.info("--> 正在运行 KneadData...")
    r1_files = sorted(glob.glob(str(input_path / "*_R1.fastq.gz")))
    if not r1_files:
        logger.warning("在输入目录中未找到 *_R1.fastq.gz 文件，跳过 KneadData。")
    else:
        for r1_file in r1_files:
            base = Path(r1_file).name.replace("_R1.fastq.gz", "")
            r2_file = str(input_path / f"{base}_R2.fastq.gz")
            
            if not Path(r2_file).exists():
                logger.warning(f"找不到配对的 R2 文件 {r2_file}，跳过样本 {base}。")
                continue
            
            logger.info(f"处理样本: {base}")
            
            kneaddata_cmd = [
                "kneaddata",
                "--input", r1_file,
                "--input", r2_file,
                "--output", str(kneaddata_output_dir),
                "--reference-db", kneaddata_db,
                "--threads", str(threads),
                "--output-prefix", base
            ]
            try:
                run_command(kneaddata_cmd)
            except (subprocess.CalledProcessError, FileNotFoundError) as e:
                logger.error(f"KneadData 运行失败 (样本: {base}): {e}")
                logger.error("请确保 kneaddata 已安装并位于系统的 PATH 中，并且数据库路径正确。")
                raise

    logger.info("质量控制分析完成。")
