# -*- coding: utf-8 -*-
"""多样性分析模块 (QIIME2)."""

import logging
import subprocess
from pathlib import Path
from micos.utils import run_command

logger = logging.getLogger(__name__)

def run_diversity_analysis(input_biom, output_dir):
    """执行多样性分析 (QIIME2)."""
    logger.info("步骤 3: 开始多样性分析...")

    input_biom_path = Path(input_biom)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    if not input_biom_path.exists():
        logger.warning(f"未找到 BIOM 文件: {input_biom}，跳过多样性分析。")
        return

    # 1. 导入数据到 QIIME2
    logger.info("--> 正在导入 BIOM 表到 QIIME2...")
    feature_table_qza = output_path / "feature-table.qza"
    import_cmd = [
        "qiime", "tools", "import",
        "--input-path", str(input_biom_path),
        "--type", "FeatureTable[Frequency]",
        "--output-path", str(feature_table_qza)
    ]
    try:
        run_command(import_cmd)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logger.error(f"QIIME2 BIOM 导入失败: {e}")
        logger.error("请确保 qiime 已安装并位于系统的 PATH 中。")
        raise

    # 2. Alpha 多样性
    logger.info("--> 正在计算 Alpha 多样性 (Shannon)...")
    alpha_div_qza = output_path / "shannon.qza"
    alpha_cmd = [
        "qiime", "diversity", "alpha",
        "--i-table", str(feature_table_qza),
        "--p-metric", "shannon",
        "--o-alpha-diversity", str(alpha_div_qza)
    ]
    try:
        run_command(alpha_cmd)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logger.error(f"QIIME2 Alpha 多样性分析失败: {e}")
        raise

    # 3. Beta 多样性
    logger.info("--> 正在计算 Beta 多样性 (Bray-Curtis)...")
    beta_div_qza = output_path / "bray-curtis.qza"
    beta_cmd = [
        "qiime", "diversity", "beta",
        "--i-table", str(feature_table_qza),
        "--p-metric", "braycurtis",
        "--o-distance-matrix", str(beta_div_qza)
    ]
    try:
        run_command(beta_cmd)
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        logger.error(f"QIIME2 Beta 多样性分析失败: {e}")
        raise

    logger.info("多样性分析完成。")
