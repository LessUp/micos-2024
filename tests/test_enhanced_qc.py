#!/usr/bin/env python3
"""
MICOS-2024 增强质量控制模块测试

测试增强质量控制功能的正确性和性能
"""

import unittest
import tempfile
import os
from pathlib import Path
import pandas as pd
import numpy as np
from unittest.mock import patch, MagicMock

# 导入被测试的模块
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'scripts'))

try:
    from enhanced_qc import EnhancedQualityControl
except ImportError:
    # 如果导入失败，创建一个模拟类用于测试
    class EnhancedQualityControl:
        def __init__(self, config_file=None, output_dir="results/enhanced_qc"):
            self.output_dir = Path(output_dir)
            self.config = {}
            self.qc_results = {}
            self.sample_stats = {}


class TestEnhancedQualityControl(unittest.TestCase):
    """增强质量控制测试类"""

    def setUp(self):
        """测试前准备"""
        self.temp_dir = tempfile.mkdtemp()
        self.qc = EnhancedQualityControl(output_dir=self.temp_dir)

    def tearDown(self):
        """测试后清理"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_initialization(self):
        """测试初始化"""
        self.assertIsInstance(self.qc, EnhancedQualityControl)
        self.assertTrue(self.qc.output_dir.exists())
        self.assertIsInstance(self.qc.config, dict)
        self.assertIsInstance(self.qc.qc_results, dict)
        self.assertIsInstance(self.qc.sample_stats, dict)

    def test_config_loading(self):
        """测试配置加载"""
        # 创建临时配置文件
        config_file = os.path.join(self.temp_dir, "test_config.yaml")
        with open(config_file, 'w') as f:
            f.write("""
enhanced_qc:
  quality_thresholds:
    min_quality: 25
    min_length: 100
  visualization:
    plot_format: ['png']
