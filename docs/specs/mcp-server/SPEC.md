# Spec: mcp-server

> Approved 2026-10-21 by Fernando. A read-only MCP server for Terminal Noir on Firebase
> Functions, a Claude Code plugin (skill + MCP) distributed from this repo, and a `/mcp`
> page on terminalnoir.web.app that explains both.

## Problem

Terminal Noir installs by copying files from the repo. An AI agent can apply a theme to a
user's apps in seconds, but only if it can find the palette, the port files and the install
steps reliably. The site is static on Firebase Hosting, so it cannot serve an MCP endpoint by
itself.

## Model

The MCP server only reads. It answers what the theme is and how to install each port; the
agent (Claude Code, Cursor, ChatGPT) applies it on the user's machine with its own tools and
permission prompts. The server never writes anything anywhere.

## Decisions

| Question | Decision |
|---|---|
| Hosting of the MCP routes | Firebase Functions (2nd gen, Node 22, `us-central1`), codebase `terminalnoir`, function `terminalnoirMcp`, in project `nandomoreira-dev` |
| Public endpoint | `https://terminalnoir.web.app/api/mcp`, a Hosting rewrite to the function |
| Transport | Streamable HTTP, stateless, plain JSON responses; one server and transport per request (same design as nandomoreira.dev `/api/mcp`) |
| Tools | `get_palette`, `list_ports`, `get_port`, `check_contrast`, `get_wallpapers` |
| Data at runtime | A catalog JSON generated from the repo at build time and committed; a test fails when it drifts |
| Skill distribution | Claude Code plugin `terminal-noir` in this repo, which is also its marketplace; the plugin ships the skill and the MCP connection |
| Skill without MCP | Falls back to reading `ports.json` and raw files from GitHub |
| Writes on the user's machine | Only by the agent, after showing the plan; backup of every file it replaces |
| Abuse and cost | Per-instance rate limit per IP (60 requests per minute), `maxInstances: 2`, 15 s timeout, 256 MiB, `Cache-Control: no-store` |

## Requirements

1. [REQ-001] WHEN `functions/scripts/build-catalog.mjs` runs THEN it SHALL write `functions/src/catalog.generated.json` with the palette (both variants), the syntax roles, every registered port (slug, name, category, variants, homepage, page URL, README, install snippet, files with raw GitHub URLs) and both wallpapers (variant, raw URL, width, height read from the PNG header); a test SHALL fail when the committed file differs from a fresh build.
2. [REQ-002] WHEN `get_palette` is called with `variant` `noir`, `paper` or nothing THEN it SHALL return that variant's roles and 16 ANSI colors, or both variants.
3. [REQ-003] WHEN `list_ports` is called THEN it SHALL return every port's slug, name, category, variants and page URL, optionally filtered by `category` and by `variant`.
4. [REQ-004] WHEN `get_port` is called with a known `slug` THEN it SHALL return the port's metadata, README, install snippet and file list with raw URLs; an unknown slug SHALL be a tool error naming `list_ports`, never a thrown exception.
5. [REQ-005] WHEN `check_contrast` is called with two `#RRGGBB` colors THEN it SHALL return the WCAG 2.1 ratio rounded to two decimals and whether it passes 4.5:1 (text) and 3:1 (graphics); any other input SHALL be rejected by the schema.
6. [REQ-006] WHEN `get_wallpapers` is called THEN it SHALL return both wallpapers with variant, raw URL and size.
7. [REQ-007] WHEN a client POSTs JSON-RPC to the function THEN it SHALL answer in plain JSON with `Cache-Control: no-store`; an internal failure SHALL answer a JSON-RPC `-32603` with no stack trace or path; more than 60 requests in a minute from one IP on one instance SHALL answer 429.
8. [REQ-008] WHEN `firebase.json` is read THEN it SHALL declare the `terminalnoir` functions codebase and rewrite `/api/mcp` to `terminalnoirMcp` in `us-central1`, so a deploy never touches functions of other codebases in the project.
9. [REQ-009] WHEN `main` is pushed THEN CI SHALL run the functions tests and deploy `hosting:terminalnoir` and `functions:terminalnoir` with the existing keyless identity.
10. [REQ-010] WHEN a user runs `/plugin marketplace add nandomoreirame/terminalnoir` and `/plugin install terminal-noir@terminal-noir` THEN the plugin SHALL install the `apply` skill and the `terminal-noir` HTTP MCP server; `claude plugin validate .` SHALL pass, and the plugin version SHALL equal the palette version.
11. [REQ-011] WHEN the `apply` skill runs THEN it SHALL detect which supported apps are installed, prefer the MCP tools and fall back to raw GitHub, show the plan before writing, back up every file it replaces, never use `sudo`, and say which apps have no Paper variant yet.
12. [REQ-012] WHEN `/mcp` (and `/pt-br/mcp`) is opened THEN the page SHALL show the endpoint with a copy button, the plugin install commands, per-client setup (Claude Code, Claude, ChatGPT, Cursor, any MCP client), the tool list taken from the same metadata the server uses, and example prompts; the main nav SHALL link to it.
13. [REQ-013] WHEN the README is read THEN a "Use with AI" section SHALL point to `/mcp` and give the two plugin commands.

## Out of scope

| Item | Reason |
|---|---|
| Tools that write files | The agent applies; the server stays read-only |
| A local stdio MCP | Not needed while every target agent has a shell |
| Auth | Public, read-only data |

## Risks

| Risk | Mitigation |
|---|---|
| CI identity lacks the IAM roles to deploy functions | First deploy by Fernando's account (Task 8), then grant the roles and let CI take over |
| Deploy fails on the Artifact Registry cleanup policy | Set it once with `firebase functions:artifacts:setpolicy` (Task 8) |
| Hosting caches a JSON-RPC answer | `Cache-Control: no-store` on every response, asserted in tests |
| Per-instance limiter is approximate | Two instances at most cap the real rate at 120/min per IP; enough for a public read-only catalog |

## Traceability

| ID | Description | Status |
|---|---|---|
| REQ-001 | Catalog generator and freshness | Pending |
| REQ-002 | get_palette | Pending |
| REQ-003 | list_ports | Pending |
| REQ-004 | get_port | Pending |
| REQ-005 | check_contrast | Pending |
| REQ-006 | get_wallpapers | Pending |
| REQ-007 | HTTP handler, no-store, errors, rate limit | Pending |
| REQ-008 | firebase.json codebase and rewrite | Pending |
| REQ-009 | CI deploy | Pending |
| REQ-010 | Plugin marketplace | Pending |
| REQ-011 | apply skill | Pending |
| REQ-012 | /mcp page | Pending |
| REQ-013 | README "Use with AI" | Pending |
