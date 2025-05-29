#!/usr/bin/env python3

"""
MICOS-2024 16S rRNA扩增子分析模块
作者: MICOS-2024 团队
版本: 1.0.0

功能:
- 16S rRNA序列质量控制
- OTU聚类和ASV推断
- 分类学注释
- 多样性分析
- 系统发育分析
"""

import os
import sys
import argparse
import logging
from pathlib import Path
import pandas as pd
import numpy as np
import subprocess
import tempfile
import shutil

# 设置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AmpliconAnalyzer:
    """16S rRNA扩增子分析类"""
    
    def __init__(self, output_dir):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # 创建子目录
        self.qc_dir = self.output_dir / "quality_control"
        self.otu_dir = self.output_dir / "otu_clustering"
        self.taxonomy_dir = self.output_dir / "taxonomy"
        self.diversity_dir = self.output_dir / "diversity"
        
        for dir_path in [self.qc_dir, self.otu_dir, self.taxonomy_dir, self.diversity_dir]:
            dir_path.mkdir(exist_ok=True)
    
    def quality_control_16s(self, input_dir, output_dir):
        """16S rRNA序列质量控制"""
        logger.info("开始16S rRNA序列质量控制...")
        
        try:
            # 检查QIIME2是否可用
            result = subprocess.run(['qiime', '--version'], 
                                  capture_output=True, text=True)
            if result.returncode != 0:
                logger.error("QIIME2未安装或不可用")
                return False
            
            # 导入序列数据
            manifest_file = self.create_manifest_file(input_dir)
            
            # QIIME2导入命令
            import_cmd = [
                'qiime', 'tools', 'import',
                '--type', 'SampleData[PairedEndSequencesWithQuality]',
                '--input-path', str(manifest_file),
                '--output-path', str(output_dir / 'demux-paired-end.qza'),
                '--input-format', 'PairedEndFastqManifestPhred33V2'
            ]
            
            result = subprocess.run(import_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                logger.error(f"QIIME2导入失败: {result.stderr}")
                return False
            
            # 生成质量报告
            demux_viz_cmd = [
                'qiime', 'demux', 'summarize',
                '--i-data', str(output_dir / 'demux-paired-end.qza'),
                '--o-visualization', str(output_dir / 'demux-paired-end.qzv')
            ]
            
            subprocess.run(demux_viz_cmd, capture_output=True, text=True)
            
            logger.info("16S rRNA质量控制完成")
            return True
            
        except Exception as e:
            logger.error(f"16S rRNA质量控制失败: {e}")
            return False
    
    def create_manifest_file(self, input_dir):
        """创建QIIME2 manifest文件"""
        manifest_file = self.qc_dir / "manifest.tsv"
        
        # 扫描输入目录中的FASTQ文件
        fastq_files = list(Path(input_dir).glob("*.fastq.gz"))
        
        # 创建manifest内容
        manifest_data = []
        manifest_data.append("sample-id\tforward-absolute-filepath\treverse-absolute-filepath")
        
        # 假设文件命名格式为 sample_R1.fastq.gz 和 sample_R2.fastq.gz
        samples = set()
        for file in fastq_files:
            if "_R1" in file.name:
                sample_id = file.name.replace("_R1.fastq.gz", "")
                samples.add(sample_id)
        
        for sample_id in samples:
            r1_file = Path(input_dir) / f"{sample_id}_R1.fastq.gz"
            r2_file = Path(input_dir) / f"{sample_id}_R2.fastq.gz"
            
            if r1_file.exists() and r2_file.exists():
                manifest_data.append(f"{sample_id}\t{r1_file.absolute()}\t{r2_file.absolute()}")
        
        # 写入manifest文件
        with open(manifest_file, 'w') as f:
            f.write('\n'.join(manifest_data))
        
        return manifest_file
    
    def denoise_sequences(self, input_qza, output_dir):
        """使用DADA2进行序列去噪和ASV推断"""
        logger.info("使用DADA2进行序列去噪...")
        
        try:
            # DADA2去噪命令
            dada2_cmd = [
                'qiime', 'dada2', 'denoise-paired',
                '--i-demultiplexed-seqs', str(input_qza),
                '--p-trim-left-f', '13',
                '--p-trim-left-r', '13',
                '--p-trunc-len-f', '150',
                '--p-trunc-len-r', '150',
                '--o-table', str(output_dir / 'table.qza'),
                '--o-representative-sequences', str(output_dir / 'rep-seqs.qza'),
                '--o-denoising-stats', str(output_dir / 'denoising-stats.qza')
            ]
            
            result = subprocess.run(dada2_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                logger.error(f"DADA2去噪失败: {result.stderr}")
                return False
            
            # 生成特征表摘要
            table_viz_cmd = [
                'qiime', 'feature-table', 'summarize',
                '--i-table', str(output_dir / 'table.qza'),
                '--o-visualization', str(output_dir / 'table.qzv')
            ]
            
            subprocess.run(table_viz_cmd, capture_output=True, text=True)
            
            # 生成代表序列摘要
            seqs_viz_cmd = [
                'qiime', 'feature-table', 'tabulate-seqs',
                '--i-data', str(output_dir / 'rep-seqs.qza'),
                '--o-visualization', str(output_dir / 'rep-seqs.qzv')
            ]
            
            subprocess.run(seqs_viz_cmd, capture_output=True, text=True)
            
            logger.info("DADA2序列去噪完成")
            return True
            
        except Exception as e:
            logger.error(f"DADA2序列去噪失败: {e}")
            return False
    
    def assign_taxonomy(self, rep_seqs_qza, classifier_qza, output_dir):
        """分配分类学注释"""
        logger.info("进行分类学注释...")
        
        try:
            # 分类学注释命令
            classify_cmd = [
                'qiime', 'feature-classifier', 'classify-sklearn',
                '--i-classifier', str(classifier_qza),
                '--i-reads', str(rep_seqs_qza),
                '--o-classification', str(output_dir / 'taxonomy.qza')
            ]
            
            result = subprocess.run(classify_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                logger.error(f"分类学注释失败: {result.stderr}")
                return False
            
            # 生成分类学可视化
            taxonomy_viz_cmd = [
                'qiime', 'metadata', 'tabulate',
                '--m-input-file', str(output_dir / 'taxonomy.qza'),
                '--o-visualization', str(output_dir / 'taxonomy.qzv')
            ]
            
            subprocess.run(taxonomy_viz_cmd, capture_output=True, text=True)
            
            logger.info("分类学注释完成")
            return True
            
        except Exception as e:
            logger.error(f"分类学注释失败: {e}")
            return False
    
    def diversity_analysis(self, table_qza, rep_seqs_qza, taxonomy_qza, metadata_file, output_dir):
        """多样性分析"""
        logger.info("进行多样性分析...")
        
        try:
            # 构建系统发育树
            phylogeny_cmd = [
                'qiime', 'phylogeny', 'align-to-tree-mafft-fasttree',
                '--i-sequences', str(rep_seqs_qza),
                '--o-alignment', str(output_dir / 'aligned-rep-seqs.qza'),
                '--o-masked-alignment', str(output_dir / 'masked-aligned-rep-seqs.qza'),
                '--o-tree', str(output_dir / 'unrooted-tree.qza'),
                '--o-rooted-tree', str(output_dir / 'rooted-tree.qza')
            ]
            
            result = subprocess.run(phylogeny_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                logger.warning(f"系统发育树构建失败: {result.stderr}")
            
            # 核心多样性分析
            core_metrics_cmd = [
                'qiime', 'diversity', 'core-metrics-phylogenetic',
                '--i-phylogeny', str(output_dir / 'rooted-tree.qza'),
                '--i-table', str(table_qza),
                '--p-sampling-depth', '1000',
                '--m-metadata-file', str(metadata_file),
                '--output-dir', str(output_dir / 'core-metrics-results')
            ]
            
            result = subprocess.run(core_metrics_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                logger.error(f"核心多样性分析失败: {result.stderr}")
                return False
            
            logger.info("多样性分析完成")
            return True
            
        except Exception as e:
            logger.error(f"多样性分析失败: {e}")
            return False
    
    def generate_taxa_barplot(self, table_qza, taxonomy_qza, metadata_file, output_file):
        """生成分类学条形图"""
        logger.info("生成分类学条形图...")
        
        try:
            barplot_cmd = [
                'qiime', 'taxa', 'barplot',
                '--i-table', str(table_qza),
                '--i-taxonomy', str(taxonomy_qza),
                '--m-metadata-file', str(metadata_file),
                '--o-visualization', str(output_file)
            ]
            
            result = subprocess.run(barplot_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                logger.error(f"分类学条形图生成失败: {result.stderr}")
                return False
            
            logger.info("分类学条形图生成完成")
            return True
            
        except Exception as e:
            logger.error(f"分类学条形图生成失败: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description="MICOS-2024 16S rRNA扩增子分析")
    parser.add_argument("--input", required=True, help="输入FASTQ文件目录")
    parser.add_argument("--metadata", required=True, help="样本元数据文件")
    parser.add_argument("--classifier", help="QIIME2分类器文件(.qza)")
    parser.add_argument("--output", required=True, help="输出目录")
    
    args = parser.parse_args()
    
    # 创建分析器
    analyzer = AmpliconAnalyzer(args.output)
    
    logger.info("开始16S rRNA扩增子分析...")
    
    # 1. 质量控制
    if analyzer.quality_control_16s(args.input, analyzer.qc_dir):
        
        # 2. 序列去噪
        demux_qza = analyzer.qc_dir / 'demux-paired-end.qza'
        if analyzer.denoise_sequences(demux_qza, analyzer.otu_dir):
            
            # 3. 分类学注释（如果提供了分类器）
            if args.classifier and Path(args.classifier).exists():
                rep_seqs_qza = analyzer.otu_dir / 'rep-seqs.qza'
                if analyzer.assign_taxonomy(rep_seqs_qza, args.classifier, analyzer.taxonomy_dir):
                    
                    # 4. 多样性分析
                    table_qza = analyzer.otu_dir / 'table.qza'
                    taxonomy_qza = analyzer.taxonomy_dir / 'taxonomy.qza'
                    analyzer.diversity_analysis(table_qza, rep_seqs_qza, taxonomy_qza, 
                                              args.metadata, analyzer.diversity_dir)
                    
                    # 5. 生成分类学条形图
                    barplot_file = analyzer.taxonomy_dir / 'taxa-bar-plots.qzv'
                    analyzer.generate_taxa_barplot(table_qza, taxonomy_qza, 
                                                 args.metadata, barplot_file)
    
    logger.info("16S rRNA扩增子分析完成！")

if __name__ == "__main__":
    main()
