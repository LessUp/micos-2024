# -*- coding: utf-8 -*-
"""测试样本数据模型模块。"""

from __future__ import annotations

from pathlib import Path

import pytest

from micos.sample import Sample


class TestSample:
    """测试 Sample 类。"""

    def test_create_paired_sample(self) -> None:
        """创建双端样本。"""
        r1 = Path("data/sample001_R1.fastq.gz")
        r2 = Path("data/sample001_R2.fastq.gz")

        sample = Sample(name="sample001", r1_path=r1, r2_path=r2)

        assert sample.name == "sample001"
        assert sample.r1_path == r1
        assert sample.r2_path == r2
        assert sample.is_paired is True

    def test_create_single_end_sample(self) -> None:
        """创建单端样本。"""
        r1 = Path("data/sample001.fastq.gz")

        sample = Sample(name="sample001", r1_path=r1)

        assert sample.name == "sample001"
        assert sample.r1_path == r1
        assert sample.r2_path is None
        assert sample.is_paired is False

    def test_files_property_returns_all_paths(self) -> None:
        """files 属性应返回所有文件路径。"""
        r1 = Path("data/sample001_R1.fastq.gz")
        r2 = Path("data/sample001_R2.fastq.gz")

        sample = Sample(name="sample001", r1_path=r1, r2_path=r2)

        assert sample.files == [r1, r2]

    def test_files_property_single_end(self) -> None:
        """单端样本的 files 属性应只返回一个路径。"""
        r1 = Path("data/sample001.fastq.gz")

        sample = Sample(name="sample001", r1_path=r1)

        assert sample.files == [r1]

    def test_metadata_default_empty_dict(self) -> None:
        """元数据默认为空字典。"""
        sample = Sample(name="test", r1_path=Path("test.fastq"))

        assert sample.metadata == {}

    def test_metadata_can_be_set(self) -> None:
        """可以设置元数据。"""
        sample = Sample(
            name="test",
            r1_path=Path("test.fastq"),
            metadata={"group": "control", "batch": "A"},
        )

        assert sample.metadata["group"] == "control"
        assert sample.metadata["batch"] == "A"


class TestSampleDiscovery:
    """测试样本发现功能。"""

    def test_discover_paired_finds_samples(self, tmp_path: Path) -> None:
        """discover_paired 应发现配对的样本。"""
        # 创建测试文件
        (tmp_path / "sample001_R1.fastq.gz").write_text("r1")
        (tmp_path / "sample001_R2.fastq.gz").write_text("r2")
        (tmp_path / "sample002_R1.fastq.gz").write_text("r1")
        (tmp_path / "sample002_R2.fastq.gz").write_text("r2")

        samples = Sample.discover_paired(tmp_path)

        assert len(samples) == 2
        assert samples[0].name == "sample001"
        assert samples[1].name == "sample002"
        assert all(s.is_paired for s in samples)

    def test_discover_paired_handles_missing_r2(self, tmp_path: Path) -> None:
        """discover_paired 应处理缺失的 R2 文件。"""
        (tmp_path / "sample001_R1.fastq.gz").write_text("r1")
        # 不创建 R2 文件

        samples = Sample.discover_paired(tmp_path)

        assert len(samples) == 1
        assert samples[0].is_paired is False

    def test_discover_paired_returns_sorted_samples(self, tmp_path: Path) -> None:
        """discover_paired 应返回按名称排序的样本。"""
        (tmp_path / "sample_b_R1.fastq.gz").write_text("r1")
        (tmp_path / "sample_b_R2.fastq.gz").write_text("r2")
        (tmp_path / "sample_a_R1.fastq.gz").write_text("r1")
        (tmp_path / "sample_a_R2.fastq.gz").write_text("r2")

        samples = Sample.discover_paired(tmp_path)

        assert samples[0].name == "sample_a"
        assert samples[1].name == "sample_b"

    def test_discover_cleaned_finds_kneaddata_output(self, tmp_path: Path) -> None:
        """discover_cleaned 应发现 KneadData 输出的样本。"""
        (tmp_path / "sample001_paired_1.fastq").write_text("r1")
        (tmp_path / "sample001_paired_2.fastq").write_text("r2")
        (tmp_path / "sample002_paired_1.fastq").write_text("r1")
        (tmp_path / "sample002_paired_2.fastq").write_text("r2")

        samples = Sample.discover_cleaned(tmp_path)

        assert len(samples) == 2
        assert samples[0].name == "sample001"
        assert samples[1].name == "sample002"

    def test_discover_empty_directory(self, tmp_path: Path) -> None:
        """空目录应返回空列表。"""
        samples = Sample.discover_paired(tmp_path)

        assert samples == []


class TestSampleValidation:
    """测试样本验证功能。"""

    def test_validate_existing_files(self, tmp_path: Path) -> None:
        """validate 应验证存在的文件。"""
        r1 = tmp_path / "test_R1.fastq.gz"
        r2 = tmp_path / "test_R2.fastq.gz"
        r1.write_text("r1")
        r2.write_text("r2")

        sample = Sample(name="test", r1_path=r1, r2_path=r2)

        assert sample.validate() is True

    def test_validate_missing_file_raises(self, tmp_path: Path) -> None:
        """validate 应对缺失文件抛出异常。"""
        r1 = tmp_path / "nonexistent.fastq.gz"

        sample = Sample(name="test", r1_path=r1)

        with pytest.raises(FileNotFoundError):
            sample.validate()


class TestSampleStringRepresentation:
    """测试样本的字符串表示。"""

    def test_str_paired(self) -> None:
        """双端样本的字符串表示。"""
        sample = Sample(
            name="test",
            r1_path=Path("test_R1.fastq.gz"),
            r2_path=Path("test_R2.fastq.gz"),
        )

        s = str(sample)
        assert "test" in s
        assert "paired" in s

    def test_str_single(self) -> None:
        """单端样本的字符串表示。"""
        sample = Sample(name="test", r1_path=Path("test.fastq.gz"))

        s = str(sample)
        assert "test" in s
        assert "single" in s

    def test_repr(self) -> None:
        """repr 应返回详细的表示。"""
        sample = Sample(name="test", r1_path=Path("test.fastq.gz"))

        r = repr(sample)
        assert "Sample" in r
        assert "test" in r


class TestExtractSampleName:
    """测试样本名提取功能。"""

    def test_extract_from_r1_pattern(self) -> None:
        """从 R1 文件名提取样本名。"""
        name = Sample._extract_sample_name("sample001_R1.fastq.gz", "*_R1.fastq.gz")
        assert name == "sample001"

    def test_extract_from_r2_pattern(self) -> None:
        """从 R2 文件名提取样本名。"""
        name = Sample._extract_sample_name("sample001_R2.fastq.gz", "*_R2.fastq.gz")
        assert name == "sample001"

    def test_extract_with_different_extensions(self) -> None:
        """处理不同的扩展名。"""
        assert Sample._extract_sample_name("sample_R1.fq.gz", "*_R1.fastq.gz") == "sample"
        assert Sample._extract_sample_name("sample_R1.fastq", "*_R1.fastq.gz") == "sample"

    def test_extract_cleaned_sample_name(self) -> None:
        """从清洗后的文件名提取样本名。"""
        name = Sample._extract_cleaned_sample_name("sample001_paired_1.fastq")
        assert name == "sample001"
