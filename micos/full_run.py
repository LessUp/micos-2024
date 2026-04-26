# -*- coding: utf-8 -*-
"""完整分析流程的编排模块."""

import logging
from pathlib import Path
from typing import List, Optional

from micos.diversity_analysis import run_diversity_analysis
from micos.functional_annotation import run_functional_annotation
from micos.quality_control import run_qc
from micos.summarize_results import run_summarize
from micos.taxonomic_profiling import run_taxonomic_profiling

logger = logging.getLogger(__name__)

QUALITY_CONTROL_DIR = "quality_control"
TAXONOMIC_PROFILING_DIR = "taxonomic_profiling"
DIVERSITY_ANALYSIS_DIR = "diversity_analysis"
FUNCTIONAL_ANNOTATION_DIR = "functional_annotation"
SUMMARY_REPORT_NAME = "micos_summary_report.html"


def run_full_pipeline(
    input_dir: str,
    results_dir: str,
    threads: int,
    kneaddata_db: str,
    kraken2_db: str,
    samples: Optional[List[str]] = None,
    skip_qc: bool = False,
    skip_taxonomy: bool = False,
    skip_functional: bool = False,
    skip_diversity: bool = False,
) -> None:
    """按顺序执行完整的分析流程.

    Args:
        input_dir: 输入 FASTQ 文件目录
        results_dir: 结果输出目录
        threads: 线程数
        kneaddata_db: KneadData 数据库路径
        kraken2_db: Kraken2 数据库路径
        samples: 指定分析的样本列表（可选）
        skip_qc: 跳过质量控制步骤
        skip_taxonomy: 跳过物种分类步骤
        skip_functional: 跳过功能注释步骤
        skip_diversity: 跳过多样性分析步骤
    """
    logger.info("MICOS 完整分析流程开始...")

    if samples:
        logger.info(f"指定样本列表: {samples}")

    results_root = Path(results_dir)
    qc_output_dir = results_root / QUALITY_CONTROL_DIR
    tax_output_dir = results_root / TAXONOMIC_PROFILING_DIR
    div_output_dir = results_root / DIVERSITY_ANALYSIS_DIR
    func_output_dir = results_root / FUNCTIONAL_ANNOTATION_DIR

    kneaddata_output = qc_output_dir / "kneaddata"

    # 步骤1: 质量控制
    if not skip_qc:
        try:
            run_qc(
                input_dir=input_dir,
                output_dir=str(qc_output_dir),
                threads=threads,
                kneaddata_db=kneaddata_db,
                samples=samples,
            )
        except Exception as exc:
            logger.error(f"质量控制步骤失败: {exc}", exc_info=True)
            raise
    else:
        logger.info("跳过质量控制步骤")

    # 步骤2: 物种分类
    if not skip_taxonomy:
        try:
            run_taxonomic_profiling(
                input_dir=str(kneaddata_output),
                output_dir=str(tax_output_dir),
                threads=threads,
                kraken2_db=kraken2_db,
                samples=samples,
            )
        except Exception as exc:
            logger.error(f"物种分类步骤失败: {exc}", exc_info=True)
            raise
    else:
        logger.info("跳过物种分类步骤")

    # 步骤3: 多样性分析
    if not skip_diversity:
        biom_file = tax_output_dir / "feature-table.biom"
        if not biom_file.exists():
            logger.error(f"错误: 未找到 BIOM 文件 ({biom_file})，无法进行多样性分析。")
            raise FileNotFoundError(f"BIOM file not found: {biom_file}")

        try:
            run_diversity_analysis(
                input_biom=str(biom_file),
                output_dir=str(div_output_dir),
            )
        except Exception as exc:
            logger.error(f"多样性分析步骤失败: {exc}", exc_info=True)
            raise
    else:
        logger.info("跳过多样性分析步骤")

    # 步骤4: 功能注释
    if not skip_functional:
        try:
            run_functional_annotation(
                input_dir=str(kneaddata_output),
                output_dir=str(func_output_dir),
                threads=threads,
                samples=samples,
            )
        except Exception as exc:
            logger.error(f"功能注释步骤失败: {exc}", exc_info=True)
            raise
    else:
        logger.info("跳过功能注释步骤")

    # 步骤5: 结果汇总
    try:
        summary_output_file = results_root / SUMMARY_REPORT_NAME
        run_summarize(
            results_dir=str(results_root),
            output_file=str(summary_output_file),
        )
    except Exception as exc:
        logger.error(f"结果汇总步骤失败: {exc}", exc_info=True)
        raise

    logger.info(f"输入目录: {input_dir}")
    logger.info(f"结果目录: {results_dir}")
    logger.info(f"线程数: {threads}")
    logger.info("MICOS 完整分析流程已成功完成!")
