# -*- coding: utf-8 -*-
"""MICOS-2024 命令行界面."""

import click
import logging
from micos.quality_control import run_qc
from micos.taxonomic_profiling import run_taxonomic_profiling
from micos.diversity_analysis import run_diversity_analysis
from micos.full_run import run_full_pipeline
from micos.functional_annotation import run_functional_annotation
from micos.summarize_results import run_summarize
from micos.utils import load_config, setup_logging

@click.group()
@click.option('--log-file', type=click.Path(dir_okay=False), help='将日志输出到指定文件.')
@click.option('--verbose', is_flag=True, help='启用详细的 DEBUG 级别日志.')
def main(log_file, verbose):
    """MICOS-2024 命令行界面."""
    log_level = logging.DEBUG if verbose else logging.INFO
    setup_logging(level=log_level, log_file=log_file)
    pass

@main.command('full-run', context_settings=dict(default_map=load_config()))
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含原始 FASTQ 文件的输入目录.')
@click.option('--results-dir', required=True, type=click.Path(file_okay=False), help='存放所有分析结果的根目录.')
@click.option('--threads', type=int, help='使用的线程数 (默认: 16).')
@click.option('--kneaddata-db', type=click.Path(exists=True, dir_okay=True), help='KneadData 参考数据库的路径.')
@click.option('--kraken2-db', type=click.Path(exists=True, dir_okay=True), help='Kraken2 参考数据库的路径.')
def full_run(input_dir, results_dir, threads, kneaddata_db, kraken2_db):
    """运行完整的 MICOS 分析流程."""
    # 检查必需的数据库路径是否已提供 (通过命令行或配置文件)
    if not kneaddata_db:
        raise click.UsageError("错误: 必须通过命令行参数 --kneaddata-db 或在 config.yaml 中提供 KneadData 数据库路径。")
    if not kraken2_db:
        raise click.UsageError("错误: 必须通过命令行参数 --kraken2-db 或在 config.yaml 中提供 Kraken2 数据库路径。")
    
    # 如果 threads 未提供，则使用默认值
    threads = threads or 16
    try:
        run_full_pipeline(input_dir, results_dir, threads, kneaddata_db, kraken2_db)
    except Exception as e:
        click.secho(f"完整分析流程执行失败: {e}", fg="red")
        raise

@main.group()
def run():
    """运行一个分析模块."""
    pass

@run.command('quality-control')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含 FASTQ 文件的输入目录.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放 QC 结果的输出目录.')
@click.option('--threads', default=16, type=int, help='使用的线程数.')
@click.option('--kneaddata-db', required=True, type=click.Path(exists=True, dir_okay=True), help='KneadData 参考数据库的路径.')
def quality_control(input_dir, output_dir, threads, kneaddata_db):
    """运行质量控制 (FastQC + KneadData)."""
    try:
        run_qc(input_dir, output_dir, threads, kneaddata_db)
    except Exception as e:
        click.secho(f"质量控制模块执行失败: {e}", fg="red")
        raise

@run.command('taxonomic-profiling')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含 KneadData 清理后 FASTQ 文件的输入目录.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放物种分类结果的输出目录.')
@click.option('--threads', default=16, type=int, help='使用的线程数.')
@click.option('--kraken2-db', required=True, type=click.Path(exists=True, dir_okay=True), help='Kraken2 参考数据库的路径.')
def taxonomic_profiling(input_dir, output_dir, threads, kraken2_db):
    """运行物种分类 (Kraken2 + Krona)."""
    try:
        run_taxonomic_profiling(input_dir, output_dir, threads, kraken2_db)
    except Exception as e:
        click.secho(f"物种分类模块执行失败: {e}", fg="red")
        raise

@run.command('diversity-analysis')
@click.option('--input-biom', required=True, type=click.Path(exists=True, dir_okay=False), help='输入的 BIOM 表文件.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放多样性分析结果的输出目录.')
def diversity_analysis(input_biom, output_dir):
    """运行多样性分析 (QIIME2)."""
    try:
        run_diversity_analysis(input_biom, output_dir)
    except Exception as e:
        click.secho(f"多样性分析模块执行失败: {e}", fg="red")
        raise

@run.command('functional-annotation')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含 KneadData 清理后 FASTQ 文件的输入目录.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放功能注释结果的输出目录.')
@click.option('--threads', default=16, type=int, help='使用的线程数.')
def functional_annotation(input_dir, output_dir, threads):
    """运行功能注释 (HUMAnN)."""
    try:
        run_functional_annotation(input_dir, output_dir, threads)
    except Exception as e:
        click.secho(f"功能注释模块执行失败: {e}", fg="red")
        raise

@run.command('summarize-results')
@click.option('--results-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含所有分析结果的根目录.')
@click.option('--output-file', required=True, type=click.Path(dir_okay=False), help='输出的 HTML 报告文件路径.')
def summarize_results(results_dir, output_file):
    """汇总所有分析结果并生成 HTML 报告."""
    try:
        run_summarize(results_dir, output_file)
    except Exception as e:
        click.secho(f"结果汇总模块执行失败: {e}", fg="red")
        raise

if __name__ == '__main__':
    main()
