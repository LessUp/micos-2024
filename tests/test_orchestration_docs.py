"""Documentation consistency tests for orchestration claims.

The approved support matrix is:

- Python CLI (`micos full-run`) is the sole production orchestrator
- WDL is experimental
- resume is unsupported
"""

from __future__ import annotations

from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def _read(relative_path: str) -> str:
    return (PROJECT_ROOT / relative_path).read_text(encoding="utf-8")


@pytest.fixture(scope="module")
def readme() -> str:
    return _read("README.md")


@pytest.fixture(scope="module")
def agents() -> str:
    return _read("AGENTS.md")


@pytest.fixture(scope="module")
def full_run_wrapper() -> str:
    return _read("scripts/run_full_analysis.sh")


def test_readme_does_not_claim_wdl_as_production_workflow(readme: str) -> None:
    """README must not describe WDL as the production workflow."""
    assert "WDL-Workflow-green" not in readme
    assert "基于 WDL 的可重现分析流程，支持断点续传" not in readme


def test_readme_labels_wdl_as_experimental(readme: str) -> None:
    """README must label WDL as experimental single-step reference."""
    assert "WDL 任务定义（实验性）" in readme
    assert "实验性单步骤参考" in readme


def test_readme_states_resume_unsupported(readme: str) -> None:
    """README must state that resume is unsupported."""
    assert "不支持断点续传" in readme


def test_agents_labels_wdl_as_experimental(agents: str) -> None:
    """AGENTS.md must label WDL as experimental single-step reference."""
    assert "WDL 任务定义（实验性单步骤参考）" in agents
    assert "不是生产工作流" in agents


def test_shell_wrapper_documents_itself_as_wrapper(full_run_wrapper: str) -> None:
    """run_full_analysis.sh must document itself as a wrapper."""
    assert "包装层" in full_run_wrapper


def test_shell_wrapper_states_skip_resume_unsupported(full_run_wrapper: str) -> None:
    """run_full_analysis.sh must state skip/resume are unsupported."""
    assert "--skip/--resume-from 当前不再支持" in full_run_wrapper
