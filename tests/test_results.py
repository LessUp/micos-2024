# -*- coding: utf-8 -*-
"""测试分析结果模型模块。"""

from __future__ import annotations

from pathlib import Path

import pytest

from micos.results import (
    QCResult,
    TaxonomyResult,
    DiversityResult,
    FunctionalResult,
    SummaryResult,
    FullPipelineResult,
)
from micos.sample import Sample


class TestQCResult:
    """测试 QCResult 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = QCResult()

        assert result.fastqc_reports == []
        assert result.clean_reads == {}
        assert result.logs == []
        assert result.stats == {}

    def test_sample_count(self) -> None:
        """测试样本计数。"""
        result = QCResult()
        assert result.sample_count == 0

        sample = Sample(name="test", r1_path=Path("test.fastq"))
        result.clean_reads["test"] = sample
        assert result.sample_count == 1

    def test_success_with_samples(self) -> None:
        """有样本时 success 应为 True。"""
        sample = Sample(name="test", r1_path=Path("test.fastq"))
        result = QCResult(clean_reads={"test": sample})

        assert result.success is True

    def test_success_without_samples(self) -> None:
        """无样本时 success 应为 False。"""
        result = QCResult()

        assert result.success is False


class TestTaxonomyResult:
    """测试 TaxonomyResult 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = TaxonomyResult()

        assert result.kraken_reports == []
        assert result.biom_table is None
        assert result.krona_plots == []
        assert result.logs == []

    def test_sample_count(self) -> None:
        """测试样本计数。"""
        result = TaxonomyResult(
            kraken_reports=[Path("sample1.report"), Path("sample2.report")]
        )

        assert result.sample_count == 2

    def test_success_with_biom_table(self, tmp_path: Path) -> None:
        """有 BIOM 表时 success 应为 True。"""
        biom_file = tmp_path / "feature-table.biom"
        biom_file.write_text("test")

        result = TaxonomyResult(biom_table=biom_file)

        assert result.success is True

    def test_success_without_biom_table(self) -> None:
        """无 BIOM 表时 success 应为 False。"""
        result = TaxonomyResult()

        assert result.success is False


class TestDiversityResult:
    """测试 DiversityResult 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = DiversityResult()

        assert result.alpha_diversity == []
        assert result.beta_diversity == []
        assert result.feature_table is None

    def test_success_with_alpha(self) -> None:
        """有 Alpha 多样性结果时 success 应为 True。"""
        result = DiversityResult(alpha_diversity=[Path("shannon.qza")])

        assert result.success is True

    def test_success_with_beta(self) -> None:
        """有 Beta 多样性结果时 success 应为 True。"""
        result = DiversityResult(beta_diversity=[Path("bray_curtis.qza")])

        assert result.success is True

    def test_success_without_results(self) -> None:
        """无结果时 success 应为 False。"""
        result = DiversityResult()

        assert result.success is False


class TestFunctionalResult:
    """测试 FunctionalResult 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = FunctionalResult()

        assert result.gene_families == []
        assert result.pathway_abundance == []
        assert result.pathway_coverage == []

    def test_sample_count(self) -> None:
        """测试样本计数。"""
        result = FunctionalResult(
            gene_families=[Path("sample1_genefamilies.tsv")]
        )

        assert result.sample_count == 1

    def test_success_with_gene_families(self) -> None:
        """有基因家族结果时 success 应为 True。"""
        result = FunctionalResult(gene_families=[Path("genefamilies.tsv")])

        assert result.success is True

    def test_success_without_results(self) -> None:
        """无结果时 success 应为 False。"""
        result = FunctionalResult()

        assert result.success is False


class TestSummaryResult:
    """测试 SummaryResult 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = SummaryResult()

        assert result.html_report is None
        assert result.summary_files == []
        assert result.sections == {}

    def test_success_with_html_report(self, tmp_path: Path) -> None:
        """有 HTML 报告时 success 应为 True。"""
        html_file = tmp_path / "report.html"
        html_file.write_text("<html></html>")

        result = SummaryResult(html_report=html_file)

        assert result.success is True

    def test_success_without_html_report(self) -> None:
        """无 HTML 报告时 success 应为 False。"""
        result = SummaryResult()

        assert result.success is False


class TestFullPipelineResult:
    """测试 FullPipelineResult 类。"""

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = FullPipelineResult()

        assert isinstance(result.qc, QCResult)
        assert isinstance(result.taxonomy, TaxonomyResult)
        assert isinstance(result.diversity, DiversityResult)
        assert isinstance(result.functional, FunctionalResult)
        assert isinstance(result.summary, SummaryResult)

    def test_success_all_stages_passed(
        self, tmp_path: Path
    ) -> None:
        """所有阶段都成功时 success 应为 True。"""
        biom_file = tmp_path / "feature-table.biom"
        biom_file.write_text("test")
        html_file = tmp_path / "report.html"
        html_file.write_text("<html></html>")

        sample = Sample(name="test", r1_path=Path("test.fastq"))
        result = FullPipelineResult(
            qc=QCResult(clean_reads={"test": sample}),
            taxonomy=TaxonomyResult(biom_table=biom_file),
            diversity=DiversityResult(alpha_diversity=[Path("shannon.qza")]),
            functional=FunctionalResult(gene_families=[Path("genefamilies.tsv")]),
            summary=SummaryResult(html_report=html_file),
        )

        assert result.success is True

    def test_success_some_stages_failed(self) -> None:
        """部分阶段失败时 success 应为 False。"""
        result = FullPipelineResult(
            qc=QCResult(),  # 失败：无样本
            taxonomy=TaxonomyResult(),  # 失败：无 BIOM 表
            diversity=DiversityResult(alpha_diversity=[Path("shannon.qza")]),
            functional=FunctionalResult(gene_families=[Path("genefamilies.tsv")]),
            summary=SummaryResult(),  # 失败：无 HTML 报告
        )

        assert result.success is False

    def test_get_failed_stages(self) -> None:
        """测试获取失败阶段。"""
        result = FullPipelineResult(
            qc=QCResult(),  # 失败
            taxonomy=TaxonomyResult(),  # 失败
            diversity=DiversityResult(alpha_diversity=[Path("shannon.qza")]),
            functional=FunctionalResult(gene_families=[Path("genefamilies.tsv")]),
            summary=SummaryResult(),  # 失败
        )

        failed = result.get_failed_stages()

        assert "quality_control" in failed
        assert "taxonomic_profiling" in failed
        assert "summarize_results" in failed
        assert "diversity_analysis" not in failed
        assert "functional_annotation" not in failed
