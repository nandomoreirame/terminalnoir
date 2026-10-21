# Plan: upstream-distribution

> **Spec:** docs/specs/upstream-distribution/SPEC.md

**Goal:** Put Terminal Noir into the theme catalogs of Noctalia, Ghostty (via iTerm2-Color-Schemes), btop, fzf, VS Code, Open VSX and Obsidian.
**Architecture:** Three phases. Phase 1 (now, during the beta) generates what the free catalogs need from `palette.json`, proves it against their rules in the suite, and submits one PR at a time. Phase 2 is Fernando creating the store accounts and secrets. Phase 3 (after the stable `v0.1.0`) makes the VS Code package store-ready and adds two tag-triggered workflows: one publishes to the Marketplace and Open VSX, the other syncs and releases the Obsidian mirror repo.
**Tech Stack:** bash, jq, bats, shellcheck, GitHub Actions, `@vscode/vsce`, `ovsx`, `gh`.
**Total Tasks:** 13
**Estimated Complexity:** large

---

## Ground rules for the implementer

- **Every outward action waits for Fernando's explicit ok in the conversation:** opening an issue or PR in another repo, editing a wiki, creating a repo, pushing a tag, publishing. Prepare everything, show it, stop, then act. Silence or a task notification is never consent.
- External PRs: one per catalog, from a fork, on a branch named `terminal-noir`. The PR text is English. Mention in the body that the colors are generated from `palette.json` and gated at WCAG AA by this repo's suite.
- Run bats only as: `env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=dumb bash $HOME/.local/share/mise/installs/node/22.22.3/lib/node_modules/bats/bin/bats tests` (plain `bats` and `make test` do not work on this machine).
- No secret ever appears in a file, a command line or a log: tokens live in repository secrets and reach steps through `env:`.

## Order and dependencies

| Phase | Tasks | Gate |
|---|---|---|
| 1, beta | 1, 2, 3, 4, 5, 6, 7 | none |
| 2, accounts | 8 | Fernando |
| 3, stable | 9, 10, 11, 12, 13 | `v0.1.0` released (Task 9) and Task 8 done |

---

### Task 1: iTerm2-Color-Schemes YAML generator

**Requirement:** REQ-001
**Files:**
- Create: `scripts/lib/iterm2-yaml.jq`
- Create: `scripts/upstream/iterm2-yaml`
- Create: `tests/upstream.bats`
- Modify: `Makefile:2` (add the script to `SCRIPTS`)

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: bash-linux)
- Reviewers: test-reviewer, business-logic-reviewer

**Step 1: Write the failing test**
```bash
#!/usr/bin/env bats

# What the upstream theme catalogs receive is generated from the palette and
# checked against their own rules before any PR is opened.

load test_helper

setup() {
    OUT="$(temp_make)"
}

teardown() {
    temp_del "$OUT"
}

yaml() {
    # Prints the value of a top-level key, without its quotes.
    sed -n "s/^$2: '\(.*\)'$/\1/p" "$OUT/$1.yml"
}

@test "iterm2-yaml: one file per variant, named as the theme is displayed" {
    run "$PROJECT_ROOT/scripts/upstream/iterm2-yaml" "$OUT"
    assert_success
    [ -f "$OUT/Terminal Noir.yml" ]
    [ -f "$OUT/Terminal Noir Paper.yml" ]
    [ "$(yaml 'Terminal Noir' name)" = "Terminal Noir" ]
    [ "$(yaml 'Terminal Noir Paper' variant)" = "light" ]
}

@test "iterm2-yaml: ANSI in order, then background, foreground, cursor and selection" {
    "$PROJECT_ROOT/scripts/upstream/iterm2-yaml" "$OUT"
    local v name
    for v in dark light; do
        name="Terminal Noir$([ "$v" = light ] && echo ' Paper' || true)"
        [ "$(yaml "$name" color_01)" = "$(pal "$v" ansi.normal.black)" ]
        [ "$(yaml "$name" color_08)" = "$(pal "$v" ansi.normal.white)" ]
        [ "$(yaml "$name" color_09)" = "$(pal "$v" ansi.bright.black)" ]
        [ "$(yaml "$name" color_16)" = "$(pal "$v" ansi.bright.white)" ]
        [ "$(yaml "$name" background)" = "$(pal "$v" surface.base)" ]
        [ "$(yaml "$name" foreground)" = "$(pal "$v" text.primary)" ]
        [ "$(yaml "$name" cursor)" = "$(pal "$v" accent.primary)" ]
        [ "$(yaml "$name" cursor_text)" = "$(pal "$v" surface.base)" ]
        [ "$(yaml "$name" selection)" = "$(pal "$v" surface.selection)" ]
        [ "$(yaml "$name" selection_text)" = "$(pal "$v" text.primary)" ]
        [ "$(grep -c '^color_[0-9][0-9]: ' "$OUT/$name.yml")" -eq 16 ]
    done
}

@test "iterm2-yaml: fails without an output directory" {
    run "$PROJECT_ROOT/scripts/upstream/iterm2-yaml"
    assert_failure
}
```

