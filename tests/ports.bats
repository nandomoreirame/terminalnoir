#!/usr/bin/env bats

# Each port maps palette roles to the app's own color slots.

load test_helper

PORTS="$PROJECT_ROOT/ports"

@test "noctalia: material roles map to the palette in both modes" {
    local f="$PORTS/noctalia/Terminal Noir.json" v
    for v in dark light; do
        [ "$(jq -r ".$v.mPrimary" "$f")" = "$(pal $v accent.primary)" ]
        [ "$(jq -r ".$v.mOnPrimary" "$f")" = "$(pal $v accent.onPrimary)" ]
        [ "$(jq -r ".$v.mSecondary" "$f")" = "$(pal $v accent.success)" ]
        [ "$(jq -r ".$v.mTertiary" "$f")" = "$(pal $v accent.warning)" ]
        [ "$(jq -r ".$v.mError" "$f")" = "$(pal $v accent.error)" ]
        [ "$(jq -r ".$v.mSurface" "$f")" = "$(pal $v surface.base)" ]
        [ "$(jq -r ".$v.mSurfaceVariant" "$f")" = "$(pal $v surface.elevated)" ]
        [ "$(jq -r ".$v.mOnSurface" "$f")" = "$(pal $v text.primary)" ]
        [ "$(jq -r ".$v.mOnSurfaceVariant" "$f")" = "$(pal $v text.muted)" ]
        [ "$(jq -r ".$v.terminal.normal.yellow" "$f")" = "$(pal $v ansi.normal.yellow)" ]
    done
}

@test "ghostty: palette slots, background and cursor in both modes" {
    local v f
    for v in dark light; do
        f="$PORTS/ghostty/terminal-noir-$v"
        grep -Fqx "palette = 3=$(pal $v ansi.normal.yellow | tr 'A-F' 'a-f')" "$f"
        grep -Fqx "palette = 15=$(pal $v ansi.bright.white | tr 'A-F' 'a-f')" "$f"
        grep -Fqx "background = $(pal $v surface.base | tr 'A-F' 'a-f')" "$f"
        grep -Fqx "cursor-color = $(pal $v accent.primary | tr 'A-F' 'a-f')" "$f"
    done
}

@test "vscode: dark editor, amber cursor, keyword and string scopes" {
    local f="$PORTS/vscode/themes/terminal-noir-color-theme.json"
    jq -e '.type == "dark"' "$f"
    [ "$(jq -r '.colors["editor.background"]' "$f")" = "$(pal dark surface.base)" ]
    [ "$(jq -r '.colors["editorCursor.foreground"]' "$f")" = "$(pal dark accent.primary)" ]
    [ "$(jq -r '.colors["terminal.ansiBrightCyan"]' "$f")" = "$(pal dark ansi.bright.cyan)" ]
    [ "$(jq -r '.tokenColors[] | select(.scope | index("keyword")) | .settings.foreground' "$f")" = "$(pal dark accent.primary)" ]
    [ "$(jq -r '.tokenColors[] | select(.scope | index("string")) | .settings.foreground' "$f")" = "$(pal dark accent.success)" ]
    jq -e '.contributes.themes[0] | .label == "Terminal Noir" and .uiTheme == "vs-dark"' "$PORTS/vscode/package.json"
}

@test "bat: a plist theme with the palette background and keyword color" {
    local f="$PORTS/bat/Terminal Noir.tmTheme"
    grep -Fq '<!DOCTYPE plist' "$f"
    grep -Fq "<string>$(pal dark surface.base)</string>" "$f"
    grep -Fq '<string>keyword, keyword.control, storage, storage.type, storage.modifier, keyword.operator.new, keyword.operator.expression</string>' "$f"
    if command -v xmllint >/dev/null 2>&1; then
        xmllint --noout "$f"
    fi
}

@test "chrome: MV3 theme with RGB arrays from the palette" {
    local f="$PORTS/chrome/manifest.json"
    jq -e '.manifest_version == 3 and .name == "Terminal Noir"' "$f"
    [ "$(jq -c '.theme.colors.frame' "$f")" = "$(rgb "$(pal dark surface.base)")" ]
    [ "$(jq -c '.theme.colors.toolbar' "$f")" = "$(rgb "$(pal dark surface.elevated)")" ]
    [ "$(jq -c '.theme.colors.toolbar_button_icon' "$f")" = "$(rgb "$(pal dark accent.primary)")" ]
    [ "$(jq -c '.theme.colors.tab_background_text' "$f")" = "$(rgb "$(pal dark text.muted)")" ]
}

@test "chrome: numeric version, with the full palette version as version_name" {
    local f="$PORTS/chrome/manifest.json" version
    version="$(jq -r .version "$PALETTE")"
    # Chrome refuses a manifest whose version is not 1 to 4 dot-separated integers.
    [[ "$(jq -r .version "$f")" =~ ^[0-9]+(\.[0-9]+){0,3}$ ]]
    [ "$(jq -r .version "$f")" = "${version%%-*}" ]
    [ "$(jq -r .version_name "$f")" = "$version" ]
}

@test "btop: background, title and gradients from the palette" {
    local f="$PORTS/btop/terminal-noir.theme"
    grep -Fqx "theme[main_bg]=\"$(pal dark surface.base)\"" "$f"
    grep -Fqx "theme[title]=\"$(pal dark accent.primary)\"" "$f"
    grep -Fqx "theme[cpu_start]=\"$(pal dark accent.success)\"" "$f"
    grep -Fqx "theme[cpu_end]=\"$(pal dark accent.error)\"" "$f"
}

