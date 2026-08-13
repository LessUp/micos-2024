"""Documentation consistency tests for orchestration claims.

Verifies that README and AGENTS.md do not contradict the approved support
matrix: Python CLI is the sole production orchestrator, WDL is experimental,
and resume is unsupported.
"""

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent


def _read(name):
    return (REPO_ROOT / name).read_text(encoding="utf-8")


def test_readme_does_not_claim_wdl_as_production_workflow():
    """README must not describe WDL as the production workflow."""
    text = _read("README.md")
    # The old badge said "WDL-Workflow-green"
    assert "WDL-Workflow-green" not in text, "WDL badge must not say 'Workflow'"
    # The old feature line claimed WDL-based workflow with resume
    assert (
        "基于 WDL 的可重现分析流程，支持断点续传" not in text
    ), "README must not claim WDL-based workflow with resume support"


def test_readme_labels_wdl_as_experimental():
    """README must label WDL as experimental."""
    text = _read("README.md")
    assert "实验性" in text, "README must mention WDL experimental status"


def test_readme_states_resume_unsupported():
    """README must state that resume is unsupported."""
    text = _read("README.md")
    assert "不支持断点续传" in text, "README must state resume is unsupported"


def test_agents_labels_wdl_as_experimental():
    """AGENTS.md must label WDL as experimental."""
    text = _read("AGENTS.md")
    assert "实验性" in text, "AGENTS.md must mention WDL experimental status"


def test_shell_wrapper_documents_itself_as_wrapper():
    """run_full_analysis.sh must document itself as a wrapper."""
    text = _read("scripts/run_full_analysis.sh")
    assert (
        "包装层" in text or "wrapper" in text.lower()
    ), "Shell script must document itself as a wrapper around micos full-run"


def test_shell_wrapper_states_skip_resume_unsupported():
    """run_full_analysis.sh must state skip/resume are unsupported."""
    text = _read("scripts/run_full_analysis.sh")
    assert (
        "不再支持" in text
    ), "Shell script must state skip/resume are no longer supported"
