---
slug: mcp-server
phase: plan-complete
spec_path: docs/specs/mcp-server/SPEC.md
plan_path: docs/plans/2026-10-21-mcp-server.md
updated: 2026-10-21
---

# State: mcp-server

## Decisions

- MCP on Firebase Functions 2nd gen (`terminalnoirMcp`, codebase `terminalnoir`, `us-central1`), served at `https://terminalnoir.web.app/api/mcp` through a Hosting rewrite.
- Read-only tools: `get_palette`, `list_ports`, `get_port`, `check_contrast`, `get_wallpapers`; data from a committed, generated catalog.
- Claude Code plugin `terminal-noir` from this repo (marketplace at the root): skill `apply` plus the HTTP MCP; the skill falls back to raw GitHub.
- Bilingual `/mcp` page; tool list shared with the server through `functions/src/tools-meta.ts`.

## Open

- Deploys, IAM grants and the Artifact Registry policy (Task 8) wait for Fernando's explicit ok.