**Step 2: Run test to verify it fails**
Run: `env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=dumb bash $HOME/.local/share/mise/installs/node/22.22.3/lib/node_modules/bats/bin/bats tests/upstream.bats`
Expected: FAIL (`scripts/upstream/iterm2-yaml: No such file or directory`).

**Step 3: Write minimal implementation**
`scripts/lib/iterm2-yaml.jq` (prototyped on 2026-10-20):
```jq
# One iTerm2-Color-Schemes YAML file (Gogh format) for variant $v, named $name.
.variants[$v] as $c
| ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"] as $names
| ([$c.ansi.normal[$names[]]] + [$c.ansi.bright[$names[]]]) as $ansi
| def q: "'\(.)'";
  "---",
  "name: \($name | q)",
  "author: \("Fernando Moreira (https://terminalnoir.web.app)" | q)",
  "variant: \($v | q)",
  "",
  (range(0; 16) as $i | "color_\(if $i < 9 then "0" else "" end)\($i + 1): \($ansi[$i] | q)"),
  "",
  "background: \($c.surface.base | q)",
  "foreground: \($c.text.primary | q)",
  "cursor: \($c.accent.primary | q)",
  "cursor_text: \($c.surface.base | q)",
  "selection: \($c.surface.selection | q)",
  "selection_text: \($c.text.primary | q)"
```
`scripts/upstream/iterm2-yaml`:
```bash
#!/usr/bin/env bash
# iterm2-yaml — Write the iTerm2-Color-Schemes source files for both variants.
# That repo generates Ghostty's built-in themes (and ~30 other terminals) from
# yaml/<Name>.yml, so this is what its PR adds.
#
# Usage: scripts/upstream/iterm2-yaml OUT_DIR
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly ROOT

main() {
    local out="${1:?usage: iterm2-yaml OUT_DIR}"
    mkdir -p "$out"
    jq -r --arg v dark --arg name "Terminal Noir" -f "$ROOT/scripts/lib/iterm2-yaml.jq" \
        "$ROOT/palette/palette.json" > "$out/Terminal Noir.yml"
    jq -r --arg v light --arg name "Terminal Noir Paper" -f "$ROOT/scripts/lib/iterm2-yaml.jq" \
        "$ROOT/palette/palette.json" > "$out/Terminal Noir Paper.yml"
}

main "$@"
```
`chmod +x scripts/upstream/iterm2-yaml`. In the `Makefile`, `SCRIPTS` gains `scripts/upstream/iterm2-yaml`.

**Step 4: Run test to verify it passes**
Run: the bats command above, then `make lint`.
Expected: 3 tests ok; shellcheck silent.

