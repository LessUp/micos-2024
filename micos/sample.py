# -*- coding: utf-8 -*-
"""样本数据模型模块。

提供样本 (Sample) 领域对象，统一样本发现和处理逻辑。
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from typing import Self


@dataclass
class Sample:
    """样本数据模型 - 表示一个测序样本。

    这是一个**深层模块**，隐藏了样本发现和验证的复杂性：
    - 调用者只需知道样本名和路径
    - 样本发现、配对验证等逻辑被隐藏

    Attributes:
        name: 样本名称（唯一标识符）
        r1_path: R1 端 FASTQ 文件路径
        r2_path: R2 端 FASTQ 文件路径（单端测序时为 None）
        metadata: 样本元数据（可选）
    """

    name: str
    r1_path: Path
    r2_path: Path | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def discover_paired(
        cls,
        input_dir: Path,
        r1_pattern: str = "*_R1.fastq.gz",
        r2_suffix: str = "_R2.fastq.gz",
    ) -> list[Self]:
        """发现配对的 FASTQ 样本。

        Args:
            input_dir: 输入目录
            r1_pattern: R1 文件的 glob 模式
            r2_suffix: R2 文件的后缀（从 R1 文件名推导）

        Returns:
            发现的样本列表

        Example:
            >>> samples = Sample.discover_paired(Path("data/"))
            >>> for sample in samples:
            ...     print(f"{sample.name}: {sample.r1_path.name}")
        """
        samples: list[Self] = []

        for r1_file in sorted(input_dir.glob(r1_pattern)):
            # 提取样本名
            name = cls._extract_sample_name(r1_file.name, r1_pattern)

            # 推导 R2 文件路径
            r1_name = r1_file.name
            # 将 _R1 替换为 _R2
            r2_name = r1_name.replace("_R1", "_R2")
            r2_file = r1_file.parent / r2_name

            if r2_file.exists():
                samples.append(cls(name=name, r1_path=r1_file, r2_path=r2_file))
            else:
                # R2 不存在，创建单端样本
                samples.append(cls(name=name, r1_path=r1_file, r2_path=None))

        return samples

    @classmethod
    def discover_cleaned(
        cls,
        input_dir: Path,
        pattern: str = "*_paired_1.fastq",
    ) -> list[Self]:
        """发现清洗后的配对样本（KneadData 输出）。

        Args:
            input_dir: 输入目录（通常是 kneaddata 输出目录）
            pattern: _paired_1 文件的 glob 模式

        Returns:
            发现的样本列表
        """
        samples: list[Self] = []

        for r1_file in sorted(input_dir.glob(pattern)):
            # 提取样本名
            name = cls._extract_cleaned_sample_name(r1_file.name)

            # 推导 _paired_2 文件路径
            r2_name = r1_file.name.replace("_paired_1", "_paired_2")
            r2_file = r1_file.parent / r2_name

            if r2_file.exists():
                samples.append(cls(name=name, r1_path=r1_file, r2_path=r2_file))
            else:
                samples.append(cls(name=name, r1_path=r1_file, r2_path=None))

        return samples

    @staticmethod
    def _extract_sample_name(filename: str, pattern: str) -> str:
        """从文件名提取样本名。

        Args:
            filename: 文件名
            pattern: glob 模式（用于参考）

        Returns:
            样本名

        Example:
            >>> Sample._extract_sample_name("sample001_R1.fastq.gz", "*_R1.fastq.gz")
            'sample001'
        """
        # 移除扩展名
        name = filename
        for ext in [".fastq.gz", ".fq.gz", ".fastq", ".fq"]:
            if name.endswith(ext):
                name = name[: -len(ext)]
                break

        # 移除 _R1 或 _R2 后缀
        name = name.replace("_R1", "").replace("_R2", "")

        return name

    @staticmethod
    def _extract_cleaned_sample_name(filename: str) -> str:
        """从清洗后的文件名提取样本名。

        Args:
            filename: 文件名（如 sample001_paired_1.fastq）

        Returns:
            样本名
        """
        # 移除 _paired_1 或 _paired_2 后缀
        name = filename
        for suffix in ["_paired_1.fastq", "_paired_2.fastq"]:
            if suffix in name:
                name = name.replace(suffix, "")
                break

        return name

    @property
    def is_paired(self) -> bool:
        """检查是否为双端测序。"""
        return self.r2_path is not None

    @property
    def files(self) -> list[Path]:
        """获取所有 FASTQ 文件路径。"""
        files = [self.r1_path]
        if self.r2_path:
            files.append(self.r2_path)
        return files

    def validate(self) -> bool:
        """验证样本文件是否存在。

        Returns:
            True 如果所有文件都存在

        Raises:
            FileNotFoundError: 如果文件不存在
        """
        for file_path in self.files:
            if not file_path.exists():
                raise FileNotFoundError(f"样本文件不存在: {file_path}")
        return True

    def __str__(self) -> str:
        """返回样本的字符串表示。"""
        if self.is_paired:
            return f"Sample({self.name}, paired: {self.r1_path.name}, {self.r2_path.name})"
        return f"Sample({self.name}, single: {self.r1_path.name})"

    def __repr__(self) -> str:
        """返回样本的详细表示。"""
        return f"Sample(name={self.name!r}, r1_path={self.r1_path!r}, r2_path={self.r2_path!r})"
