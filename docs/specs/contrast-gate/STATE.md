---
feature: contrast-gate
phase: review
started_at: 2026-10-20
depth: standard
spec_path: docs/specs/contrast-gate/SPEC.md
plan_path: docs/plans/2026-10-20-contrast-gate.md
decisions:
  - "WCAG 2.1 AA on base, raised and elevated, both variants"
  - "faint and outline at 3:1; one ANSI background slot exempt per variant"
  - "Fixes keep hue, step OKLCH lightness only"
  - "Shiki port with terminal-noir.json and terminal-noir-paper.json"
blockers: []
transitions:
  - "2026-10-20: spec approved by Fernando (all of Paper must be accessible, not only code)"
  - "2026-10-20: plan-complete, 5 tasks"
  - "2026-10-20: implement done (Claude fallback: Grok 402 balance exhausted, agy unavailable); 52 bats + 46 site tests green"
---

# State: contrast-gate

Blocks Task 8 of nandomoreira.dev `theme-modes`, which vendors the Shiki port and the
fixed Paper values.

## Open notes (low, from the consequences review)

- `scripts/ports/vscode.sh` maps `editorWhitespace.foreground` and `scripts/ports/p10k.sh` the
  first-prompt gap to `surface.outline`, now 3.37:1 in dark: more visible than a decorative mark.
  Decide whether they move to `surface.border` or an alpha.
- Dark `ansi.bright.black` and light `ansi.normal.white` changed lightness: third-party apps that
  paint text on colors 8 or 7 as a background lose contrast (none of our ports do).
- `site/` Vitest keeps a stale `import.meta.glob` in `node_modules/.vitest-cache` when a port is
  added; `--no-fsModuleCache` or a clean cache fixes it.