**Step 5: Commit**
Run: `/git commit`

---

### Task 2: Noctalia community-palettes rules in the suite

**Requirement:** REQ-002
**Files:**
- Modify: `scripts/lib/contrast.jq` (append; see the note below)
- Modify: `tests/upstream.bats`

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: bash-linux)
- Reviewers: test-reviewer

**Note:** jq 1.8.2 aborts (`expand_call_arglist: Assertion ... Unknown function type`) when one module includes or imports another, even in a two-line case. So the Noctalia rules live in `contrast.jq` next to the other gates instead of in their own module.

**Step 1: Write the failing test**
Append to `tests/upstream.bats`:
```bash
NOCTALIA="$PROJECT_ROOT/ports/noctalia/Terminal Noir.json"

noctalia_problems() {
    jq -r -L "$PROJECT_ROOT/scripts/lib" 'include "contrast"; noctalia_problems' "${1:-$NOCTALIA}"
}

@test "noctalia: the port meets the community-palettes rules" {
    run noctalia_problems
    assert_success
    [ -z "$output" ] || { echo "$output"; return 1; }
}

@test "noctalia: the check reports a missing role, a short hex, a missing terminal key and a thin pair" {
    local bad="$OUT/bad.json"
    jq 'del(.light.mHover) | .dark.mShadow = "#000" | .dark.mOnPrimary = .dark.mPrimary | del(.dark.terminal.cursor)' "$NOCTALIA" > "$bad"
    run noctalia_problems "$bad"
    assert_success
    grep -q '^light missing mHover$' <<<"$output"
    grep -q '^dark mShadow is not #rrggbb: #000$' <<<"$output"
    grep -q '^dark terminal missing cursor$' <<<"$output"
    grep -q '^dark mOnPrimary on mPrimary: 1 < 3$' <<<"$output"
}
```

**Step 2: Run test to verify it fails**
Run: the bats command on `tests/upstream.bats`.
Expected: FAIL (`noctalia_problems/0 is not defined`).

**Step 3: Write minimal implementation**
Append to `scripts/lib/contrast.jq` (prototyped on 2026-10-20: no problem on the real port, the four expected lines on the broken one):
```jq

# The rules noctalia-dev/community-palettes CI enforces on a palette file, with
# the legibility floor raised from their 2:1 to 3:1. One line per problem.
def noctalia_roles: ["mPrimary", "mOnPrimary", "mSecondary", "mOnSecondary", "mTertiary", "mOnTertiary",
                     "mError", "mOnError", "mSurface", "mOnSurface", "mSurfaceVariant", "mOnSurfaceVariant",
                     "mOutline", "mShadow", "mHover", "mOnHover"];
def noctalia_terminal_keys: ["background", "bright", "cursor", "cursorText", "foreground", "normal", "selectionBg", "selectionFg"];
def is_hex6: type == "string" and test("^#[0-9A-Fa-f]{6}$");

def noctalia_problems:
  . as $file
  | ["dark", "light"][] as $v
  | if ($file | has($v)) | not then "\($v) variant missing"
    else $file[$v] as $m
    | (noctalia_roles[] as $r | select($m | has($r) | not) | "\($v) missing \($r)"),
      ($m | to_entries[] | select(.key != "terminal") | select(.value | is_hex6 | not)
        | "\($v) \(.key) is not #rrggbb: \(.value)"),
      (noctalia_terminal_keys[] as $k | select(($m.terminal // {}) | has($k) | not) | "\($v) terminal missing \($k)"),
      ($m | to_entries[] | select(.key | test("^mOn")) | .key as $on | ($on | sub("^mOn"; "m")) as $base
        | select(($m[$on] | is_hex6) and ($m[$base] | is_hex6))
        | contrast($m[$on]; $m[$base]) as $r | select($r < 3)
        | "\($v) \($on) on \($base): \(($r * 100 | floor) / 100) < 3")
    end;
```

