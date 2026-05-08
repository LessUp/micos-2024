# -*- coding: utf-8 -*-
"""物种分类模块。

该模块是**深层模块**，隐藏了物种分类的复杂性：
- 调用者只需提供输入目录和配置
- 样本发现、工具调用、结果聚合等逻辑被隐藏
"""

from __future__ import annotations

import logging
import subprocess
from pathlib import Path
from typing import TYPE_CHECKING

from micos.sample import Sample
from micos.utils import run_command_live

if TYPE_CHECKING:
    from micos.tool_runner import ToolRunner

logger = logging.getLogger(__name__)


def run_taxonomic_profiling(
    input_dir: str | Path,
    output_dir: str | Path,
    threads: int,
    kraken2_db: str | Path,
    runner: ToolRunner | None = None,
) -> None:
    """执行物种分类 (Kraken2 + Krona).

    这是一个深层模块的接口，调用者只需提供必要的配置，
    样本发现、工具调用、结果聚合等细节被隐藏。

    Args:
        input_dir: 输入目录（KneadData 清理后的 FASTQ 文件）
        output_dir: 输出目录
        threads: 线程数
        kraken2_db: Kraken2 数据库路径
        runner: 工具执行器（可选，用于测试注入）

    Raises:
        subprocess.CalledProcessError: 工具执行失败时抛出
        FileNotFoundError: 工具未安装时抛出
    """
    logger.info("步骤 2: 开始物种分类分析...")

    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # 1. 使用 Sample 类发现清洗后的样本
    samples = Sample.discover_cleaned(input_path)
    if not samples:
        logger.warning("在输入目录中未找到清洗后的配对样本文件，跳过 Kraken2。")
        return

    # 2. 运行 Kraken2
    logger.info("--> 正在运行 Kraken2...")
    for sample in samples:
        if not sample.is_paired:
            logger.warning(f"样本 {sample.name} 不是双端测序，跳过 Kraken2。")
            continue

        logger.info(f"处理样本: {sample.name}")
        kraken2_output = output_path / f"{sample.name}.kraken"
        kraken2_report = output_path / f"{sample.name}.report"

        kraken2_cmd = [
            "kraken2",
            "--db", str(kraken2_db),
            "--paired", str(sample.r1_path), str(sample.r2_path),
            "--output", str(kraken2_output),
            "--report", str(kraken2_report),
            "--threads", str(threads)
        ]
        run_command_live(kraken2_cmd)

    # 3. 生成 BIOM 文件
    logger.info("--> 正在生成 BIOM 文件...")
    report_files = list(output_path.glob("*.report"))
    if report_files:
        biom_output = output_path / "feature-table.biom"
        kraken_biom_cmd = [
            "kraken-biom",
            *[str(f) for f in report_files],
            "-o", str(biom_output)
        ]
        run_command_live(kraken_biom_cmd)
    else:
        logger.warning("未找到 Kraken2 报告文件，跳过 BIOM 文件生成。")

    # 4. 生成 Krona 图表
    logger.info("--> 正在生成 Krona 图表...")
    if report_files:
        for report_file in report_files:
            base = report_file.stem
            krona_output = output_path / f"{base}.krona.html"
            ktimport_cmd = [
                "ktImportTaxonomy",
                "-q", "2",
                "-t", "3",
                str(report_file),
                "-o", str(krona_output)
            ]
            run_command_live(ktimport_cmd)
    else:
        logger.warning("未找到 Kraken2 报告文件，跳过 Krona 图表生成。")

    logger.info("物种分类分析完成。")
