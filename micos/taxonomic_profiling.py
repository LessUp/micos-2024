# -*- coding: utf-8 -*-
"""物种分类模块."""

import logging
from pathlib import Path
import glob
from micos.utils import run_command

logger = logging.getLogger(__name__)

def run_taxonomic_profiling(input_dir, output_dir, threads, kraken2_db):
    """执行物种分类 (Kraken2 + Krona)."""
    logger.info("步骤 2: 开始物种分类分析...")

    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # 1. 运行 Kraken2
    logger.info("--> 正在运行 Kraken2...")
    paired_files = sorted(glob.glob(str(input_path / "*_paired_1.fastq")))
    if not paired_files:
        logger.warning("在输入目录中未找到 *_paired_1.fastq 文件，跳过 Kraken2。")
    else:
        for r1_file in paired_files:
            base = Path(r1_file).name.replace("_paired_1.fastq", "")
            r2_file = str(input_path / f"{base}_paired_2.fastq")

            if not Path(r2_file).exists():
                logger.warning(f"找不到配对的 R2 文件 {r2_file}，跳过样本 {base}。")
                continue

            logger.info(f"处理样本: {base}")
            kraken2_output = output_path / f"{base}.kraken"
            kraken2_report = output_path / f"{base}.report"

            kraken2_cmd = [
                "kraken2",
                "--db", kraken2_db,
                "--paired", r1_file, r2_file,
                "--output", str(kraken2_output),
                "--report", str(kraken2_report),
                "--threads", str(threads)
            ]
            run_command(kraken2_cmd)

    # 2. 生成 BIOM 文件
    logger.info("--> 正在生成 BIOM 文件...")
    report_files = glob.glob(str(output_path / "*.report"))
    if report_files:
        biom_output = output_path / "feature-table.biom"
        kraken_biom_cmd = [
            "kraken-biom",
            *report_files,
            "-o", str(biom_output)
        ]
        run_command(kraken_biom_cmd)
    else:
        logger.warning("未找到 Kraken2 报告文件，跳过 BIOM 文件生成。")

    # 3. 生成 Krona 图表
    logger.info("--> 正在生成 Krona 图表...")
    if report_files:
        for report_file in report_files:
            base = Path(report_file).stem
            krona_output = output_path / f"{base}.krona.html"
            ktimport_cmd = [
                "ktImportTaxonomy",
                "-q", "2",
                "-t", "3",
                report_file,
                "-o", str(krona_output)
            ]
            run_command(ktimport_cmd)
    else:
        logger.warning("未找到 Kraken2 报告文件，跳过 Krona 图表生成。")

    logger.info("物种分类分析完成。")
