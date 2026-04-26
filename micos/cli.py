# -*- coding: utf-8 -*-
"""MICOS-2024 命令行界面."""

import logging
import os
import sys
from pathlib import Path

import click
import yaml

from micos.diversity_analysis import run_diversity_analysis
from micos.full_run import run_full_pipeline
from micos.functional_annotation import run_functional_annotation
from micos.quality_control import run_qc
from micos.summarize_results import run_summarize
from micos.taxonomic_profiling import run_taxonomic_profiling
from micos.utils import get_full_run_defaults, load_config, setup_logging

# 默认线程数
DEFAULT_THREADS = 16

# 返回码定义
EXIT_SUCCESS = 0
EXIT_GENERAL_ERROR = 1
EXIT_INVALID_ARGS = 2
EXIT_CONFIG_ERROR = 3
EXIT_MISSING_DEPS = 4
EXIT_DB_ERROR = 5
EXIT_IO_ERROR = 6
EXIT_INTERRUPTED = 130


@click.group()
@click.option('--config', 'config_path', type=click.Path(dir_okay=False), help='指定分析配置文件路径。')
@click.option('--log-file', type=click.Path(dir_okay=False), help='将日志输出到指定文件.')
@click.option('--verbose', is_flag=True, help='启用详细的 DEBUG 级别日志.')
@click.option('--dry-run', is_flag=True, help='仅显示将要执行的命令，不实际运行.')
@click.version_option(version=None, prog_name='MICOS-2024', message='%(prog)s %(version)s')
@click.pass_context
def main(ctx, config_path, log_file, verbose, dry_run):
    """MICOS-2024 命令行界面."""
    log_level = logging.DEBUG if verbose else logging.INFO
    setup_logging(level=log_level, log_file=log_file)
    ctx.ensure_object(dict)
    ctx.obj['config_path'] = config_path
    ctx.obj['dry_run'] = dry_run
    ctx.default_map = ctx.default_map or {}
    ctx.default_map.setdefault('full-run', get_full_run_defaults(config_path))


@main.command('validate-config')
@click.option('--config', 'config_path', type=click.Path(dir_okay=False), help='要验证的配置文件路径.')
@click.pass_context
def validate_config(ctx, config_path):
    """验证配置文件的有效性."""
    logger = logging.getLogger(__name__)
    errors = []
    warnings = []

    # 确定配置文件路径
    config_file = config_path or ctx.obj.get('config_path')
    if not config_file:
        config_file = 'config/analysis.yaml'

    config_path_obj = Path(config_file)

    # 检查文件是否存在
    if not config_path_obj.exists():
        click.secho(f"✗ 配置文件不存在: {config_file}", fg="red")
        sys.exit(EXIT_CONFIG_ERROR)

    # 检查语法
    try:
        config = load_config(config_file)
        click.secho(f"✓ 配置文件语法有效", fg="green")
    except yaml.YAMLError as e:
        click.secho(f"✗ 配置文件语法错误: {e}", fg="red")
        sys.exit(EXIT_CONFIG_ERROR)

    # 检查必需字段
    required_fields = ['paths', 'resources']
    for field in required_fields:
        if field not in config:
            warnings.append(f"缺少推荐字段: {field}")

    # 检查数据库路径
    db_config_path = config_path_obj.parent / 'databases.yaml'
    if db_config_path.exists():
        try:
            with open(db_config_path) as f:
                db_config = yaml.safe_load(f) or {}
            for section, dbs in db_config.items():
                if isinstance(dbs, dict):
                    for name, path in dbs.items():
                        if isinstance(path, str) and path.startswith('/path/to/'):
                            warnings.append(f"数据库路径为占位符: {section}.{name}")
        except Exception as e:
            warnings.append(f"无法读取数据库配置: {e}")
    else:
        warnings.append("数据库配置文件 (databases.yaml) 不存在")

    # 输出结果
    if warnings:
        for warning in warnings:
            click.secho(f"⚠ 警告: {warning}", fg="yellow")

    if not errors:
        click.secho("\n✓ 配置验证完成!", fg="green")
        sys.exit(EXIT_SUCCESS)
    else:
        for error in errors:
            click.secho(f"✗ 错误: {error}", fg="red")
        sys.exit(EXIT_CONFIG_ERROR)


