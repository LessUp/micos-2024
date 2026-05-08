# -*- coding: utf-8 -*-
"""工具执行接口模块。

提供外部工具调用的抽象层，使核心逻辑可测试。
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING, Sequence

if TYPE_CHECKING:
    pass


@dataclass
class ToolResult:
    """工具执行结果。

    Attributes:
        return_code: 命令返回码（0 表示成功）
        stdout: 标准输出内容
        stderr: 标准错误内容
        output_files: 生成的输出文件列表
    """

    return_code: int
    stdout: str = ""
    stderr: str = ""
    output_files: list[Path] = field(default_factory=list)

    @property
    def success(self) -> bool:
        """检查执行是否成功。"""
        return self.return_code == 0


class ToolRunner(ABC):
    """工具执行接口 - 外部工具调用的抽象层。

    这是一个**深层模块**的接口，隐藏了工具执行的复杂性：
    - 调用者只需知道 command 和 output_dir
    - 实现细节（subprocess、容器、模拟）被隐藏

    接口设计原则：
    - 一个 adapter = 假设的接缝
    - 两个 adapter = 真正的接缝
    - MockToolRunner 用于测试，SubprocessToolRunner 用于生产
    """

    @abstractmethod
    def run(
        self,
        command: Sequence[str],
        output_dir: Path | None = None,
        *,
        check: bool = True,
        capture: bool = True,
    ) -> ToolResult:
        """执行命令并返回结果。

        Args:
            command: 要执行的命令（列表形式）
            output_dir: 输出目录（用于跟踪生成的文件）
            check: 是否在返回码非零时抛出异常
            capture: 是否捕获输出

        Returns:
            ToolResult 包含执行结果

        Raises:
            subprocess.CalledProcessError: 当 check=True 且返回码非零时
            FileNotFoundError: 当命令不存在时
        """
        ...


class SubprocessToolRunner(ToolRunner):
    """真实执行 - 调用 subprocess。

    这是 ToolRunner 接口的生产实现，用于实际运行外部工具。
    """

    def __init__(self, verbose: bool = False):
        """初始化执行器。

        Args:
            verbose: 是否实时打印输出
        """
        self.verbose = verbose

    def run(
        self,
        command: Sequence[str],
        output_dir: Path | None = None,
        *,
        check: bool = True,
        capture: bool = True,
    ) -> ToolResult:
        """执行命令并返回结果。"""
        import subprocess
        import logging

        logger = logging.getLogger(__name__)
        logger.info(f"执行命令: {' '.join(command)}")

        try:
            if self.verbose and capture:
                # 实时输出模式
                process = subprocess.Popen(
                    command,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True,
                )
                stdout_lines = []
                if process.stdout:
                    for line in iter(process.stdout.readline, ""):
                        stdout_lines.append(line)
                        print(line, end="")  # 实时输出
                    process.stdout.close()

                return_code = process.wait()
                stdout_text = "".join(stdout_lines)
                stderr_text = ""
            elif capture:
                # 捕获输出模式
                result = subprocess.run(
                    command,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                return_code = result.returncode
                stdout_text = result.stdout
                stderr_text = result.stderr
            else:
                # 不捕获输出（直接输出到终端）
                result = subprocess.run(
                    command,
                    check=False,
                )
                return_code = result.returncode
                stdout_text = ""
                stderr_text = ""

            # 收集输出文件
            output_files = []
            if output_dir and output_dir.exists():
                output_files = list(output_dir.iterdir())

            tool_result = ToolResult(
                return_code=return_code,
                stdout=stdout_text,
                stderr=stderr_text,
                output_files=output_files,
            )

            if check and return_code != 0:
                logger.error(f"命令执行失败，返回码: {return_code}")
                raise subprocess.CalledProcessError(return_code, command, stdout_text, stderr_text)

            return tool_result

        except FileNotFoundError as e:
            logger.error(f"命令不存在: {command[0]}")
            raise


class MockToolRunner(ToolRunner):
    """模拟执行 - 用于测试。

    这是 ToolRunner 接口的测试实现，不会真正执行命令。
    可以预设返回结果，并记录所有调用以供验证。

    Example:
        >>> runner = MockToolRunner()
        >>> runner.add_response("fastqc", ToolResult(0, "done", ""))
        >>> result = runner.run(["fastqc", "input.fastq"])
        >>> result.success
        True
        >>> runner.was_called("fastqc")
        True
    """

    def __init__(self) -> None:
        """初始化模拟执行器。"""
        self._calls: list[tuple[str, tuple[str, ...], dict]] = []
        self._responses: dict[str, ToolResult] = {}
        self._default_result = ToolResult(0, "", "")

    def add_response(self, tool_name: str, result: ToolResult) -> None:
        """预设工具的返回结果。

        Args:
            tool_name: 工具名称（命令的第一个参数）
            result: 预设的返回结果
        """
        self._responses[tool_name] = result

    def set_default_result(self, result: ToolResult) -> None:
        """设置默认返回结果（当没有预设时使用）。"""
        self._default_result = result

    def run(
        self,
        command: Sequence[str],
        output_dir: Path | None = None,
        *,
        check: bool = True,
        capture: bool = True,
    ) -> ToolResult:
        """模拟执行命令并返回预设结果。"""
        import subprocess

        tool_name = command[0] if command else ""
        args = tuple(command)

        # 记录调用
        self._calls.append((tool_name, args, {"output_dir": output_dir}))

        # 获取预设结果或默认结果
        result = self._responses.get(tool_name, self._default_result)

        # 如果需要检查且返回码非零，抛出异常
        if check and not result.success:
            raise subprocess.CalledProcessError(
                result.return_code, list(command), result.stdout, result.stderr
            )

        return result

    @property
    def calls(self) -> list[tuple[str, tuple[str, ...], dict]]:
        """获取所有调用记录。"""
        return self._calls

    def was_called(self, tool_name: str) -> bool:
        """检查指定工具是否被调用过。"""
        return any(call[0] == tool_name for call in self._calls)

    def get_call_count(self, tool_name: str) -> int:
        """获取指定工具的调用次数。"""
        return sum(1 for call in self._calls if call[0] == tool_name)

    def get_calls_for(self, tool_name: str) -> list[tuple[str, tuple[str, ...], dict]]:
        """获取指定工具的所有调用记录。"""
        return [call for call in self._calls if call[0] == tool_name]

    def reset(self) -> None:
        """重置所有调用记录和预设响应。"""
        self._calls.clear()
        self._responses.clear()


# 全局默认执行器（向后兼容）
_default_runner: ToolRunner | None = None


def get_default_runner() -> ToolRunner:
    """获取全局默认执行器。"""
    global _default_runner
    if _default_runner is None:
        _default_runner = SubprocessToolRunner(verbose=True)
    return _default_runner


def set_default_runner(runner: ToolRunner | None) -> None:
    """设置全局默认执行器（主要用于测试）。"""
    global _default_runner
    _default_runner = runner


def run_command(
    command: Sequence[str],
    output_dir: Path | None = None,
    runner: ToolRunner | None = None,
) -> ToolResult:
    """执行命令的便捷函数。

    这是一个向后兼容的函数，使用全局默认执行器。
    新代码应直接使用 ToolRunner 实例。

    Args:
        command: 要执行的命令
        output_dir: 输出目录
        runner: 指定执行器（None 使用全局默认）

    Returns:
        ToolResult 执行结果
    """
    active_runner = runner or get_default_runner()
    return active_runner.run(command, output_dir)
