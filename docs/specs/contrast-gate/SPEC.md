# Spec: contrast-gate

> Approved 2026-10-20. Consumer: nandomoreira.dev, feature `theme-modes`, the first real
> use of the Paper (light) variant.

## Problem

Nothing in the repo measures contrast. Measured on 2026-10-20 against `surface.base`,
`surface.raised` and `surface.elevated`, the palette fails WCAG 2.1 AA in 14 places,
almost all in the light variant:

| Variant | Role | Value | Worst ratio | Floor |
|---|---|---|---|---|
| light | `text.faint` | `#8A857C` | 2.94 | 3.0 |
| light | `surface.outline` | `#8A857C` | 2.94 | 3.0 |
| light | `accent.success` | `#047857` | 4.40 | 4.5 |
| light | `accent.info` | `#0969DA` | 4.17 | 4.5 |
| light | `ansi.normal.red` | `#CF222E` | 4.30 | 4.5 |
| light | `ansi.normal.blue` | `#0969DA` | 4.17 | 4.5 |
| light | `ansi.normal.magenta` | `#8250DF` | 4.05 | 4.5 |
| light | `ansi.normal.cyan` | `#1B7C83` | 3.96 | 4.5 |
| light | `ansi.normal.white` | `#8A857C` | 2.94 | 4.5 |
| light | `ansi.bright.green` | `#1A7F37` | 4.07 | 4.5 |
| light | `ansi.bright.blue` | `#218BFF` | 2.72 | 4.5 |
| light | `ansi.bright.magenta` | `#A475F9` | 2.60 | 4.5 |
| light | `ansi.bright.cyan` | `#3192AA` | 2.89 | 4.5 |
| dark | `ansi.bright.black` | `#6B6B74` | 3.36 | 4.5 |
| dark | `surface.outline` | `#3F3F46` | 1.70 | 3.0 |

Syntax roles point at palette paths, so the light Shiki/editor themes inherit the failures:
types (`ansi.bright.magenta`) and properties (`ansi.bright.cyan`) read at 2.6 to 3.5.

## Goals

- A gate that fails the test suite when any readable role drops below AA, in both variants.
- Fixed values that keep each color's hue, changing only OKLCH lightness (chroma only when
  the gamut forces it).
- A Shiki port, so websites use the exact palette instead of a GitHub theme.

## Requirements

1. [REQ-001] WHEN the suite runs THEN `scripts/lib/contrast.jq` SHALL compute the WCAG 2.1 contrast ratio of two `#RRGGBB` colors, matching the reference values (21:1 for black on white).
2. [REQ-002] WHEN the suite runs THEN `text.primary`, `text.muted` and every `accent.*` except `onPrimary` SHALL reach 4.5:1 on `surface.base`, `surface.raised` and `surface.elevated`, in both variants.
3. [REQ-003] WHEN the suite runs THEN `text.faint` and `surface.outline` SHALL reach 3:1 on the three surfaces (non-text: line numbers, disabled text, borders that delimit targets).
4. [REQ-004] WHEN the suite runs THEN `accent.onPrimary` on `accent.primary`, and `text.primary` on `surface.selection`, SHALL reach 4.5:1.
5. [REQ-005] WHEN the suite runs THEN every ANSI color SHALL reach 4.5:1 on the three surfaces, except the background slot of each variant: `ansi.normal.black` in dark and `ansi.bright.white` in light.
6. [REQ-006] WHEN the suite runs THEN every syntax role SHALL reach 4.5:1 on the three surfaces of each variant.
7. [REQ-007] WHEN the palette is fixed THEN it SHALL use the values below, and every port SHALL be regenerated from it.
8. [REQ-008] WHEN `scripts/build` runs THEN it SHALL write `ports/shiki/terminal-noir.json` (dark) and `ports/shiki/terminal-noir-paper.json` (light): TextMate theme JSON with `name`, `displayName`, `type`, `colors.editor.background` (`surface.base`), `colors.editor.foreground` (`text.primary`) and one `tokenColors` entry per syntax role.
9. [REQ-009] WHEN the Shiki port is added THEN it SHALL be registered in `ports.json` (category `editor`, variants dark and light), with a README in English and pt-BR and a screenshot, like every port.
10. [REQ-010] WHEN the README is read THEN it SHALL state the contrast floors and that the suite enforces them.

## Fixed values (REQ-007)

| Variant | Role | Before | After | Worst ratio after |
|---|---|---|---|---|
| light | `text.faint` | `#8A857C` | `#88837A` | 3.02 |
| light | `surface.outline` | `#8A857C` | `#88837A` | 3.02 |
| light | `accent.success` | `#047857` | `#0B7656` | 4.51 |
| light | `accent.info` | `#0969DA` | `#0663D0` | 4.55 |
| light | `ansi.normal.red` | `#CF222E` | `#CB1B2A` | 4.52 |
| light | `ansi.normal.blue` | `#0969DA` | `#0663D0` | 4.55 |
| light | `ansi.normal.magenta` | `#8250DF` | `#7B47D6` | 4.54 |
| light | `ansi.normal.cyan` | `#1B7C83` | `#08737A` | 4.50 |
| light | `ansi.normal.white` | `#8A857C` | `#6C675F` | 4.50 |
| light | `ansi.bright.green` | `#1A7F37` | `#0B772F` | 4.56 |
| light | `ansi.bright.blue` | `#218BFF` | `#0666C5` | 4.54 |
| light | `ansi.bright.magenta` | `#A475F9` | `#7C4BCB` | 4.52 |
| light | `ansi.bright.cyan` | `#3192AA` | `#0A7187` | 4.52 |
| dark | `ansi.bright.black` | `#6B6B74` | `#808089` | 4.53 |
| dark | `surface.outline` | `#3F3F46` | `#64646B` | 3.02 |

Computed by stepping OKLCH lightness by 0.002 (darker in light, lighter in dark) until the
worst of the three surfaces clears the floor.

## Edge cases

- Background slots stay exempt because a terminal paints them as background, never as text on it.
- `surface.border` stays decorative (1.24 dark, 1.36 light) and is not gated; the README says so.
- The site anchors (`#F5A623`, `#0B0B0C`, `#34D399`, light `#865700`) do not move.

## Decisions

| Question | Decision |
|---|---|
| Surfaces measured | All three: base, raised, elevated |
| Floor for faint and outline | 3:1 (non-text and inactive UI, WCAG 1.4.11) |
| ANSI exemptions | One background slot per variant |
| Shiki file names | `terminal-noir.json`, `terminal-noir-paper.json` |
| Contrast math | jq module, so the bats suite needs no new runtime |

## Out of scope

| Item | Reason |
|---|---|
| Light variants of the other ports | Separate decision per app |
| APCA | The consumer gates WCAG 2.1 |

## Test strategy

- `tests/contrast.bats`: library references, the four gates, and a proof the gate can fail (an old value).
- `tests/ports.bats`: Shiki files, colors, one token per role, AA on its own background.
- Existing suites: README tables, build freshness, registry, i18n, screenshots.

## Traceability

| ID | Description | Status |
|---|---|---|
| REQ-001 | Contrast library | Done |
| REQ-002 | Text and accents gate | Done |
| REQ-003 | Faint and outline gate | Done |
| REQ-004 | onPrimary and selection gate | Done |
| REQ-005 | ANSI gate | Done |
| REQ-006 | Syntax roles gate | Done |
| REQ-007 | Fixed palette | Done |
| REQ-008 | Shiki port | Done |
| REQ-009 | Shiki registry, READMEs, screenshot | Done |
| REQ-010 | README accessibility note | Done |