@main.command('full-run')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含原始 FASTQ 文件的输入目录.')
@click.option('--results-dir', required=True, type=click.Path(file_okay=False), help='存放所有分析结果的根目录.')
@click.option('--threads', type=int, default=DEFAULT_THREADS, help=f'使用的线程数 (默认: {DEFAULT_THREADS}).')
@click.option('--kneaddata-db', type=click.Path(exists=True, dir_okay=True), help='KneadData 参考数据库的路径.')
@click.option('--kraken2-db', type=click.Path(exists=True, dir_okay=True), help='Kraken2 参考数据库的路径.')
@click.option('--samples', type=str, help='指定分析的样本列表 (逗号分隔).')
@click.option('--skip-qc', is_flag=True, help='跳过质量控制步骤.')
@click.option('--skip-taxonomy', is_flag=True, help='跳过物种分类步骤.')
@click.option('--skip-functional', is_flag=True, help='跳过功能注释步骤.')
@click.option('--skip-diversity', is_flag=True, help='跳过多样性分析步骤.')
@click.pass_context
def full_run(ctx, input_dir, results_dir, threads, kneaddata_db, kraken2_db,
             samples, skip_qc, skip_taxonomy, skip_functional, skip_diversity):
    """运行完整的 MICOS 分析流程."""
    logger = logging.getLogger(__name__)

    # 检查数据库路径
    if not kneaddata_db and not skip_qc:
        raise click.UsageError(
            '错误: 必须通过命令行参数 --kneaddata-db 或配置文件提供 KneadData 数据库路径。'
        )
    if not kraken2_db and not skip_taxonomy:
        raise click.UsageError(
            '错误: 必须通过命令行参数 --kraken2-db 或配置文件提供 Kraken2 数据库路径。'
        )

    # 解析样本列表
    sample_list = None
    if samples:
        sample_list = [s.strip() for s in samples.split(',')]

    # Dry run 模式
    if ctx.obj.get('dry_run'):
        click.secho("=== Dry Run 模式 ===", fg="cyan")
        click.echo(f"输入目录: {input_dir}")
        click.echo(f"输出目录: {results_dir}")
        click.echo(f"线程数: {threads}")
        click.echo(f"样本列表: {sample_list or '全部'}")
        click.echo(f"跳过步骤: QC={skip_qc}, Taxonomy={skip_taxonomy}, Functional={skip_functional}, Diversity={skip_diversity}")
        click.echo("不执行实际操作。")
        return

    try:
        run_full_pipeline(
            input_dir, results_dir, threads, kneaddata_db, kraken2_db,
            samples=sample_list,
            skip_qc=skip_qc,
            skip_taxonomy=skip_taxonomy,
            skip_functional=skip_functional,
            skip_diversity=skip_diversity
        )
    except Exception as exc:
        click.secho(f"完整分析流程执行失败: {exc}", fg="red")
        raise


@main.group()
def run():
    """运行一个分析模块."""


@run.command('quality-control')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含 FASTQ 文件的输入目录.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放 QC 结果的输出目录.')
@click.option('--threads', default=DEFAULT_THREADS, type=int, help=f'使用的线程数 (默认: {DEFAULT_THREADS}).')
@click.option('--kneaddata-db', required=True, type=click.Path(exists=True, dir_okay=True), help='KneadData 参考数据库的路径.')
@click.pass_context
def quality_control(ctx, input_dir, output_dir, threads, kneaddata_db):
    """运行质量控制 (FastQC + KneadData)."""
    if ctx.obj.get('dry_run'):
        click.secho("=== Dry Run: Quality Control ===", fg="cyan")
        click.echo(f"输入目录: {input_dir}")
        click.echo(f"输出目录: {output_dir}")
        click.echo(f"线程数: {threads}")
        click.echo(f"KneadData 数据库: {kneaddata_db}")
        return

    try:
        run_qc(input_dir, output_dir, threads, kneaddata_db)
    except Exception as exc:
        click.secho(f"质量控制模块执行失败: {exc}", fg="red")
        raise


