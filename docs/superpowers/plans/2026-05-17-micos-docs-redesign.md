# MICOS-2024 Docs Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the MICOS-2024 GitHub Pages site into a bilingual whitepaper-grade documentation experience on top of the same VitePress stack used by kimi-cli.

**Architecture:** Keep the current docs site on VitePress, but replace the shallow page structure with a content-rich, component-assisted information architecture. The new theme stays CSS-first, adds a small set of Vue components for hero/metrics/diagram/citation surfaces, and rewrites the site content around overview, academy, architecture, guides, reference, and research journeys.

**Tech Stack:** VitePress 1.5, Vue 3, TypeScript, vitepress-plugin-mermaid, vitepress-plugin-llms, Markdown, CSS custom properties

---

### Task 1: Audit and realign the docs shell

**Files:**
- Modify: `docs/package.json`
- Modify: `docs/.vitepress/config.ts`
- Modify: `docs/.vitepress/theme/index.ts`
- Modify: `docs/.vitepress/theme/style.css`

- [ ] **Step 1: Snapshot the current docs shell**

Run: `git --no-pager diff -- docs/package.json docs/.vitepress/config.ts docs/.vitepress/theme/index.ts docs/.vitepress/theme/style.css`
Expected: shows the pre-redesign docs shell so the refactor has a clear baseline.

- [ ] **Step 2: Align scripts and theme hooks with the kimi-cli baseline**

Update the shell so the docs package retains `dev`, `build`, and `preview` commands and the theme entry can register custom components:

```ts
import DefaultTheme from 'vitepress/theme'
import type { Theme } from 'vitepress'
import './style.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    // register custom docs components here
  },
} satisfies Theme
```

- [ ] **Step 3: Redefine locale navigation and sidebars**

Replace the current shallow nav with sections for overview, academy, architecture, guides, reference, and research. Use concrete routes such as:

```ts
{ text: 'Academy', link: '/en/academy/pipeline-foundations', activeMatch: '/en/academy/' }
{ text: 'Architecture', link: '/en/architecture/system-overview', activeMatch: '/en/architecture/' }
{ text: 'Research', link: '/en/research/citations', activeMatch: '/en/research/' }
```

- [ ] **Step 4: Build the docs shell**

Run: `npm --prefix docs run build`
Expected: VitePress build completes successfully.

- [ ] **Step 5: Commit shell refactor**

```bash
git add docs/package.json docs/.vitepress/config.ts docs/.vitepress/theme/index.ts docs/.vitepress/theme/style.css
git commit -m "feat(docs): rebuild vitepress shell for whitepaper IA"
```

### Task 2: Add reusable whitepaper components

**Files:**
- Create: `docs/.vitepress/theme/components/SiteHero.vue`
- Create: `docs/.vitepress/theme/components/SiteSection.vue`
- Create: `docs/.vitepress/theme/components/MetricGrid.vue`
- Create: `docs/.vitepress/theme/components/FlowStageGrid.vue`
- Create: `docs/.vitepress/theme/components/ThemeAsset.vue`
- Create: `docs/.vitepress/theme/components/ReferenceList.vue`
- Modify: `docs/.vitepress/theme/index.ts`
- Modify: `docs/.vitepress/theme/style.css`

- [ ] **Step 1: Write the component registration**

Add explicit component registration:

```ts
app.component('SiteHero', SiteHero)
app.component('SiteSection', SiteSection)
app.component('MetricGrid', MetricGrid)
app.component('FlowStageGrid', FlowStageGrid)
app.component('ThemeAsset', ThemeAsset)
app.component('ReferenceList', ReferenceList)
```

- [ ] **Step 2: Implement the hero and section primitives**

Create Vue components that accept props for eyebrow/title/lede/actions and section labels so pages can stay markdown-centric.

- [ ] **Step 3: Implement metrics, stage grid, and theme-aware asset helpers**

The theme-aware asset component should switch image sources by theme:

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useData, withBase } from 'vitepress'