**Step 4: Run test to verify it passes**
Run: the bats command on `tests/upstream.bats`, then the whole suite.
Expected: 5 tests ok in the file; the whole suite green.

**Step 5: Commit**
Run: `/git commit`

---

### Task 3: Noctalia community-palettes PR

**Requirement:** REQ-003
**Depends on:** Task 2, and a Paper screenshot of Noctalia (Fernando takes it: Noctalia in light mode with Terminal Noir applied, saved as `assets/screenshots/noctalia-paper.png`)
**Files:**
- Create: `assets/screenshots/noctalia-paper.png` (by Fernando)

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct, by Claude in the main session)
- Reviewers: self-review

**Steps (each outward step after Fernando's ok):**
1. `gh repo fork noctalia-dev/community-palettes --clone --remote` into the scratchpad; `git checkout -b terminal-noir`.
2. `mkdir "Terminal Noir" && cp ~/dev/projects/terminalnoir/ports/noctalia/"Terminal Noir.json" "Terminal Noir/"`.
3. Run their check exactly as CI does: `./.github/workflows/contrast-check.sh "Terminal Noir"/*.json --all`. Expected: no failure and no warning. If it rejects uppercase hex, report and stop (the port would need lowercase, a generator change in this repo first).
4. Do not touch `registry.json`. Commit only the new directory.
5. Show Fernando the diff and the PR body; on his ok, push and `gh pr create` with both screenshots (`noctalia.png`, `noctalia-paper.png`) uploaded in the body, following their PR template.
6. Record the PR URL in `docs/distribution.md` (Task 7).

---

### Task 4: iTerm2-Color-Schemes PR (Ghostty and other terminals)

**Requirement:** REQ-003
**Depends on:** Task 1

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: self-review

**Steps (each outward step after Fernando's ok):**
1. Fork and clone `mbadolato/iTerm2-Color-Schemes`; branch `terminal-noir`.
2. `~/dev/projects/terminalnoir/scripts/upstream/iterm2-yaml yaml/`.
3. Generate with their tooling: `./generate-all.sh` with Docker if available, else `pip install -r requirements.txt` in a venv and `python3 tools/gen.py -s "Terminal Noir"` and `python3 tools/gen.py -s "Terminal Noir Paper"`.
4. Compare their generated `ghostty/Terminal Noir` and `ghostty/Terminal Noir Paper` with `ports/ghostty/terminal-noir-dark` and `-light`: the palette slots, background, foreground, cursor and selection must match. A difference means `gen.py` adjusted a color; report it instead of submitting.
5. `pushd tools && python3 -m screenshot_gen && popd` for the screenshots; add the README entries and a `CREDITS.md` line as the guide says.
6. Show the diff and the PR body; on his ok, push and open the PR.

---

### Task 5: btop issue, then PR

**Requirement:** REQ-003

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: self-review

**Steps (each outward step after Fernando's ok):**
1. Draft an issue for `aristocratos/btop`: "Theme submission: Terminal Noir", with the screenshot `assets/screenshots/btop.png`, a link to `ports/btop/terminal-noir.theme`, a one-line description, and that it is MIT licensed and generated from a palette checked at WCAG AA. Ask whether a PR to `themes/` is welcome.
2. Open it on his ok. If the maintainer welcomes it: fork, copy `ports/btop/terminal-noir.theme` to `themes/terminal-noir.theme`, PR referencing the issue, marked "[AI generated]" if the maintainer's rule applies to a generated file (ask Fernando).

---

### Task 6: fzf wiki entry

**Requirement:** REQ-003

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: self-review

**Steps:**
1. Read https://github.com/junegunn/fzf/wiki/Color-schemes and match the format of existing entries.
2. Draft the entry: name, the `--color` string from `ports/fzf/terminal-noir.sh`, a link to `ports/fzf`.
3. GitHub wikis are edited in the browser: hand the text to Fernando to paste (or, if the wiki repo accepts pushes, clone `https://github.com/junegunn/fzf.wiki.git` and push on his ok).

---

### Task 7: Distribution tracker and README "Get it"

**Requirement:** REQ-007
**Files:**
- Create: `docs/distribution.md`
- Modify: `README.md` (new `## Get it` section after `## Accessibility`)
- Modify: `tests/upstream.bats`

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: self-review

**Step 1: Write the failing test**
```bash
@test "distribution: every planned channel has a status row" {
    local doc="$PROJECT_ROOT/docs/distribution.md" channel
    for channel in "Noctalia" "iTerm2-Color-Schemes" "btop" "fzf" "VS Code Marketplace" "Open VSX" "Obsidian" "Shiki"; do
        grep -Eq "^\| $channel \| (planned|submitted|live|blocked) \|" "$doc" || { echo "no row: $channel"; return 1; }
    done
}

@test "README lists where to get the theme" {
    sed -n '/^## Get it$/,/^## /p' "$PROJECT_ROOT/README.md" | grep -q 'docs/distribution.md'
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL (`no row: Noctalia`).

**Step 3: Write minimal implementation**
`docs/distribution.md`:
```markdown
# Distribution

Where Terminal Noir ships besides this repository. Status: planned, submitted, live or blocked.

| Channel | Status | Link | Notes |
|---|---|---|---|
| Noctalia | planned | | noctalia-dev/community-palettes, dark and light |
| iTerm2-Color-Schemes | planned | | Ghostty syncs it weekly; ~30 terminals |
| btop | planned | | issue first |
| fzf | planned | | wiki, Color schemes |
| VS Code Marketplace | planned | | after v0.1.0 |
| Open VSX | planned | | after v0.1.0; Cursor and VSCodium |
| Obsidian | planned | | mirror repo, after v0.1.0 |
| Shiki | blocked | | needs 50K Marketplace downloads or 300 GitHub stars |
```
`README.md`:
```markdown
## Get it

Each port's README installs it from this repository. Catalog listings (Noctalia, Ghostty, btop, VS Code, Open VSX, Obsidian) are tracked in [docs/distribution.md](docs/distribution.md).
```
Tasks 3 to 6 and 13 update the rows as each channel moves.

**Step 4: Run test to verify it passes**
Expected: PASS.

**Step 5: Commit**
Run: `/git commit`

---

### Task 8: Accounts and secrets (Fernando)

**Requirement:** REQ-005, REQ-006
**Team:**
- Track: infra
- Implementer: Fernando (manual), Claude guides
- Reviewers: security-reviewer (checks no token ever lands in the repo or a log)

**Steps:**
1. **Marketplace:** create an Azure DevOps organization, then a publisher at https://marketplace.visualstudio.com/manage. Its ID must equal `publisher` in `ports/vscode/package.json` (`nandomoreira`); if taken, choose another and change `scripts/ports/vscode.sh` and `scripts/install-vscode` before Task 10. Create a PAT with scope "Marketplace: Manage", all accessible organizations, shortest expiry that covers the launch.
2. **Open VSX:** sign in at https://open-vsx.org with GitHub, link an Eclipse account, sign the Publisher Agreement, create an access token; then `npx --yes ovsx create-namespace nandomoreira -p <token>` (typed by Fernando with `!`, so the token stays out of files) and claim it through the open-vsx.org namespace ownership process.
3. **Obsidian mirror:** on Fernando's ok, `gh repo create nandomoreirame/obsidian-terminal-noir --public --description "Terminal Noir theme for Obsidian (mirror of nandomoreirame/terminalnoir)"`. Create a fine-grained GitHub token limited to that repo with Contents: read and write.
4. **Secrets:** Fernando runs `! gh secret set VSCE_PAT`, `! gh secret set OVSX_PAT` and `! gh secret set OBSIDIAN_MIRROR_TOKEN` in this repo (gh prompts for the value). Verify with `gh secret list` (names only).
5. Note each token's expiry in `docs/distribution.md` (date only).

---

### Task 9: Stable release v0.1.0

**Requirement:** REQ-004 (gate)
**Depends on:** Fernando's decision that the beta is done

**Steps:** run `/git release 0.1.0`. The palette version becomes `0.1.0`; every port regenerates, so the VS Code `package.json` and Obsidian `manifest.json` carry `0.1.0` and Chrome's `version_name` drops the suffix. Tasks 11 and 12 must be merged before this tag if the stores should publish from it; otherwise they publish from the next stable tag.

---

### Task 10: VS Code package ready for the stores

**Requirement:** REQ-004
**Files:**
- Create: `assets/icon.png` (128x128, from `site/public/favicon.svg`: `magick -background none -density 512 site/public/favicon.svg -resize 128x128 assets/icon.png`)
- Modify: `scripts/ports/vscode.sh` (package.json fields; copy `assets/icon.png` and `LICENSE` into `ports/vscode/`)
- Modify: `tests/ports.bats`, `tests/build.bats` (`GENERATED` gains `ports/vscode/icon.png` and `ports/vscode/LICENSE`)

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: bash-linux)
- Reviewers: test-reviewer, consequences-reviewer

**Step 1: Write the failing test**
```bash
@test "vscode: store metadata, icon and license" {
    local f="$PORTS/vscode/package.json"
    [ "$(jq -r .repository.url "$f")" = "https://github.com/nandomoreirame/terminalnoir" ]
    [ "$(jq -r .bugs.url "$f")" = "https://github.com/nandomoreirame/terminalnoir/issues" ]
    [ "$(jq -r .icon "$f")" = "icon.png" ]
    [ -f "$PORTS/vscode/icon.png" ]
    # PNG IHDR: width and height are big-endian at bytes 16-23.
    [ "$(od -An -tx1 -j16 -N8 "$PORTS/vscode/icon.png" | tr -d ' \n')" = "0000008000000080" ]
    cmp -s "$PORTS/vscode/LICENSE" "$PROJECT_ROOT/LICENSE"
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL (`repository.url` is `null`).

**Step 3: Write minimal implementation**
In `scripts/ports/vscode.sh`, add to the generated `package.json` object, after `homepage`:
```jq
        repository: { type: "git", url: "https://github.com/nandomoreirame/terminalnoir" },
        bugs: { url: "https://github.com/nandomoreirame/terminalnoir/issues" },
        icon: "icon.png",
```
and at the end of `build_vscode`:
```bash
    cp "$ROOT/assets/icon.png" "$OUT/ports/vscode/icon.png"
    cp "$ROOT/LICENSE" "$OUT/ports/vscode/LICENSE"
```
(if `build_vscode` has no `$ROOT`, derive it the way `scripts/build` does, from `$PALETTE`'s directory). Then `scripts/build`.

**Step 4: Run test to verify it passes**
Run: the full bats suite, `make lint`, then in a scratch copy `cd ports/vscode && npx --yes @vscode/vsce@3 package --out /tmp/tn.vsix`.
Expected: suite green; `vsce` prints no WARNING and writes the VSIX. Check `scripts/install-vscode` still builds its VSIX (`tests/install-vscode.bats`).

**Step 5: Commit**
Run: `/git commit`

---

### Task 11: Publish workflow (Marketplace and Open VSX)

**Requirement:** REQ-005
**Depends on:** Task 10
**Files:**
- Create: `.github/workflows/publish-vscode.yml`
- Create: `tests/workflows.bats`

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: cloud-cli, bash-linux)
- Reviewers: security-reviewer, consequences-reviewer

**Step 1: Write the failing test**
```bash
#!/usr/bin/env bats

# Publishing workflows: stable tags only, secrets only through env, least privilege.

load test_helper

WF="$PROJECT_ROOT/.github/workflows"

@test "publish-vscode: runs on version tags and skips pre-releases" {
    local f="$WF/publish-vscode.yml"
    grep -q "tags: \['v\*'\]" "$f"
    grep -q "if: \${{ !contains(github.ref_name, '-') }}" "$f"
}

@test "publish-vscode: tokens come from secrets through env, never inline" {
    local f="$WF/publish-vscode.yml"
    grep -q 'VSCE_PAT: \${{ secrets.VSCE_PAT }}' "$f"
    grep -q 'OVSX_PAT: \${{ secrets.OVSX_PAT }}' "$f"
    if grep -n 'secrets\.' "$f" | grep -v ': \${{ secrets\.[A-Z_]* }}$'; then return 1; fi
    grep -q '^permissions:$' "$f"
    grep -q '^  contents: read$' "$f"
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL (file missing).

**Step 3: Write minimal implementation**
`.github/workflows/publish-vscode.yml`:
```yaml
# Publish the VS Code extension to the Visual Studio Marketplace and Open VSX
# (Cursor, VSCodium) on every stable version tag. Pre-release tags (v0.2.0-beta)
# are skipped: the Marketplace takes x.y.z only.
name: Publish VS Code extension

on:
  push:
    tags: ['v*']

permissions:
  contents: read

jobs:
  publish:
    if: ${{ !contains(github.ref_name, '-') }}
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Check the tag matches the extension version
        run: |
          version="$(jq -r .version ports/vscode/package.json)"
          [ "v$version" = "$GITHUB_REF_NAME" ] || { echo "tag $GITHUB_REF_NAME, package $version"; exit 1; }

      - name: Package
        working-directory: ports/vscode
        run: npx --yes @vscode/vsce@3 package --out terminal-noir.vsix

      - name: Visual Studio Marketplace
        working-directory: ports/vscode
        env:
          VSCE_PAT: ${{ secrets.VSCE_PAT }}
        run: npx --yes @vscode/vsce@3 publish --packagePath terminal-noir.vsix

      - name: Open VSX
        working-directory: ports/vscode
        env:
          OVSX_PAT: ${{ secrets.OVSX_PAT }}
        run: npx --yes ovsx@0 publish terminal-noir.vsix
```
(`vsce` reads `VSCE_PAT` and `ovsx` reads `OVSX_PAT` from the environment; pin both to the exact current major at implementation time.)

**Step 4: Run test to verify it passes**
Expected: `tests/workflows.bats` ok.

**Step 5: Commit**
Run: `/git commit`

---

### Task 12: Obsidian mirror and release workflow

**Requirement:** REQ-006
**Depends on:** Task 8 (mirror repo and token)
**Files:**
- Create: `assets/screenshots/obsidian-512.png` (`magick assets/screenshots/obsidian.png -resize 512x288^ -gravity north -extent 512x288 assets/screenshots/obsidian-512.png`)
- Create: `ports/obsidian/mirror-README.md`
- Create: `.github/workflows/obsidian-mirror.yml`
- Modify: `tests/workflows.bats`, `tests/ports.bats`

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: bash-linux)
- Reviewers: security-reviewer, consequences-reviewer

**Step 1: Write the failing tests**
In `tests/ports.bats`:
```bash
@test "obsidian: a 512x288 store screenshot and a README for the mirror" {
    local png="$PROJECT_ROOT/assets/screenshots/obsidian-512.png"
    [ "$(od -An -tx1 -j16 -N8 "$png" | tr -d ' \n')" = "0000020000000120" ]
    grep -q '](screenshot.png)' "$PORTS/obsidian/mirror-README.md"
    grep -q 'github.com/nandomoreirame/terminalnoir' "$PORTS/obsidian/mirror-README.md"
}
```
In `tests/workflows.bats`:
```bash
@test "obsidian-mirror: stable tags only, scoped token through env, x.y.z manifest" {
    local f="$WF/obsidian-mirror.yml"
    grep -q "tags: \['v\*'\]" "$f"
    grep -q "if: \${{ !contains(github.ref_name, '-') }}" "$f"
    grep -q 'TOKEN: \${{ secrets.OBSIDIAN_MIRROR_TOKEN }}' "$f"
    if grep -n 'secrets\.' "$f" | grep -v ': \${{ secrets\.[A-Z_]* }}$'; then return 1; fi
    grep -q '\^\[0-9\]+\\.\[0-9\]+\\.\[0-9\]+\$' "$f"
    grep -q 'gh release create' "$f"
}
```

**Step 2: Run tests to verify they fail**
Expected: FAIL (files missing).

**Step 3: Write minimal implementation**
`ports/obsidian/mirror-README.md`:
```markdown
# Terminal Noir for Obsidian

Cold near-black surfaces stepped by luminance, one amber accent and an emerald status color. Every text and accent color meets WCAG AA.

![Terminal Noir for Obsidian](screenshot.png)

This repository is a release mirror. The theme is generated from the palette in [nandomoreirame/terminalnoir](https://github.com/nandomoreirame/terminalnoir), where issues and pull requests go.

MIT licensed.
```
`.github/workflows/obsidian-mirror.yml`:
```yaml
# Sync the Obsidian theme to its mirror repo and release it there on every
# stable tag. Obsidian reads manifest.json from the mirror's root and installs
# from a release whose tag equals the manifest version (x.y.z only).
name: Obsidian mirror

on:
  push:
    tags: ['v*']

permissions:
  contents: read

jobs:
  mirror:
    if: ${{ !contains(github.ref_name, '-') }}
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - name: Sync and release
        env:
          TOKEN: ${{ secrets.OBSIDIAN_MIRROR_TOKEN }}
          MIRROR: nandomoreirame/obsidian-terminal-noir
        run: |
          set -euo pipefail
          src="ports/obsidian/Terminal Noir"
          version="$(jq -r .version "$src/manifest.json")"
          [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "manifest version $version is not x.y.z"; exit 1; }
          git clone --depth 1 "https://x-access-token:${TOKEN}@github.com/${MIRROR}.git" mirror
          cp "$src/manifest.json" "$src/theme.css" LICENSE mirror/
          cp assets/screenshots/obsidian-512.png mirror/screenshot.png
          cp ports/obsidian/mirror-README.md mirror/README.md
          cd mirror
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add -A
          git diff --cached --quiet || git commit -m "Terminal Noir $version"
          git push origin HEAD
          GH_TOKEN="$TOKEN" gh release create "$version" manifest.json theme.css \
            --repo "$MIRROR" --title "$version" --notes "Terminal Noir $version"
```

**Step 4: Run tests to verify they pass**
Expected: suite green, `make lint` silent.

**Step 5: Commit**
Run: `/git commit`

---

### Task 13: Phase 3 launch

**Requirement:** REQ-003, REQ-005, REQ-006, REQ-007
**Depends on:** Tasks 8 to 12

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct) with Fernando
- Reviewers: self-review

**Steps:**
1. When `v0.1.0` (or the next stable tag) is pushed, watch both workflows: `gh run list --workflow publish-vscode.yml` and `--workflow obsidian-mirror.yml`. A failure is reported, never retried blindly.
2. Confirm the listings: the Marketplace page for `nandomoreira.terminal-noir`, `https://open-vsx.org/extension/nandomoreira/terminal-noir`, and the mirror's release with both assets.
3. Fernando submits the mirror at https://community.obsidian.md (sign in, link GitHub, add the theme) and fixes anything the automated review reports through a new stable release.
4. Update `docs/distribution.md` with links and statuses; once the Marketplace passes 50K downloads or the repo passes 300 stars, open the Shiki issue for `shikijs/textmate-grammars-themes`.