@run.command('taxonomic-profiling')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含 KneadData 清理后 FASTQ 文件的输入目录.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放物种分类结果的输出目录.')
@click.option('--threads', default=DEFAULT_THREADS, type=int, help=f'使用的线程数 (默认: {DEFAULT_THREADS}).')
@click.option('--kraken2-db', required=True, type=click.Path(exists=True, dir_okay=True), help='Kraken2 参考数据库的路径.')
@click.option('--confidence', type=float, default=0.1, help='Kraken2 分类置信度阈值.')
@click.pass_context
def taxonomic_profiling(ctx, input_dir, output_dir, threads, kraken2_db, confidence):
    """运行物种分类 (Kraken2 + Krona)."""
    if ctx.obj.get('dry_run'):
        click.secho("=== Dry Run: Taxonomic Profiling ===", fg="cyan")
        click.echo(f"输入目录: {input_dir}")
        click.echo(f"输出目录: {output_dir}")
        click.echo(f"线程数: {threads}")
        click.echo(f"Kraken2 数据库: {kraken2_db}")
        click.echo(f"置信度阈值: {confidence}")
        return

    try:
        run_taxonomic_profiling(input_dir, output_dir, threads, kraken2_db)
    except Exception as exc:
        click.secho(f"物种分类模块执行失败: {exc}", fg="red")
        raise


@run.command('diversity-analysis')
@click.option('--input-biom', required=True, type=click.Path(exists=True, dir_okay=False), help='输入的 BIOM 表文件.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放多样性分析结果的输出目录.')
@click.option('--metadata', type=click.Path(exists=True, dir_okay=False), help='样本元数据文件.')
@click.option('--sampling-depth', type=int, help='稀疏采样深度.')
@click.pass_context
def diversity_analysis(ctx, input_biom, output_dir, metadata, sampling_depth):
    """运行多样性分析 (QIIME2)."""
    if ctx.obj.get('dry_run'):
        click.secho("=== Dry Run: Diversity Analysis ===", fg="cyan")
        click.echo(f"输入 BIOM 文件: {input_biom}")
        click.echo(f"输出目录: {output_dir}")
        click.echo(f"元数据文件: {metadata}")
        click.echo(f"采样深度: {sampling_depth}")
        return

    try:
        run_diversity_analysis(input_biom, output_dir)
    except Exception as exc:
        click.secho(f"多样性分析模块执行失败: {exc}", fg="red")
        raise


@run.command('functional-annotation')
@click.option('--input-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含 KneadData 清理后 FASTQ 文件的输入目录.')
@click.option('--output-dir', required=True, type=click.Path(file_okay=False), help='存放功能注释结果的输出目录.')
@click.option('--threads', default=DEFAULT_THREADS, type=int, help=f'使用的线程数 (默认: {DEFAULT_THREADS}).')
@click.pass_context
def functional_annotation(ctx, input_dir, output_dir, threads):
    """运行功能注释 (HUMAnN)."""
    if ctx.obj.get('dry_run'):
        click.secho("=== Dry Run: Functional Annotation ===", fg="cyan")
        click.echo(f"输入目录: {input_dir}")
        click.echo(f"输出目录: {output_dir}")
        click.echo(f"线程数: {threads}")
        return

    try:
        run_functional_annotation(input_dir, output_dir, threads)
    except Exception as exc:
        click.secho(f"功能注释模块执行失败: {exc}", fg="red")
        raise


@run.command('summarize-results')
@click.option('--results-dir', required=True, type=click.Path(exists=True, file_okay=False), help='包含所有分析结果的根目录.')
@click.option('--output-file', required=True, type=click.Path(dir_okay=False), help='输出的 HTML 报告文件路径.')
@click.pass_context
def summarize_results(ctx, results_dir, output_file):
    """汇总所有分析结果并生成 HTML 报告."""
    if ctx.obj.get('dry_run'):
        click.secho("=== Dry Run: Summarize Results ===", fg="cyan")
        click.echo(f"结果目录: {results_dir}")
        click.echo(f"输出文件: {output_file}")
        return

    try:
        run_summarize(results_dir, output_file)
    except Exception as exc:
        click.secho(f"结果汇总模块执行失败: {exc}", fg="red")
        raise


if __name__ == '__main__':
    main()