const props = defineProps<{ light: string; dark: string; alt: string }>()
const { isDark } = useData()
const src = computed(() => withBase(isDark.value ? props.dark : props.light))
</script>
```

- [ ] **Step 4: Implement reference list rendering**

Support citation entries with title, authors, venue, year, link, and note.

- [ ] **Step 5: Rebuild docs**

Run: `npm --prefix docs run build`
Expected: components render without VitePress import or hydration errors.

- [ ] **Step 6: Commit component system**

```bash
git add docs/.vitepress/theme
git commit -m "feat(docs): add reusable whitepaper theme components"
```

### Task 3: Rebuild visual system and theme-safe assets

**Files:**
- Create: `docs/public/illustrations/pipeline-overview-light.svg`
- Create: `docs/public/illustrations/pipeline-overview-dark.svg`
- Create: `docs/public/illustrations/runtime-topology-light.svg`
- Create: `docs/public/illustrations/runtime-topology-dark.svg`
- Modify: `docs/media/logo.svg`
- Modify: `docs/media/favicon.svg`
- Modify: `docs/.vitepress/theme/style.css`

- [ ] **Step 1: Replace fragile gradients with controlled theme variants**

Use SVG files with deliberate light/dark fills instead of relying on identical gradients in both themes.

- [ ] **Step 2: Define a tokenized design system in CSS**

Add variables for:

```css
--micos-surface-1
--micos-surface-2
--micos-grid-line
--micos-glow
--micos-success
--micos-warning
```

- [ ] **Step 3: Style homepage and doc primitives**

Create styles for cards, callouts, diagram rails, reference blocks, and metric bands with strong dark/light contrast.

- [ ] **Step 4: Build docs and inspect output**

Run: `npm --prefix docs run build`
Expected: build succeeds and generated assets include the new illustrations.

- [ ] **Step 5: Commit the visual system**

```bash
git add docs/public docs/media docs/.vitepress/theme/style.css
git commit -m "feat(docs): add theme-safe visual system and illustrations"
```

### Task 4: Rewrite the bilingual homepage

**Files:**
- Modify: `docs/index.md`
- Modify: `docs/en/index.md`
- Modify: `docs/zh/index.md`

- [ ] **Step 1: Rebuild the root language redirect**

Keep the language redirect but preserve saved preference first, then browser locale.

- [ ] **Step 2: Rewrite the English homepage**

Use the new components to cover:

```md
<SiteHero ... />
<MetricGrid :items="..." />
<FlowStageGrid :stages="..." />
<ReferenceList :items="..." />
```

The homepage must present value proposition, architecture, execution path, reproducibility guarantees, and research grounding.

- [ ] **Step 3: Rewrite the Chinese homepage**

Mirror the English structure with idiomatic Chinese copy, not direct machine-translation phrasing.

- [ ] **Step 4: Build docs**

Run: `npm --prefix docs run build`
Expected: both locales render with the new homepage sections.

- [ ] **Step 5: Commit homepage rewrite**

```bash
git add docs/index.md docs/en/index.md docs/zh/index.md
git commit -m "feat(docs): rewrite homepage as technical whitepaper"
```

### Task 5: Add academy and architecture sections

**Files:**
- Create: `docs/en/academy/pipeline-foundations.md`
- Create: `docs/en/academy/data-products.md`
- Create: `docs/en/architecture/system-overview.md`
- Create: `docs/en/architecture/runtime-topology.md`
- Create: `docs/zh/academy/pipeline-foundations.md`
- Create: `docs/zh/academy/data-products.md`
- Create: `docs/zh/architecture/system-overview.md`
- Create: `docs/zh/architecture/runtime-topology.md`
- Modify: `docs/.vitepress/config.ts`

- [ ] **Step 1: Write the academy pages**

Explain stage-by-stage analysis flow, core inputs/outputs, and how readers should interpret deliverables.

- [ ] **Step 2: Write the architecture pages**

Cover the relation between Python package, WDL steps, scripts, config templates, containers, and deploy assets.

- [ ] **Step 3: Include diagrams**

Embed Mermaid or `ThemeAsset` visual blocks for pipeline flow and runtime topology.

- [ ] **Step 4: Build docs**

Run: `npm --prefix docs run build`
Expected: new sections are reachable from nav/sidebar and all routes build.

- [ ] **Step 5: Commit academy/architecture content**

```bash
git add docs/en/academy docs/en/architecture docs/zh/academy docs/zh/architecture docs/.vitepress/config.ts
git commit -m "feat(docs): add academy and architecture sections"
```

### Task 6: Refresh guides, reference, and research sections

**Files:**
- Create: `docs/en/guides/deployment.md`
- Create: `docs/en/reference/project-structure.md`
- Create: `docs/en/research/citations.md`
- Create: `docs/en/research/related-projects.md`
- Create: `docs/en/research/evolution-notes.md`
- Create: `docs/zh/guides/deployment.md`
- Create: `docs/zh/reference/project-structure.md`
- Create: `docs/zh/research/citations.md`
- Create: `docs/zh/research/related-projects.md`
- Create: `docs/zh/research/evolution-notes.md`
- Modify: `docs/en/guides/getting-started.md`
- Modify: `docs/en/configuration.md`
- Modify: `docs/en/reference/cli.md`
- Modify: `docs/en/faq.md`
- Modify: `docs/en/troubleshooting.md`
- Modify: `docs/zh/guides/getting-started.md`
- Modify: `docs/zh/configuration.md`
- Modify: `docs/zh/reference/cli.md`
- Modify: `docs/zh/faq.md`
- Modify: `docs/zh/troubleshooting.md`
- Modify: `docs/.vitepress/config.ts`

- [ ] **Step 1: Rewrite existing operational pages**

Tighten getting started, configuration, CLI, FAQ, and troubleshooting around the real repo entry points and sample commands.

- [ ] **Step 2: Add deployment and project-structure references**

Document `deploy/`, `containers/`, `config/`, `steps/`, and `tests/`.

- [ ] **Step 3: Add research pages**

Include literature citations, related open-source project comparisons, and evolution notes grounded in current repository direction.

- [ ] **Step 4: Build docs**

Run: `npm --prefix docs run build`
Expected: all pages build and local search indexes include the new content.

- [ ] **Step 5: Commit content expansion**

```bash
git add docs/en docs/zh docs/.vitepress/config.ts
git commit -m "feat(docs): expand guides reference and research content"
```

### Task 7: Final verification and branch completion

**Files:**
- Modify: `docs/superpowers/specs/2026-05-17-micos-docs-redesign-design.md`
- Modify: `docs/superpowers/plans/2026-05-17-micos-docs-redesign.md`

- [ ] **Step 1: Run the docs build**

Run: `npm --prefix docs run build`
Expected: PASS

- [ ] **Step 2: Run repository tests needed for safety**

Run: `pytest tests/ -v`
Expected: PASS or known baseline documented before proceeding.

- [ ] **Step 3: Review git diff**

Run: `git --no-pager diff --stat`
Expected: only intentional docs and support changes are present.

- [ ] **Step 4: Commit final plan/spec updates**

```bash
git add docs/superpowers/specs/2026-05-17-micos-docs-redesign-design.md docs/superpowers/plans/2026-05-17-micos-docs-redesign.md
git commit -m "docs: add redesign spec and implementation plan"
```

- [ ] **Step 5: Merge and publish**

```bash
git checkout master
git merge --ff-only <working-branch>
git push origin master
```