@test "fzf: an exported FZF_DEFAULT_OPTS with the amber highlight" {
    local f="$PORTS/fzf/terminal-noir.sh"
    run bash -c "source '$f'; printf '%s' \"\$FZF_DEFAULT_OPTS\""
    assert_success
    [[ "$output" == *"hl:$(pal dark accent.primary)"* ]]
    [[ "$output" == *"bg+:$(pal dark surface.elevated)"* ]]
    [[ "$output" == *"marker:$(pal dark accent.success)"* ]]
}

@test "gtk: libadwaita accent variables and the file-view override" {
    local f="$PORTS/gtk/gtk.css"
    grep -Fq -- "--accent-bg-color: $(pal dark accent.primary);" "$f"
    grep -Fq -- "--accent-fg-color: $(pal dark accent.onPrimary);" "$f"
    grep -Fq '.nautilus-list-view listview,' "$f"
    grep -Fq 'filechooser columnview > listview,' "$f"
}

@test "niri: amber focus ring at 80% alpha, palette inactive and urgent" {
    local f="$PORTS/niri/terminal-noir.kdl" amber
    amber="$(pal dark accent.primary | tr 'A-F' 'a-f')"
    grep -Fq "active-color \"${amber}cc\"" "$f"
    grep -Fq "inactive-color \"$(pal dark surface.outline | tr 'A-F' 'a-f')\"" "$f"
    grep -Fq "urgent-color \"$(pal dark accent.error | tr 'A-F' 'a-f')\"" "$f"
    if command -v niri >/dev/null 2>&1; then
        run niri validate -c "$f"
        assert_success
    fi
}

@test "obsidian: a community-theme folder with manifest and dark variables" {
    local dir="$PORTS/obsidian/Terminal Noir"
    jq -e --arg v "$(jq -r .version "$PALETTE")" '.name == "Terminal Noir" and .version == $v and (.minAppVersion | length > 0) and (.author | length > 0)' "$dir/manifest.json"
    grep -q '^\.theme-dark {' "$dir/theme.css"
    grep -Fq -- "--background-primary: $(pal dark surface.base);" "$dir/theme.css"
    grep -Fq -- "--interactive-accent: $(pal dark accent.primary);" "$dir/theme.css"
    grep -Fq -- "--code-string: $(pal dark accent.success);" "$dir/theme.css"
    [ ! -e "$PORTS/obsidian/terminal-noir.css" ]
}

@test "p10k: overrides use palette hex colors and parse" {
    local f="$PORTS/p10k/terminal-noir.p10k.zsh"
    grep -Fqx "typeset -g POWERLEVEL9K_BACKGROUND='$(pal dark surface.elevated)'" "$f"
    grep -Fqx "typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND='$(pal dark accent.primary)'" "$f"
    grep -Fqx "typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='$(pal dark accent.success)'" "$f"
    if command -v zsh >/dev/null 2>&1; then
        run zsh -n "$f"
        assert_success
    fi
}

@test "shiki: one TextMate theme per variant, on the palette base, every token at AA" {
    local v file
    for v in dark light; do
        file="$PROJECT_ROOT/ports/shiki/terminal-noir$([ "$v" = light ] && echo -paper || true).json"
        [ "$(jq -r .type "$file")" = "$v" ] || { echo "type: $file"; return 1; }
        [ "$(jq -r '.colors["editor.background"]' "$file")" = "$(pal "$v" surface.base)" ]
        [ "$(jq -r '.colors["editor.foreground"]' "$file")" = "$(pal "$v" text.primary)" ]
        [ "$(jq '.tokenColors | length' "$file")" -eq "$(jq '.tokens | length' "$SYNTAX")" ]
        [ "$(jq -r '.tokenColors[] | select(.name == "Keyword") | .settings.foreground' "$file")" = "$(pal "$v" accent.primary)" ]
        run jq -r -L "$PROJECT_ROOT/scripts/lib" 'include "contrast";
            .colors["editor.background"] as $bg
            | .tokenColors[] | select(.settings.foreground) | .settings.foreground as $fg
            | select(contrast($fg; $bg) < 4.5) | "\(.name) \($fg)"' "$file"
        [ -z "$output" ] || { echo "$file: $output"; return 1; }
    done
    [ "$(jq -r .name "$PROJECT_ROOT/ports/shiki/terminal-noir-paper.json")" = "terminal-noir-paper" ]
}

@test "shiki: every token keeps its role's name, scopes, color and style" {
    local v file name expected actual
    for v in dark light; do
        file="$PROJECT_ROOT/ports/shiki/terminal-noir$([ "$v" = light ] && echo -paper || true).json"
        name="terminal-noir$([ "$v" = light ] && echo -paper || true)"
        [ "$(jq -r .name "$file")" = "$name" ] || { echo "name: $file"; return 1; }
        expected="$(jq -c --arg v "$v" --slurpfile pal "$PALETTE" '
            [.tokens[] | {name, scope,
                foreground: (.color as $p | if $p then ($pal[0].variants[$v] | getpath($p | split("."))) else null end),
                fontStyle: (.fontStyle // null)}]' "$SYNTAX")"
        actual="$(jq -c '[.tokenColors[] | {name, scope, foreground: (.settings.foreground // null), fontStyle: (.settings.fontStyle // null)}]' "$file")"
        [ "$expected" = "$actual" ] || { echo "$v: tokens drifted from syntax.json"; return 1; }
    done
}
