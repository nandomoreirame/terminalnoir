# Spec: upstream-distribution

> Approved 2026-10-20 by Fernando. Strategy to get Terminal Noir into the theme
> catalogs of the apps it ports to, instead of only "copy this file" READMEs.

## Problem

Every port today is installed by hand from this repository. Users discover themes inside
their apps (Noctalia's palette picker, `ghostty +list-themes`, the VS Code and Open VSX
extension views, Obsidian's theme browser), and Terminal Noir is in none of them.

## Channel research (2026-10-20)

| Port | Channel | How it is accepted | Decision |
|---|---|---|---|
| Noctalia | `noctalia-dev/community-palettes` | PR with `Terminal Noir/Terminal Noir.json`; dark and light, 16 roles and a `terminal` block; CI checks roles, `#rrggbb` and each `mOnX` on `mX` (fails under 2:1); dark and light screenshots in the PR; one palette per PR | Phase 1 |
| Ghostty and ~30 terminals | `mbadolato/iTerm2-Color-Schemes` | PR with `yaml/<Name>.yml` (Gogh-style YAML), `tools/gen.py -s "<Name>"`, a generated screenshot, optional CREDITS entry; Ghostty syncs it weekly | Phase 1 |
| btop | `aristocratos/btop` `themes/` | README asks contributors to get in touch first; CONTRIBUTING wants an issue before an unrequested PR and an "[AI generated]" mark when it applies | Phase 1, issue first |
| fzf | `junegunn/fzf` wiki, Color schemes page | Wiki edit | Phase 1 |
| VS Code | Visual Studio Marketplace (`vsce`) | Azure DevOps publisher and PAT; `x.y.z` versions only | Phase 3, after 0.1.0 |
| Cursor and VSCodium | Open VSX (`ovsx`) | Eclipse account, Publisher Agreement, namespace claim, PAT; malware and typosquatting scans | Phase 3, after 0.1.0 |
| Obsidian | community.obsidian.md directory | Repo root with `manifest.json`, `README.md`, `LICENSE`, screenshot (512x288 recommended); GitHub release whose tag equals `manifest.version` (`x.y.z` only) with `manifest.json` and `theme.css` attached; automated review | Phase 3, mirror repo |
| Shiki | `shikijs/textmate-grammars-themes` | Needs 50K Marketplace downloads or 300 GitHub stars | Tracked, not now |
| bat | bundled themes | Curated by popularity | Out |
| niri, p10k | no theme catalog | n/a | Out |
| Chrome, GTK | Web Store (US$ 5), gnome-look.org | Manual uploads | Out (decided) |

## Decisions

| Question | Decision |
|---|---|
| Channels | Free PRs (Noctalia, iTerm2-Color-Schemes, btop, fzf wiki), VS Code + Open VSX, Obsidian |
| Versioning | Stores wait for the stable 0.1.0; free PRs go out during the beta |
| Obsidian | Mirror repo `nandomoreirame/obsidian-terminal-noir`, updated by CI on each stable tag, with its own release |
| Accounts | None exist; Fernando creates them in Phase 2 |
| Who opens external PRs and publishes | Claude prepares everything; every outward action (PR, issue, wiki edit, publish, repo creation) waits for Fernando's explicit ok |

## Requirements

1. [REQ-001] WHEN `scripts/upstream/iterm2-yaml <dir>` runs THEN it SHALL write `Terminal Noir.yml` (dark) and `Terminal Noir Paper.yml` (light) in the iTerm2-Color-Schemes YAML format: `name`, `author`, `variant`, `color_01`..`color_16` from the ANSI set in order, `background`, `foreground`, `cursor`, `cursor_text`, `selection`, `selection_text`, all from `palette/palette.json`.
2. [REQ-002] WHEN the suite runs THEN it SHALL fail if the Noctalia port breaks a rule that `community-palettes` CI enforces: both variants, all 16 roles plus the 8-key `terminal` block, six-digit hex, and every `mOnX` on `mX` at 3:1 or more (stricter than their 2:1).
3. [REQ-003] WHEN Phase 1 runs THEN the PRs to `community-palettes` and `iTerm2-Color-Schemes`, the btop issue (and PR once welcomed) and the fzf wiki entry SHALL be prepared in full and submitted only after Fernando's ok, one at a time, each with screenshots.
4. [REQ-004] WHEN the stable `v0.1.0` exists THEN `ports/vscode/package.json` SHALL carry `repository`, `bugs`, `icon` (a 128x128 PNG) and a `0.1.0` version, and `npx @vscode/vsce package` SHALL build a VSIX without warnings.
5. [REQ-005] WHEN a stable tag `vX.Y.Z` (no pre-release suffix) is pushed THEN a workflow SHALL publish the VS Code extension to the Marketplace and to Open VSX with `VSCE_PAT` and `OVSX_PAT` from repository secrets, and SHALL NOT run for pre-release tags.
6. [REQ-006] WHEN a stable tag is pushed THEN a workflow SHALL sync `manifest.json`, `theme.css`, `README.md`, `LICENSE` and a 512x288 screenshot to `nandomoreirame/obsidian-terminal-noir` and create a release there tagged with the manifest version, with both files attached; it SHALL use a fine-grained token scoped to that one repo.
7. [REQ-007] WHEN the README is read THEN a "Get it" section SHALL list each catalog where Terminal Noir is available, and `docs/distribution.md` SHALL track each channel's status (planned, submitted with link, live) and the Shiki threshold (stars and Marketplace downloads).

## Out of scope

| Item | Reason |
|---|---|
| Chrome Web Store, gnome-look.org | Decided out for now |
| A light VS Code theme and a light Obsidian theme | Separate feature; the stores ship the existing dark ports first |
| Shiki bundling | Gated on 50K downloads or 300 stars |

## Risks

| Risk | Mitigation |
|---|---|
| A maintainer declines (btop, iTerm2) | Issue first where asked; the port stays installable from this repo |
| `gen.py` adjusts colors below 1.75:1 | Our palette already clears 4.5:1, so it should not touch them; check the generated Ghostty file against ours |
| Leaked publish tokens | Repository secrets only, fine-grained and expiring tokens, workflows on tags only, `permissions` minimal |
| Open VSX namespace squatting | Claim the namespace right after creating it |

## Traceability

| ID | Description | Phase | Status |
|---|---|---|---|
| REQ-001 | iTerm2 YAML generator | 1 | Pending |
| REQ-002 | Noctalia community rules in the suite | 1 | Pending |
| REQ-003 | Phase 1 submissions | 1 | Pending |
| REQ-004 | VS Code package ready for stores | 3 | Pending |
| REQ-005 | Publish workflow (Marketplace, Open VSX) | 3 | Pending |
| REQ-006 | Obsidian mirror and release workflow | 3 | Pending |
| REQ-007 | README "Get it" and distribution tracker | 1, 3 | Pending |