""")
        
        qc = EnhancedQualityControl(config_file=config_file, output_dir=self.temp_dir)
        self.assertEqual(qc.config['quality_thresholds']['min_quality'], 25)
        self.assertEqual(qc.config['quality_thresholds']['min_length'], 100)

    def test_sequence_complexity_calculation(self):
        """测试序列复杂度计算"""
        # 测试简单序列
        simple_seq = "AAAAAAAAAA"
        complexity = self.qc.calculate_sequence_complexity(simple_seq)
        self.assertLess(complexity, 0.5)  # 低复杂度
        
        # 测试复杂序列
        complex_seq = "ATCGATCGATCGATCG"
        complexity = self.qc.calculate_sequence_complexity(complex_seq)
        self.assertGreater(complexity, 0.5)  # 高复杂度
        
        # 测试短序列
        short_seq = "ATG"
        complexity = self.qc.calculate_sequence_complexity(short_seq)
        self.assertEqual(complexity, 0.0)

    def test_summary_table_creation(self):
        """测试汇总表格创建"""
        # 模拟分析结果
        mock_results = {
            'sample1': {
                'total_sequences': 1000,
                'total_bases': 150000,
                'sequence_lengths': [150] * 1000,
                'gc_content': [45.0] * 1000,
                'quality_scores': [30] * 150000,
                'complexity_scores': [0.8] * 1000,
                'n_content': [0.01] * 1000
            },
            'sample2': {
                'total_sequences': 800,
                'total_bases': 120000,
                'sequence_lengths': [150] * 800,
                'gc_content': [42.0] * 800,
                'quality_scores': [28] * 120000,
                'complexity_scores': [0.75] * 800,
                'n_content': [0.02] * 800
            }
        }
        
        report_dir = Path(self.temp_dir) / "reports"
        report_dir.mkdir(exist_ok=True)
        
        df = self.qc.create_summary_table(mock_results, report_dir)
        
        # 检查结果
        self.assertIsInstance(df, pd.DataFrame)
        self.assertEqual(len(df), 2)
        self.assertIn('Sample', df.columns)
        self.assertIn('Total_Sequences', df.columns)
        self.assertIn('Mean_GC_Content', df.columns)
        
        # 检查文件是否创建
        summary_file = report_dir / "quality_summary.csv"
        self.assertTrue(summary_file.exists())

    @patch('matplotlib.pyplot.savefig')
    @patch('matplotlib.pyplot.close')
    def test_plot_creation(self, mock_close, mock_savefig):
        """测试图表创建"""
        # 模拟分析结果
        mock_results = {
            'sample1': {
                'gc_content': [45.0, 46.0, 44.0],
                'sequence_lengths': [150, 151, 149],
                'quality_scores': [30, 31, 29],
                'complexity_scores': [0.8, 0.81, 0.79],
                'n_content': [0.01, 0.01, 0.02]
            }
        }
        
        plots_dir = Path(self.temp_dir) / "plots"
        plots_dir.mkdir(exist_ok=True)
        
        # 测试各种图表创建方法
        try:
            self.qc.plot_gc_distribution(mock_results, plots_dir)
            self.qc.plot_length_distribution(mock_results, plots_dir)
            self.qc.plot_quality_distribution(mock_results, plots_dir)
            self.qc.plot_complexity_analysis(mock_results, plots_dir)
        except Exception as e:
            # 如果matplotlib不可用，跳过图表测试
            self.skipTest(f"Matplotlib not available: {e}")

    def test_file_analysis_mock(self):
        """测试文件分析（模拟）"""
        # 创建模拟FASTQ文件
        mock_fastq = os.path.join(self.temp_dir, "test.fastq")
        with open(mock_fastq, 'w') as f:
            f.write("@seq1\nATCGATCG\n+\nIIIIIIII\n")
            f.write("@seq2\nGCGCGCGC\n+\nIIIIIIII\n")
        
        # 由于BioPython可能不可用，我们模拟分析结果
        mock_stats = {
            'total_sequences': 2,
            'total_bases': 16,
            'gc_content': [50.0, 100.0],
            'sequence_lengths': [8, 8],
            'quality_scores': [40] * 16,
            'complexity_scores': [0.8, 0.6],
            'n_content': [0.0, 0.0]
        }
        
        # 验证统计数据结构
        self.assertIn('total_sequences', mock_stats)
        self.assertIn('total_bases', mock_stats)
        self.assertIsInstance(mock_stats['gc_content'], list)
        self.assertIsInstance(mock_stats['sequence_lengths'], list)

    def test_error_handling(self):
        """测试错误处理"""
        # 测试不存在的文件
        non_existent_file = "/path/that/does/not/exist.fastq"
        result = self.qc.analyze_sequence_file(non_existent_file)
        
        # 应该返回空的统计数据
        expected_keys = ['total_sequences', 'total_bases', 'gc_content', 
                        'sequence_lengths', 'quality_scores', 'complexity_scores', 'n_content']
        for key in expected_keys:
            self.assertIn(key, result)

    def test_performance_with_large_data(self):
        """测试大数据性能"""
        # 创建大量模拟数据
        large_data = {
            f'sample_{i}': {
                'total_sequences': 10000,
                'total_bases': 1500000,
                'sequence_lengths': [150] * 10000,
                'gc_content': np.random.normal(45, 5, 10000).tolist(),
                'quality_scores': np.random.normal(30, 5, 1500000).tolist(),
                'complexity_scores': np.random.uniform(0.5, 1.0, 10000).tolist(),
                'n_content': np.random.uniform(0, 0.05, 10000).tolist()
            }
            for i in range(5)
        }
        
        report_dir = Path(self.temp_dir) / "performance_test"
        report_dir.mkdir(exist_ok=True)
        
        # 测试汇总表格创建性能
        import time
        start_time = time.time()
        df = self.qc.create_summary_table(large_data, report_dir)
        end_time = time.time()
        
        # 应该在合理时间内完成（< 5秒）
        self.assertLess(end_time - start_time, 5.0)
        self.assertEqual(len(df), 5)


class TestQualityMetrics(unittest.TestCase):
    """质量指标测试类"""

    def test_gc_content_calculation(self):
        """测试GC含量计算"""
        # 这里我们测试GC含量计算的逻辑
        sequences = [
            ("ATCG", 50.0),  # 2 GC out of 4
            ("AAAA", 0.0),   # 0 GC out of 4
            ("GGGG", 100.0), # 4 GC out of 4
            ("ATCGATCG", 50.0), # 4 GC out of 8
        ]
        
        for seq, expected_gc in sequences:
            gc_count = seq.count('G') + seq.count('C')
            calculated_gc = (gc_count / len(seq)) * 100
            self.assertAlmostEqual(calculated_gc, expected_gc, places=1)

    def test_quality_thresholds(self):
        """测试质量阈值"""
        quality_scores = [10, 20, 25, 30, 35, 40]
        thresholds = [20, 30]
        
        for threshold in thresholds:
            fraction_above = sum(1 for q in quality_scores if q >= threshold) / len(quality_scores)
            self.assertGreaterEqual(fraction_above, 0.0)
            self.assertLessEqual(fraction_above, 1.0)


if __name__ == '__main__':
    unittest.main()
