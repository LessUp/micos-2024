"""Regression tests for the redesigned VitePress documentation site."""

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DOCS_ROOT = PROJECT_ROOT / "docs"


def test_whitepaper_theme_components_exist() -> None:
    """The docs theme should expose the new whitepaper component set."""
    components_dir = DOCS_ROOT / ".vitepress" / "theme" / "components"

    assert (components_dir / "SiteHero.vue").exists()
    assert (components_dir / "SiteSection.vue").exists()
    assert (components_dir / "MetricGrid.vue").exists()
    assert (components_dir / "FlowStageGrid.vue").exists()
    assert (components_dir / "ThemeAsset.vue").exists()
    assert (components_dir / "ReferenceList.vue").exists()


def test_bilingual_whitepaper_sections_exist() -> None:
    """Both locales should expose academy, architecture, and research sections."""
    expected_pages = [
        DOCS_ROOT / "en" / "academy" / "pipeline-foundations.md",
        DOCS_ROOT / "en" / "architecture" / "system-overview.md",
        DOCS_ROOT / "en" / "research" / "citations.md",
        DOCS_ROOT / "zh" / "academy" / "pipeline-foundations.md",
        DOCS_ROOT / "zh" / "architecture" / "system-overview.md",
        DOCS_ROOT / "zh" / "research" / "citations.md",
    ]

    for page in expected_pages:
        assert page.exists(), f"missing page: {page.relative_to(PROJECT_ROOT)}"


def test_theme_assets_and_navigation_are_upgraded() -> None:
    """The docs shell should register new IA sections and theme-aware illustrations."""
    config_text = (DOCS_ROOT / ".vitepress" / "config.ts").read_text(encoding="utf-8")

    assert "Academy" in config_text
    assert "Architecture" in config_text
    assert "Research" in config_text
    assert "学院" in config_text
    assert "架构" in config_text
    assert "研究" in config_text

    assert (DOCS_ROOT / "public" / "illustrations" / "pipeline-overview-light.svg").exists()
