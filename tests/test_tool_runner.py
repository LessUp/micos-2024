# -*- coding: utf-8 -*-
"""测试工具执行接口模块。"""

from __future__ import annotations

import subprocess
from pathlib import Path

import pytest

from micos.tool_runner import (
    MockToolRunner,
    SubprocessToolRunner,
    ToolResult,
    get_default_runner,
    set_default_runner,
    run_command,
)


class TestToolResult:
    """测试 ToolResult 类。"""

    def test_success_returns_true_for_zero_return_code(self) -> None:
        """返回码为 0 时 success 应为 True。"""
        result = ToolResult(return_code=0)
        assert result.success is True

    def test_success_returns_false_for_non_zero_return_code(self) -> None:
        """返回码非 0 时 success 应为 False。"""
        result = ToolResult(return_code=1)
        assert result.success is False

    def test_default_values(self) -> None:
        """测试默认值。"""
        result = ToolResult(return_code=0)
        assert result.stdout == ""
        assert result.stderr == ""
        assert result.output_files == []


class TestMockToolRunner:
    """测试 MockToolRunner 类。"""

    def test_run_records_call(self) -> None:
        """run 应记录调用。"""
        runner = MockToolRunner()
        runner.run(["echo", "hello"])

        assert len(runner.calls) == 1
        assert runner.calls[0][0] == "echo"
        assert runner.calls[0][1] == ("echo", "hello")

    def test_run_returns_default_result(self) -> None:
        """run 应返回默认结果。"""
        runner = MockToolRunner()
        result = runner.run(["echo", "hello"])

        assert result.success is True
        assert result.return_code == 0

    def test_run_returns_preset_result(self) -> None:
        """run 应返回预设结果。"""
        runner = MockToolRunner()
        runner.add_response("fastqc", ToolResult(0, "FastQC done", ""))

        result = runner.run(["fastqc", "input.fastq"])

        assert result.success is True
        assert result.stdout == "FastQC done"

    def test_run_raises_on_non_zero_with_check(self) -> None:
        """check=True 且返回码非零时应抛出异常。"""
        runner = MockToolRunner()
        runner.add_response("failing_tool", ToolResult(1, "", "error"))

        with pytest.raises(subprocess.CalledProcessError):
            runner.run(["failing_tool", "args"], check=True)

    def test_run_does_not_raise_with_check_false(self) -> None:
        """check=False 时即使返回码非零也不抛出异常。"""
        runner = MockToolRunner()
        runner.add_response("failing_tool", ToolResult(1, "", "error"))

        result = runner.run(["failing_tool", "args"], check=False)

        assert result.return_code == 1

    def test_was_called(self) -> None:
        """was_called 应正确检测调用。"""
        runner = MockToolRunner()
        runner.run(["fastqc", "input.fastq"])
        runner.run(["kraken2", "input.fastq"])

        assert runner.was_called("fastqc") is True
        assert runner.was_called("kraken2") is True
        assert runner.was_called("humann") is False

    def test_get_call_count(self) -> None:
        """get_call_count 应正确计数。"""
        runner = MockToolRunner()
        runner.run(["echo", "hello"])
        runner.run(["echo", "world"])
        runner.run(["ls"])

        assert runner.get_call_count("echo") == 2
        assert runner.get_call_count("ls") == 1
        assert runner.get_call_count("cat") == 0

    def test_reset_clears_state(self) -> None:
        """reset 应清除所有状态。"""
        runner = MockToolRunner()
        runner.add_response("tool", ToolResult(0, "ok", ""))
        runner.run(["tool"])

        runner.reset()

        assert len(runner.calls) == 0
        assert runner.was_called("tool") is False


class TestSubprocessToolRunner:
    """测试 SubprocessToolRunner 类。"""

    def test_run_echo_command(self) -> None:
        """测试运行简单的 echo 命令。"""
        runner = SubprocessToolRunner(verbose=False)
        result = runner.run(["echo", "hello"], capture=True)

        assert result.success is True
        assert "hello" in result.stdout

    def test_run_raises_on_nonexistent_command(self) -> None:
        """命令不存在时应抛出 FileNotFoundError。"""
        runner = SubprocessToolRunner(verbose=False)

        with pytest.raises(FileNotFoundError):
            runner.run(["nonexistent_command_xyz123"])

    def test_run_with_check_false(self) -> None:
        """check=False 时失败命令不应抛出异常。"""
        runner = SubprocessToolRunner(verbose=False)

        # 使用一个会失败的命令
        result = runner.run(["ls", "/nonexistent_dir_xyz123"], check=False, capture=True)

        assert result.return_code != 0


class TestGlobalRunner:
    """测试全局执行器管理。"""

    def test_get_default_runner_returns_subprocess_runner(self) -> None:
        """默认执行器应为 SubprocessToolRunner。"""
        runner = get_default_runner()
        assert isinstance(runner, SubprocessToolRunner)

    def test_set_default_runner(self) -> None:
        """set_default_runner 应设置全局执行器。"""
        mock = MockToolRunner()
        set_default_runner(mock)

        assert get_default_runner() is mock

        # 恢复默认
        set_default_runner(None)
        assert isinstance(get_default_runner(), SubprocessToolRunner)

    def test_run_command_uses_global_runner(self) -> None:
        """run_command 应使用全局执行器。"""
        mock = MockToolRunner()
        mock.add_response("test", ToolResult(0, "ok", ""))
        set_default_runner(mock)

        result = run_command(["test"])

        assert result.success is True
        assert mock.was_called("test")

        # 恢复默认
        set_default_runner(None)

    def test_run_command_with_explicit_runner(self) -> None:
        """run_command 可指定执行器。"""
        mock = MockToolRunner()
        mock.add_response("explicit", ToolResult(0, "explicit result", ""))

        result = run_command(["explicit"], runner=mock)

        assert result.stdout == "explicit result"
