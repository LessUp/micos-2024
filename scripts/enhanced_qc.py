#!/usr/bin/env python3
"""
MICOS-2024 增强质量控制模块
Enhanced Quality Control Module

该模块提供增强的质量控制功能，包括：
- 高级序列质量评估
- 多样本质量比较
- 自适应质量过滤
- 质量控制可视化
- 批量处理优化

作者: MICOS-2024 团队
版本: 1.0.0
"""

import os
import sys
import argparse
import logging
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import subprocess
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import yaml
from Bio import SeqIO
from Bio.SeqUtils import GC
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import warnings
warnings.filterwarnings('ignore')

class EnhancedQualityControl:
    """增强质量控制分析类"""

    def __init__(self, config_file: str = None, output_dir: str = "results/enhanced_qc"):
        """
        初始化增强质量控制分析

        Args:
            config_file: 配置文件路径
            output_dir: 输出目录
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # 设置日志
        self.setup_logging()

        # 加载配置
        self.config = self.load_config(config_file)

        # 初始化结果存储
        self.qc_results = {}
        self.sample_stats = {}

        self.logger.info("增强质量控制模块初始化完成")

    def setup_logging(self):
        """设置日志系统"""
        log_file = self.output_dir / "enhanced_qc.log"
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)

    def load_config(self, config_file: str) -> Dict:
        """加载配置文件"""
        default_config = {
            'quality_thresholds': {
                'min_quality': 20,
                'min_length': 50,
                'max_n_content': 0.1,
                'min_gc_content': 0.2,
                'max_gc_content': 0.8
            },
            'fastqc': {
                'threads': 4,
                'memory': '2G'
            },
            'multiqc': {
                'enabled': True,
                'config_file': None
            },
            'advanced_metrics': {
                'calculate_complexity': True,
                'detect_adapters': True,
                'estimate_insert_size': True
            },
            'visualization': {
                'plot_format': ['png', 'svg'],
                'dpi': 300,
                'interactive_plots': True
            }
        }

        if config_file and os.path.exists(config_file):
            with open(config_file, 'r', encoding='utf-8') as f:
                user_config = yaml.safe_load(f)
                default_config.update(user_config.get('enhanced_qc', {}))

        return default_config

    def run_fastqc_analysis(self, input_files: List[str], threads: int = 4) -> Dict:
        """
        运行FastQC分析

        Args:
            input_files: 输入文件列表
            threads: 线程数

        Returns:
            FastQC结果字典
        """
        self.logger.info("开始运行FastQC分析...")

        fastqc_dir = self.output_dir / "fastqc_reports"
        fastqc_dir.mkdir(exist_ok=True)

        # 运行FastQC
        cmd = [
            "fastqc",
            "--outdir", str(fastqc_dir),
            "--threads", str(threads),
            "--extract"
        ] + input_files

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            self.logger.info("FastQC分析完成")

            # 解析FastQC结果
            fastqc_results = self.parse_fastqc_results(fastqc_dir)
            return fastqc_results

        except subprocess.CalledProcessError as e:
            self.logger.error(f"FastQC运行失败: {e}")
            return {}

    def parse_fastqc_results(self, fastqc_dir: Path) -> Dict:
        """解析FastQC结果"""
        results = {}

        for fastqc_file in fastqc_dir.glob("*_fastqc"):
            if fastqc_file.is_dir():
                sample_name = fastqc_file.name.replace("_fastqc", "")

                # 解析fastqc_data.txt
                data_file = fastqc_file / "fastqc_data.txt"
                if data_file.exists():
                    results[sample_name] = self.parse_fastqc_data(data_file)

        return results

    def parse_fastqc_data(self, data_file: Path) -> Dict:
        """解析单个FastQC数据文件"""
        data = {}
        current_section = None

        with open(data_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith(">>"):
                    if line.endswith("END_MODULE"):
                        current_section = None
                    else:
                        current_section = line[2:].split('\t')[0]
                        data[current_section] = []
                elif current_section and not line.startswith("#"):
                    data[current_section].append(line.split('\t'))

        return data

    def calculate_sequence_complexity(self, sequence: str) -> float:
        """计算序列复杂度"""
        if len(sequence) < 4:
            return 0.0

        # 计算4-mer多样性
        kmers = {}
        for i in range(len(sequence) - 3):
            kmer = sequence[i:i+4]
            kmers[kmer] = kmers.get(kmer, 0) + 1

        # 计算Shannon熵
        total = sum(kmers.values())
        entropy = 0
        for count in kmers.values():
            p = count / total
            entropy -= p * np.log2(p)

        # 标准化到0-1范围
        max_entropy = np.log2(min(4**4, total))
        return entropy / max_entropy if max_entropy > 0 else 0

    def analyze_sequence_file(self, file_path: str) -> Dict:
        """分析单个序列文件"""
        stats = {
            'total_sequences': 0,
            'total_bases': 0,
            'gc_content': [],
            'sequence_lengths': [],
            'quality_scores': [],
            'complexity_scores': [],
            'n_content': []
        }

        file_format = 'fastq' if file_path.endswith(('.fastq', '.fq', '.fastq.gz', '.fq.gz')) else 'fasta'

        try:
            if file_path.endswith('.gz'):
                import gzip
                handle = gzip.open(file_path, 'rt')
            else:
                handle = open(file_path, 'r')

            for record in SeqIO.parse(handle, file_format):
                stats['total_sequences'] += 1
                seq_str = str(record.seq)
                stats['total_bases'] += len(seq_str)
                stats['sequence_lengths'].append(len(seq_str))
                stats['gc_content'].append(GC(seq_str))
                stats['complexity_scores'].append(self.calculate_sequence_complexity(seq_str))
                stats['n_content'].append(seq_str.count('N') / len(seq_str) if len(seq_str) > 0 else 0)

                if hasattr(record, 'letter_annotations') and 'phred_quality' in record.letter_annotations:
                    stats['quality_scores'].extend(record.letter_annotations['phred_quality'])

            handle.close()

        except Exception as e:
            self.logger.error(f"分析文件 {file_path} 时出错: {e}")

        return stats

    def run_enhanced_analysis(self, input_files: List[str]) -> Dict:
        """运行增强质量控制分析"""
        self.logger.info("开始增强质量控制分析...")

        results = {}

        # 并行分析文件
        with ThreadPoolExecutor(max_workers=4) as executor:
            future_to_file = {
                executor.submit(self.analyze_sequence_file, file_path): file_path
                for file_path in input_files
            }

            for future in as_completed(future_to_file):
                file_path = future_to_file[future]
                try:
                    stats = future.result()
                    sample_name = Path(file_path).stem.replace('.fastq', '').replace('.fq', '')
                    results[sample_name] = stats
                    self.logger.info(f"完成分析: {sample_name}")
                except Exception as e:
                    self.logger.error(f"分析文件 {file_path} 失败: {e}")

        return results

    def create_summary_table(self, analysis_results: Dict, report_dir: Path):
        """创建汇总统计表格"""
        summary_data = []

        for sample_name, stats in analysis_results.items():
            summary_data.append({
                'Sample': sample_name,
                'Total_Sequences': stats['total_sequences'],
                'Total_Bases': stats['total_bases'],
                'Mean_Length': np.mean(stats['sequence_lengths']) if stats['sequence_lengths'] else 0,
                'Mean_GC_Content': np.mean(stats['gc_content']) if stats['gc_content'] else 0,
                'Mean_Quality': np.mean(stats['quality_scores']) if stats['quality_scores'] else 0,
                'Mean_Complexity': np.mean(stats['complexity_scores']) if stats['complexity_scores'] else 0,
                'Mean_N_Content': np.mean(stats['n_content']) if stats['n_content'] else 0
            })

        df = pd.DataFrame(summary_data)
        df.to_csv(report_dir / "quality_summary.csv", index=False)
        return df

    def create_quality_plots(self, analysis_results: Dict, report_dir: Path):
        """创建质量控制可视化图表"""
        # 设置绘图样式
        plt.style.use('seaborn-v0_8')
        sns.set_palette("husl")

        # 创建图表目录
        plots_dir = report_dir / "plots"
        plots_dir.mkdir(exist_ok=True)

        # 1. GC含量分布图
        self.plot_gc_distribution(analysis_results, plots_dir)

        # 2. 序列长度分布图
        self.plot_length_distribution(analysis_results, plots_dir)

        # 3. 质量分数分布图
        self.plot_quality_distribution(analysis_results, plots_dir)

        # 4. 复杂度分析图
        self.plot_complexity_analysis(analysis_results, plots_dir)

        # 5. 样本比较热图
        self.plot_sample_comparison(analysis_results, plots_dir)

    def plot_gc_distribution(self, analysis_results: Dict, plots_dir: Path):
        """绘制GC含量分布图"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('GC Content Analysis', fontsize=16, fontweight='bold')

        # 收集所有GC数据
        all_gc_data = []
        sample_names = []

        for sample_name, stats in analysis_results.items():
            if stats['gc_content']:
                all_gc_data.extend(stats['gc_content'])
                sample_names.extend([sample_name] * len(stats['gc_content']))

        if all_gc_data:
            # 整体GC分布直方图
            axes[0, 0].hist(all_gc_data, bins=50, alpha=0.7, edgecolor='black')
            axes[0, 0].set_xlabel('GC Content (%)')
            axes[0, 0].set_ylabel('Frequency')
            axes[0, 0].set_title('Overall GC Content Distribution')
            axes[0, 0].axvline(np.mean(all_gc_data), color='red', linestyle='--',
                              label=f'Mean: {np.mean(all_gc_data):.2f}%')
            axes[0, 0].legend()

            # 样本间GC含量箱线图
            gc_df = pd.DataFrame({'Sample': sample_names, 'GC_Content': all_gc_data})
            sns.boxplot(data=gc_df, x='Sample', y='GC_Content', ax=axes[0, 1])
            axes[0, 1].set_title('GC Content by Sample')
            axes[0, 1].tick_params(axis='x', rotation=45)

            # GC含量密度图
            for sample_name, stats in analysis_results.items():
                if stats['gc_content']:
                    axes[1, 0].hist(stats['gc_content'], bins=30, alpha=0.5,
                                   label=sample_name, density=True)
            axes[1, 0].set_xlabel('GC Content (%)')
            axes[1, 0].set_ylabel('Density')
            axes[1, 0].set_title('GC Content Density by Sample')
            axes[1, 0].legend()

            # GC含量统计汇总
            gc_stats = gc_df.groupby('Sample')['GC_Content'].agg(['mean', 'std', 'min', 'max'])
            sns.heatmap(gc_stats, annot=True, fmt='.2f', ax=axes[1, 1], cmap='viridis')
            axes[1, 1].set_title('GC Content Statistics Heatmap')

        plt.tight_layout()
        plt.savefig(plots_dir / "gc_content_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()

    def plot_length_distribution(self, analysis_results: Dict, plots_dir: Path):
        """绘制序列长度分布图"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('Sequence Length Analysis', fontsize=16, fontweight='bold')

        # 收集长度数据
        all_lengths = []
        sample_names = []

        for sample_name, stats in analysis_results.items():
            if stats['sequence_lengths']:
                all_lengths.extend(stats['sequence_lengths'])
                sample_names.extend([sample_name] * len(stats['sequence_lengths']))

        if all_lengths:
            # 整体长度分布
            axes[0, 0].hist(all_lengths, bins=50, alpha=0.7, edgecolor='black')
            axes[0, 0].set_xlabel('Sequence Length (bp)')
            axes[0, 0].set_ylabel('Frequency')
            axes[0, 0].set_title('Overall Length Distribution')
            axes[0, 0].axvline(np.mean(all_lengths), color='red', linestyle='--',
                              label=f'Mean: {np.mean(all_lengths):.0f} bp')
            axes[0, 0].legend()

            # 样本间长度比较
            length_df = pd.DataFrame({'Sample': sample_names, 'Length': all_lengths})
            sns.boxplot(data=length_df, x='Sample', y='Length', ax=axes[0, 1])
            axes[0, 1].set_title('Length Distribution by Sample')
            axes[0, 1].tick_params(axis='x', rotation=45)

            # 长度累积分布
            for sample_name, stats in analysis_results.items():
                if stats['sequence_lengths']:
                    sorted_lengths = np.sort(stats['sequence_lengths'])
                    cumulative = np.arange(1, len(sorted_lengths) + 1) / len(sorted_lengths)
                    axes[1, 0].plot(sorted_lengths, cumulative, label=sample_name, alpha=0.7)
            axes[1, 0].set_xlabel('Sequence Length (bp)')
            axes[1, 0].set_ylabel('Cumulative Fraction')
            axes[1, 0].set_title('Cumulative Length Distribution')
            axes[1, 0].legend()

            # 长度统计汇总
            length_stats = length_df.groupby('Sample')['Length'].agg(['mean', 'std', 'min', 'max'])
            sns.heatmap(length_stats, annot=True, fmt='.0f', ax=axes[1, 1], cmap='plasma')
            axes[1, 1].set_title('Length Statistics Heatmap')

        plt.tight_layout()
        plt.savefig(plots_dir / "length_distribution_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()

    def plot_quality_distribution(self, analysis_results: Dict, plots_dir: Path):
        """绘制质量分数分布图"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle('Quality Score Analysis', fontsize=16, fontweight='bold')

        # 收集质量数据
        all_qualities = []
        sample_names = []

        for sample_name, stats in analysis_results.items():
            if stats['quality_scores']:
                all_qualities.extend(stats['quality_scores'])
                sample_names.extend([sample_name] * len(stats['quality_scores']))

        if all_qualities:
            # 整体质量分布
            axes[0, 0].hist(all_qualities, bins=50, alpha=0.7, edgecolor='black')
            axes[0, 0].set_xlabel('Quality Score')
            axes[0, 0].set_ylabel('Frequency')
            axes[0, 0].set_title('Overall Quality Distribution')
            axes[0, 0].axvline(np.mean(all_qualities), color='red', linestyle='--',
                              label=f'Mean: {np.mean(all_qualities):.2f}')
            axes[0, 0].legend()

            # 样本间质量比较
            quality_df = pd.DataFrame({'Sample': sample_names, 'Quality': all_qualities})
            sns.boxplot(data=quality_df, x='Sample', y='Quality', ax=axes[0, 1])
            axes[0, 1].set_title('Quality Distribution by Sample')
            axes[0, 1].tick_params(axis='x', rotation=45)

            # 质量阈值分析
            thresholds = [10, 20, 30, 40]
            threshold_data = []
            for sample_name, stats in analysis_results.items():
                if stats['quality_scores']:
                    for threshold in thresholds:
                        fraction = np.mean(np.array(stats['quality_scores']) >= threshold)
                        threshold_data.append({
                            'Sample': sample_name,
                            'Threshold': f'Q{threshold}',
                            'Fraction': fraction
                        })

            if threshold_data:
                threshold_df = pd.DataFrame(threshold_data)
                threshold_pivot = threshold_df.pivot(index='Sample', columns='Threshold', values='Fraction')
                sns.heatmap(threshold_pivot, annot=True, fmt='.3f', ax=axes[1, 0], cmap='RdYlGn')
                axes[1, 0].set_title('Quality Threshold Analysis')

            # 质量统计汇总
            quality_stats = quality_df.groupby('Sample')['Quality'].agg(['mean', 'std', 'min', 'max'])
            sns.heatmap(quality_stats, annot=True, fmt='.2f', ax=axes[1, 1], cmap='viridis')
            axes[1, 1].set_title('Quality Statistics Heatmap')

        plt.tight_layout()
        plt.savefig(plots_dir / "quality_score_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()

    def plot_complexity_analysis(self, analysis_results: Dict, plots_dir: Path):
        """绘制复杂度分析图"""
        fig, axes = plt.subplots(1, 2, figsize=(15, 6))
        fig.suptitle('Sequence Complexity Analysis', fontsize=16, fontweight='bold')

        # 收集复杂度数据
        complexity_data = []
        for sample_name, stats in analysis_results.items():
            if stats['complexity_scores']:
                for score in stats['complexity_scores']:
                    complexity_data.append({'Sample': sample_name, 'Complexity': score})

        if complexity_data:
            complexity_df = pd.DataFrame(complexity_data)

            # 复杂度分布箱线图
            sns.boxplot(data=complexity_df, x='Sample', y='Complexity', ax=axes[0])
            axes[0].set_title('Complexity Distribution by Sample')
            axes[0].tick_params(axis='x', rotation=45)

            # 复杂度直方图
            axes[1].hist(complexity_df['Complexity'], bins=30, alpha=0.7, edgecolor='black')
            axes[1].set_xlabel('Complexity Score')
            axes[1].set_ylabel('Frequency')
            axes[1].set_title('Overall Complexity Distribution')
            axes[1].axvline(complexity_df['Complexity'].mean(), color='red', linestyle='--',
                           label=f'Mean: {complexity_df["Complexity"].mean():.3f}')
            axes[1].legend()

        plt.tight_layout()
        plt.savefig(plots_dir / "complexity_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()

    def plot_sample_comparison(self, analysis_results: Dict, plots_dir: Path):
        """绘制样本比较热图"""
        # 准备数据
        comparison_data = []
        for sample_name, stats in analysis_results.items():
            comparison_data.append({
                'Sample': sample_name,
                'Total_Sequences': stats['total_sequences'],
                'Mean_Length': np.mean(stats['sequence_lengths']) if stats['sequence_lengths'] else 0,
                'Mean_GC': np.mean(stats['gc_content']) if stats['gc_content'] else 0,
                'Mean_Quality': np.mean(stats['quality_scores']) if stats['quality_scores'] else 0,
                'Mean_Complexity': np.mean(stats['complexity_scores']) if stats['complexity_scores'] else 0,
                'Mean_N_Content': np.mean(stats['n_content']) if stats['n_content'] else 0
            })

        if comparison_data:
            df = pd.DataFrame(comparison_data)
            df.set_index('Sample', inplace=True)

            # 标准化数据用于热图
            df_normalized = (df - df.mean()) / df.std()

            plt.figure(figsize=(12, 8))
            sns.heatmap(df_normalized.T, annot=True, fmt='.2f', cmap='RdBu_r', center=0)
            plt.title('Sample Comparison Heatmap (Standardized)', fontsize=16, fontweight='bold')
            plt.tight_layout()
            plt.savefig(plots_dir / "sample_comparison_heatmap.png", dpi=300, bbox_inches='tight')
            plt.close()

    def create_html_report(self, analysis_results: Dict, report_dir: Path) -> Path:
        """创建HTML报告"""
        html_content = f"""
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>MICOS-2024 增强质量控制报告</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ text-align: center; background-color: #f0f0f0; padding: 20px; }}
                .section {{ margin: 20px 0; }}
                .plot {{ text-align: center; margin: 20px 0; }}
                .plot img {{ max-width: 100%; height: auto; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
                .summary {{ background-color: #e8f4fd; padding: 15px; border-radius: 5px; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>MICOS-2024 增强质量控制报告</h1>
                <p>生成时间: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            </div>

            <div class="section">
                <h2>分析概要</h2>
                <div class="summary">
                    <p><strong>分析样本数:</strong> {len(analysis_results)}</p>
                    <p><strong>总序列数:</strong> {sum(stats['total_sequences'] for stats in analysis_results.values()):,}</p>
                    <p><strong>总碱基数:</strong> {sum(stats['total_bases'] for stats in analysis_results.values()):,}</p>
                </div>
            </div>

            <div class="section">
                <h2>质量控制图表</h2>

                <div class="plot">
                    <h3>GC含量分析</h3>
                    <img src="plots/gc_content_analysis.png" alt="GC Content Analysis">
                </div>

                <div class="plot">
                    <h3>序列长度分析</h3>
                    <img src="plots/length_distribution_analysis.png" alt="Length Distribution Analysis">
                </div>

                <div class="plot">
                    <h3>质量分数分析</h3>
                    <img src="plots/quality_score_analysis.png" alt="Quality Score Analysis">
                </div>

                <div class="plot">
                    <h3>复杂度分析</h3>
                    <img src="plots/complexity_analysis.png" alt="Complexity Analysis">
                </div>

                <div class="plot">
                    <h3>样本比较</h3>
                    <img src="plots/sample_comparison_heatmap.png" alt="Sample Comparison">
                </div>
            </div>

            <div class="section">
                <h2>详细统计</h2>
                <p>详细的统计数据请查看: <a href="quality_summary.csv">quality_summary.csv</a></p>
            </div>

            <div class="section">
                <h2>质量评估建议</h2>
                {self.generate_quality_recommendations(analysis_results)}
            </div>
        </body>
        </html>
        """

        report_file = report_dir / "enhanced_qc_report.html"
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(html_content)

        return report_file

    def generate_quality_recommendations(self, analysis_results: Dict) -> str:
        """生成质量评估建议"""
        recommendations = []

        for sample_name, stats in analysis_results.items():
            sample_recommendations = []

            # 检查GC含量
            if stats['gc_content']:
                mean_gc = np.mean(stats['gc_content'])
                if mean_gc < 30 or mean_gc > 70:
                    sample_recommendations.append(f"GC含量异常 ({mean_gc:.1f}%)")

            # 检查质量分数
            if stats['quality_scores']:
                mean_quality = np.mean(stats['quality_scores'])
                if mean_quality < 25:
                    sample_recommendations.append(f"平均质量分数较低 ({mean_quality:.1f})")

            # 检查复杂度
            if stats['complexity_scores']:
                mean_complexity = np.mean(stats['complexity_scores'])
                if mean_complexity < 0.5:
                    sample_recommendations.append(f"序列复杂度较低 ({mean_complexity:.3f})")

            # 检查N含量
            if stats['n_content']:
                mean_n = np.mean(stats['n_content'])
                if mean_n > 0.05:
                    sample_recommendations.append(f"N含量较高 ({mean_n:.3f})")

            if sample_recommendations:
                recommendations.append(f"<li><strong>{sample_name}:</strong> {'; '.join(sample_recommendations)}</li>")

        if recommendations:
            return f"<ul>{''.join(recommendations)}</ul>"
        else:
            return "<p>所有样本质量良好，无特殊建议。</p>"

    def generate_quality_report(self, analysis_results: Dict) -> str:
        """生成质量控制报告"""
        self.logger.info("生成质量控制报告...")

        # 创建报告目录
        report_dir = self.output_dir / "reports"
        report_dir.mkdir(exist_ok=True)

        # 生成统计表格
        self.create_summary_table(analysis_results, report_dir)

        # 生成可视化图表
        self.create_quality_plots(analysis_results, report_dir)

        # 生成HTML报告
        report_file = self.create_html_report(analysis_results, report_dir)

        self.logger.info(f"质量控制报告已生成: {report_file}")
        return str(report_file)


def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="MICOS-2024 增强质量控制分析")
    parser.add_argument("input_files", nargs="+", help="输入FASTQ/FASTA文件")
    parser.add_argument("-c", "--config", help="配置文件路径")
    parser.add_argument("-o", "--output", default="results/enhanced_qc", help="输出目录")
    parser.add_argument("--threads", type=int, default=4, help="线程数")

    args = parser.parse_args()

    # 初始化分析器
    qc_analyzer = EnhancedQualityControl(args.config, args.output)

    # 运行分析
    results = qc_analyzer.run_enhanced_analysis(args.input_files)

    # 生成报告
    report_file = qc_analyzer.generate_quality_report(results)

    print(f"增强质量控制分析完成，报告文件: {report_file}")


if __name__ == "__main__":
    main()
