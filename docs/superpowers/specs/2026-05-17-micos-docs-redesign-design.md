# MICOS-2024 Docs Redesign Spec

## Goal

Rebuild the GitHub Pages site into a production-grade bilingual technical whitepaper and architecture showcase that feels academically rigorous, visually sharp, and structurally aligned with the `kimi-cli` documentation stack.

## Reference Baseline

The redesign keeps the same documentation foundation used by `/home/shane/dev/kimi-cli/docs`:

- VitePress 1.5
- `vitepress-plugin-mermaid`
- `vitepress-plugin-llms`
- custom theme entry under `docs/.vitepress/theme`
- bilingual `zh` / `en` locale structure
- lightweight CSS-first theme overrides instead of a component-heavy app shell

## Current Gaps

1. The current site copies the baseline mechanically but does not use it to tell a stronger MICOS story.
2. The information architecture is thin: readers do not get a guided path from overview to architecture to operation to reference.
3. The homepage is feature-card centric instead of whitepaper centric.
4. Diagrams and SVG assets are not designed as a unified visual system and are fragile across light/dark themes.
5. The docs underrepresent the actual project surface: WDL orchestration, containers, sample/config model, pipeline stages, research grounding, and citations.

## Target Information Architecture

Each locale should be reorganized around six reader journeys:

1. **Overview** — what MICOS is, who it is for, why it exists
2. **Academy** — conceptual onboarding, pipeline stages, data model, output interpretation
3. **Architecture** — system design, workflow graph, runtime topology, reproducibility model
4. **Guides** — quickstart, configuration, deployment, troubleshooting
5. **Reference** — CLI/entrypoints, directories, configs, workflow stages
6. **Research** — citations, related projects, evolution notes, design trade-offs

## UX / Visual Design

The site should feel like an open-source whitepaper:

- restrained but premium typography
- strong spacing rhythm
- layered cards instead of flat boxes
- subtle grid/noise accents, not loud gradients
- diagrams embedded into the narrative, not dumped below the fold
- dark/light themes with consistent contrast
- tokenized palette inspired by microbiome / systems biology aesthetics

## Theme Strategy

The site should remain CSS-first, but introduce focused custom components for high-value surfaces:

- `SiteHero` for homepage masthead
- `SiteSection` wrappers for whitepaper sections
- `MetricGrid` for key metrics
- `FlowStageGrid` for staged pipeline explanation
- `ThemeAsset` for light/dark-aware SVG illustration switching
- `ReferenceList` for paper/tool/repo citations

This preserves VitePress simplicity while enabling a significantly more intentional UI system.

## Content Strategy

The docs should add and/or rewrite content in both Chinese and English for:

- homepage overview
- getting started
- architecture overview
- pipeline stages
- configuration system
- execution and deployment
- FAQ / troubleshooting refresh
- citations / related work / evolution notes

Content must stay grounded in the repository’s real structure: `micos/`, `steps/`, `scripts/`, `config/`, `containers/`, `deploy/`, and `tests/`.

## Diagram Strategy

1. Keep Mermaid for process and architecture diagrams.
2. Introduce CSS/HTML “diagram cards” for homepage-level visuals to guarantee theme compatibility.
3. Replace decorative SVG dependence with theme-aware assets using separate light/dark sources when needed.
4. Use monochrome/duotone SVG fills with deliberate contrast instead of multicolor gradients that wash out.

## Non-Goals

- No migration away from VitePress.
- No custom frontend app outside the docs site.
- No speculative claims about features that are not present in the repository.

## Deliverables

- redesigned VitePress theme and styling system
- new bilingual navigation and sidebar structure
- new bilingual homepage
- new bilingual academy / architecture / research sections
- fixed theme-aware visual assets
- validated docs build output
