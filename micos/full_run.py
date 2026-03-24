# -*- coding: utf-8 -*-
"""完整分析流程的编排模块."""

import logging
from pathlib import Path

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


def run_full_pipeline(input_dir, results_dir, threads, kneaddata_db, kraken2_db):
    """按顺序执行完整的分析流程."""
    logger.info("MICOS 完整分析流程开始...")

    results_root = Path(results_dir)
    qc_output_dir = results_root / QUALITY_CONTROL_DIR
    tax_output_dir = results_root / TAXONOMIC_PROFILING_DIR
    div_output_dir = results_root / DIVERSITY_ANALYSIS_DIR
    func_output_dir = results_root / FUNCTIONAL_ANNOTATION_DIR

    try:
        run_qc(
            input_dir=input_dir,
            output_dir=str(qc_output_dir),
            threads=threads,
            kneaddata_db=kneaddata_db,
        )
    except Exception as exc:
        logger.error(f"质量控制步骤失败: {exc}", exc_info=True)
        raise

    kneaddata_output = qc_output_dir / "kneaddata"
    try:
        run_taxonomic_profiling(
            input_dir=str(kneaddata_output),
            output_dir=str(tax_output_dir),
            threads=threads,
            kraken2_db=kraken2_db,
        )
    except Exception as exc:
        logger.error(f"物种分类步骤失败: {exc}", exc_info=True)
        raise

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

    try:
        run_functional_annotation(
            input_dir=str(kneaddata_output),
            output_dir=str(func_output_dir),
            threads=threads,
        )
    except Exception as exc:
        logger.error(f"功能注释步骤失败: {exc}", exc_info=True)
        raise

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
