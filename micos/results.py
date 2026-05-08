# -*- coding: utf-8 -*-
"""分析结果模型模块。

提供各阶段分析结果的数据模型，支持内存管道和结果验证。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from micos.sample import Sample


@dataclass
class QCResult:
    """质量控制结果。

    这是质量控制阶段的输出，包含 FastQC 报告和清洗后的样本。

    Attributes:
        fastqc_reports: FastQC 报告文件列表
        clean_reads: 清洗后的样本字典（样本名 -> Sample）
        logs: 日志文件列表
        stats: 统计信息（读取数、过滤比例等）
    """

    fastqc_reports: list[Path] = field(default_factory=list)
    clean_reads: dict[str, Sample] = field(default_factory=dict)
    logs: list[Path] = field(default_factory=list)
    stats: dict[str, Any] = field(default_factory=dict)

    @property
    def sample_count(self) -> int:
        """获取样本数量。"""
        return len(self.clean_reads)

    @property
    def success(self) -> bool:
        """检查结果是否有效。"""
        return len(self.clean_reads) > 0


@dataclass
class TaxonomyResult:
    """物种分类结果。

    这是物种分类阶段的输出，包含 Kraken2 报告、BIOM 表和 Krona 可视化。

    Attributes:
        kraken_reports: Kraken2 报告文件列表
        biom_table: BIOM 特征表路径
        krona_plots: Krona 可视化图表列表
        logs: 日志文件列表
        stats: 统计信息（分类比例等）
    """

    kraken_reports: list[Path] = field(default_factory=list)
    biom_table: Path | None = None
    krona_plots: list[Path] = field(default_factory=list)
    logs: list[Path] = field(default_factory=list)
    stats: dict[str, Any] = field(default_factory=dict)

    @property
    def sample_count(self) -> int:
        """获取样本数量。"""
        return len(self.kraken_reports)

    @property
    def success(self) -> bool:
        """检查结果是否有效。"""
        return self.biom_table is not None and self.biom_table.exists()


@dataclass
class DiversityResult:
    """多样性分析结果。

    这是多样性分析阶段的输出，包含 QIIME2 分析结果。

    Attributes:
        alpha_diversity: Alpha 多样性结果路径
        beta_diversity: Beta 多样性结果路径
        feature_table: 特征表路径
        logs: 日志文件列表
        stats: 统计信息
    """

    alpha_diversity: list[Path] = field(default_factory=list)
    beta_diversity: list[Path] = field(default_factory=list)
    feature_table: Path | None = None
    logs: list[Path] = field(default_factory=list)
    stats: dict[str, Any] = field(default_factory=dict)

    @property
    def success(self) -> bool:
        """检查结果是否有效。"""
        return len(self.alpha_diversity) > 0 or len(self.beta_diversity) > 0


@dataclass
class FunctionalResult:
    """功能注释结果。

    这是功能注释阶段的输出，包含 HUMAnN 分析结果。

    Attributes:
        gene_families: 基因家族丰度表列表
        pathway_abundance: 通路丰度表列表
        pathway_coverage: 通路覆盖度表列表
        logs: 日志文件列表
        stats: 统计信息
    """

    gene_families: list[Path] = field(default_factory=list)
    pathway_abundance: list[Path] = field(default_factory=list)
    pathway_coverage: list[Path] = field(default_factory=list)
    logs: list[Path] = field(default_factory=list)
    stats: dict[str, Any] = field(default_factory=dict)

    @property
    def sample_count(self) -> int:
        """获取样本数量。"""
        return len(self.gene_families)

    @property
    def success(self) -> bool:
        """检查结果是否有效。"""
        return len(self.gene_families) > 0


@dataclass
class SummaryResult:
    """结果汇总。

    这是汇总阶段的输出，包含 HTML 报告和汇总文件。

    Attributes:
        html_report: HTML 报告路径
        summary_files: 汇总文件列表
        sections: 各部分结果路径
    """

    html_report: Path | None = None
    summary_files: list[Path] = field(default_factory=list)
    sections: dict[str, list[Path]] = field(default_factory=dict)

    @property
    def success(self) -> bool:
        """检查结果是否有效。"""
        return self.html_report is not None and self.html_report.exists()


@dataclass
class FullPipelineResult:
    """完整流程结果。

    这是完整分析流程的输出，包含所有阶段的结果。

    Attributes:
        qc: 质量控制结果
        taxonomy: 物种分类结果
        diversity: 多样性分析结果
        functional: 功能注释结果
        summary: 结果汇总
    """

    qc: QCResult = field(default_factory=QCResult)
    taxonomy: TaxonomyResult = field(default_factory=TaxonomyResult)
    diversity: DiversityResult = field(default_factory=DiversityResult)
    functional: FunctionalResult = field(default_factory=FunctionalResult)
    summary: SummaryResult = field(default_factory=SummaryResult)

    @property
    def success(self) -> bool:
        """检查整体结果是否有效。"""
        return all(
            [
                self.qc.success,
                self.taxonomy.success,
                self.diversity.success,
                self.functional.success,
                self.summary.success,
            ]
        )

    def get_failed_stages(self) -> list[str]:
        """获取失败的阶段列表。"""
        failed = []
        if not self.qc.success:
            failed.append("quality_control")
        if not self.taxonomy.success:
            failed.append("taxonomic_profiling")
        if not self.diversity.success:
            failed.append("diversity_analysis")
        if not self.functional.success:
            failed.append("functional_annotation")
        if not self.summary.success:
            failed.append("summarize_results")
        return failed
