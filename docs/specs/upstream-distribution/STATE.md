---
feature: upstream-distribution
phase: plan-complete
started_at: 2026-10-20
depth: deep
spec_path: docs/specs/upstream-distribution/SPEC.md
plan_path: docs/plans/2026-10-20-upstream-distribution.md
decisions:
  - "Channels: free PRs (Noctalia community-palettes, iTerm2-Color-Schemes for Ghostty, btop, fzf wiki), VS Code Marketplace + Open VSX, Obsidian"
  - "Stores wait for the stable v0.1.0; free PRs go out during the beta"
  - "Obsidian through a mirror repo synced and released by CI on stable tags"
  - "No store accounts exist yet; Fernando creates them (Task 8)"
  - "Chrome Web Store and gnome-look.org out for now; Shiki gated on 50K downloads or 300 stars; bat, niri and p10k have no catalog"
  - "Every outward action (PR, issue, wiki edit, repo creation, tag, publish) waits for Fernando's explicit ok"
blockers: []
transitions:
  - "2026-10-20: research (channel rules read from each repo's README and docs), spec approved"
  - "2026-10-20: plan-complete, 13 tasks in 3 phases"
---

# State: upstream-distribution

jq 1.8.2 aborts when a module includes another module, so the Noctalia rules are appended to
`scripts/lib/contrast.jq` (Task 2) instead of living in their own module.
