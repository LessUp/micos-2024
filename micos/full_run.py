# -*- coding: utf-8 -*-
"""完整分析流程的编排模块."""

import logging
from pathlib import Path

from micos.quality_control import run_qc
from micos.taxonomic_profiling import run_taxonomic_profiling
from micos.diversity_analysis import run_diversity_analysis
from micos.functional_annotation import run_functional_annotation
from micos.summarize_results import run_summarize

logger = logging.getLogger(__name__)

def run_full_pipeline(input_dir, results_dir, threads, kneaddata_db, kraken2_db):
    """按顺序执行完整的分析流程."""
    logger.info("MICOS 完整分析流程开始...")
    
    # 定义各步骤的输出目录
    qc_output_dir = Path(results_dir) / "1_quality_control"
    tax_output_dir = Path(results_dir) / "2_taxonomic_profiling"
    div_output_dir = Path(results_dir) / "3_diversity_analysis"

    # --- 步骤 1: 质量控制 ---
    try:
        run_qc(
            input_dir=input_dir, 
            output_dir=str(qc_output_dir), 
            threads=threads, 
            kneaddata_db=kneaddata_db
        )
    except Exception as e:
        logger.error(f"质量控制步骤失败: {e}", exc_info=True)
        raise

    # --- 步骤 2: 物种分类 ---
    # 物种分类的输入是 QC 步骤中 KneadData 的输出
    kneaddata_output = qc_output_dir / "kneaddata"
    try:
        run_taxonomic_profiling(
            input_dir=str(kneaddata_output), 
            output_dir=str(tax_output_dir), 
            threads=threads, 
            kraken2_db=kraken2_db
        )
    except Exception as e:
        logger.error(f"物种分类步骤失败: {e}", exc_info=True)
        raise

    # --- 步骤 3: 多样性分析 ---
    # 多样性分析的输入是物种分类步骤生成的 BIOM 文件
    biom_file = tax_output_dir / "feature-table.biom"
    if not biom_file.exists():
        logger.error(f"错误: 未找到 BIOM 文件 ({biom_file})，无法进行多样性分析。")
        raise FileNotFoundError(f"BIOM file not found: {biom_file}")

    try:
        run_diversity_analysis(
            input_biom=str(biom_file), 
            output_dir=str(div_output_dir)
        )
    except Exception as e:
        logger.error(f"多样性分析步骤失败: {e}", exc_info=True)
        raise

    # --- 步骤 4: 功能注释 ---
    # 功能注释的输入也是 QC 步骤中 KneadData 的输出
    try:
        run_functional_annotation(
            input_dir=str(kneaddata_output), 
            output_dir=str(Path(results_dir) / "4_functional_annotation"), 
            threads=threads
        )
    except Exception as e:
        logger.error(f"功能注释步骤失败: {e}", exc_info=True)
        raise

    # --- 最终步骤: 汇总结果 ---
    try:
        summary_output_file = Path(results_dir) / "micos_summary_report.html"
        run_summarize(
            results_dir=results_dir,
            output_file=str(summary_output_file)
        )
    except Exception as e:
        logger.error(f"结果汇总步骤失败: {e}", exc_info=True)
        raise

    logger.info(f"输入目录: {input_dir}")
    logger.info(f"结果目录: {results_dir}")
    logger.info(f"线程数: {threads}")
    logger.info("MICOS 完整分析流程已成功完成!")
