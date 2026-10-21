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

@test "iterm2: one itermcolors plist per variant with sRGB palette components" {
    local v f
    for v in dark light; do
        f="$PORTS/iterm2/Terminal Noir$([ "$v" = light ] && echo ' Paper' || true).itermcolors"
        grep -Fq '<!DOCTYPE plist' "$f"
        [ "$(itermcolor "$f" 'Background Color')" = "$(srgb "$(pal $v surface.base)")" ]
        [ "$(itermcolor "$f" 'Foreground Color')" = "$(srgb "$(pal $v text.primary)")" ]
        [ "$(itermcolor "$f" 'Cursor Color')" = "$(srgb "$(pal $v accent.primary)")" ]
        [ "$(itermcolor "$f" 'Cursor Text Color')" = "$(srgb "$(pal $v accent.onPrimary)")" ]
        [ "$(itermcolor "$f" 'Selection Color')" = "$(srgb "$(pal $v surface.selection)")" ]
        [ "$(itermcolor "$f" 'Link Color')" = "$(srgb "$(pal $v accent.info)")" ]
        [ "$(itermcolor "$f" 'Ansi 3 Color')" = "$(srgb "$(pal $v ansi.normal.yellow)")" ]
        [ "$(itermcolor "$f" 'Ansi 15 Color')" = "$(srgb "$(pal $v ansi.bright.white)")" ]
        [ "$(grep -c '<string>sRGB</string>' "$f")" -eq 24 ]
        if command -v xmllint >/dev/null 2>&1; then
            xmllint --noout "$f"
        fi
    done
}

@test "zsh: syntax-highlighting and autosuggestion styles per variant" {
    local v f
    for v in dark light; do
        f="$PORTS/zsh/terminal-noir$([ "$v" = light ] && echo -paper || true).zsh"
        grep -Fqx "ZSH_HIGHLIGHT_STYLES[command]='fg=$(pal $v accent.info)'" "$f"
        grep -Fqx "ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=$(pal $v accent.primary)'" "$f"
        grep -Fqx "ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=$(pal $v accent.success)'" "$f"
        grep -Fqx "ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=$(pal $v accent.error)'" "$f"
        grep -Fqx "ZSH_HIGHLIGHT_STYLES[comment]='fg=$(pal $v text.muted)'" "$f"
        grep -Fqx "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=$(pal $v text.faint)'" "$f"
        if command -v zsh >/dev/null 2>&1; then
            run zsh -fc "source '$f'; print -r -- \$ZSH_HIGHLIGHT_STYLES[command]"
            assert_success
            [ "$output" = "fg=$(pal $v accent.info)" ]
        fi
    done
}

@test "fish: one theme with light and dark sections from the palette" {
    local f="$PORTS/fish/terminal-noir.theme" v
    for v in dark light; do
        [ "$(fishcolor "$f" "$v" '# preferred_background:')" = "$(pal $v surface.base | hex6)" ]
        [ "$(fishcolor "$f" "$v" fish_color_command)" = "$(pal $v accent.info | hex6)" ]
        [ "$(fishcolor "$f" "$v" fish_color_keyword)" = "$(pal $v accent.primary | hex6)" ]
        [ "$(fishcolor "$f" "$v" fish_color_quote)" = "$(pal $v accent.success | hex6)" ]
        [ "$(fishcolor "$f" "$v" fish_color_error)" = "$(pal $v accent.error | hex6)" ]
        [ "$(fishcolor "$f" "$v" fish_color_selection)" = "--background=$(pal $v surface.selection | hex6)" ]
    done
    if command -v fish >/dev/null 2>&1; then
        local cfg
        cfg="$(temp_make)"
        mkdir -p "$cfg/fish/themes"
        cp "$f" "$cfg/fish/themes/"
        run env XDG_CONFIG_HOME="$cfg" fish --no-config -c 'fish_config theme list | string match -q terminal-noir'
        temp_del "$cfg"
        assert_success
    fi
}

@test "alacritty: primary, cursor and ANSI colors per variant, valid TOML" {
    local v f
    for v in dark light; do
        f="$PORTS/alacritty/terminal-noir$([ "$v" = light ] && echo -paper || true).toml"
        grep -Fqx "background = \"$(pal $v surface.base)\"" "$f"
        grep -Fqx "foreground = \"$(pal $v text.primary)\"" "$f"
        grep -Fqx "cursor = \"$(pal $v accent.primary)\"" "$f"
        grep -Fqx "yellow = \"$(pal $v ansi.normal.yellow)\"" "$f"
        grep -Fqx "white = \"$(pal $v ansi.bright.white)\"" "$f"
        run /usr/bin/python3 -I -c 'import sys, tomllib; c = tomllib.load(open(sys.argv[1], "rb"))["colors"]; print(c["primary"]["background"], c["bright"]["cyan"])' "$f"
        assert_success
        [ "$output" = "$(pal $v surface.base) $(pal $v ansi.bright.cyan)" ]
    done
}

@test "kitty: color0-15, cursor, borders and tabs per variant" {
    local v f
    for v in dark light; do
        f="$PORTS/kitty/terminal-noir$([ "$v" = light ] && echo -paper || true).conf"
        grep -Fqx "background $(pal $v surface.base)" "$f"
        grep -Fqx "foreground $(pal $v text.primary)" "$f"
        grep -Fqx "cursor $(pal $v accent.primary)" "$f"
        grep -Fqx "color3 $(pal $v ansi.normal.yellow)" "$f"
        grep -Fqx "color15 $(pal $v ansi.bright.white)" "$f"
        grep -Fqx "active_border_color $(pal $v accent.primary)" "$f"
        grep -Fqx "active_tab_background $(pal $v accent.primary)" "$f"
    done
}

@test "micro: colorscheme with syntax roles per variant" {
    local v f
    for v in dark light; do
        f="$PORTS/micro/terminal-noir$([ "$v" = light ] && echo -paper || true).micro"
        grep -Fqx "color-link default \"$(pal $v text.primary),$(pal $v surface.base)\"" "$f"
        grep -Fqx "color-link comment \"$(pal $v text.muted)\"" "$f"
        grep -Fqx "color-link statement \"$(pal $v accent.primary)\"" "$f"
        grep -Fqx "color-link constant.string \"$(pal $v accent.success)\"" "$f"
        grep -Fqx "color-link identifier \"$(pal $v accent.info)\"" "$f"
    done
}

@test "hyper: plugin decorates the config with the chosen variant" {
    local dir="$PORTS/hyper"
    jq -e '.name == "hyper-terminal-noir" and .main == "index.js"' "$dir/package.json"
    if command -v node >/dev/null 2>&1; then
        run node -e '
            const p = require(process.argv[1]);
            const d = p.decorateConfig({});
            const l = p.decorateConfig({ terminalNoir: { variant: "paper" } });
            console.log(d.backgroundColor, d.cursorColor, d.colors.yellow, l.backgroundColor, l.colors.lightWhite);' "$dir/index.js"
        assert_success
        [ "$output" = "$(pal dark surface.base) $(pal dark accent.primary) $(pal dark ansi.normal.yellow) $(pal light surface.base) $(pal light ansi.bright.white)" ]
    fi
}

@test "nvim: Lua and Vim colorschemes follow background and the syntax roles" {
    local lua="$PORTS/nvim/colors/terminal-noir.lua" vimf="$PORTS/nvim/vim/colors/terminal-noir.vim" v bg out
    grep -Fq "vim.g.colors_name = \"terminal-noir\"" "$lua"
    grep -Fq "let g:colors_name = \"terminal-noir\"" "$vimf"
    for v in dark light; do
        bg="$(pal $v surface.base)"
        out="$(env -i HOME="$BATS_TMPDIR" PATH=/usr/bin:/bin vim -Nu NONE -i NONE -es \
            -c "set background=$v termguicolors rtp^=$PORTS/nvim/vim" -c 'colorscheme terminal-noir' \
            -c 'call writefile([synIDattr(hlID("Normal"), "bg#"), synIDattr(hlID("Comment"), "fg#"), synIDattr(hlID("Statement"), "fg#")], "/dev/stdout")' \
            -c 'qa!' 2>&1 | tr 'a-f' 'A-F' | tr '\n' ' ')"
        [ "$out" = "$bg $(pal $v text.muted) $(pal $v accent.primary) " ] || { echo "vim $v: $out"; return 1; }
        if command -v nvim >/dev/null 2>&1; then
            out="$(nvim --clean --headless -c "set background=$v rtp^=$PORTS/nvim" -c 'colorscheme terminal-noir' \
                -c 'lua io.stdout:write(string.format("#%06X #%06X", vim.api.nvim_get_hl(0, {name = "Normal"}).bg, vim.api.nvim_get_hl(0, {name = "@string"}).fg))' -c 'qa!' 2>&1)"
            [ "$out" = "$bg $(pal $v accent.success)" ] || { echo "nvim $v: $out"; return 1; }
        fi
    done
}

@test "telegram: a palette per variant with every key resolved" {
    local v f
    for v in dark light; do
        f="$PORTS/telegram/terminal-noir$([ "$v" = light ] && echo -paper || true).tdesktop-palette"
        grep -Fqx "tnBase: $(pal $v surface.base | tr 'A-F' 'a-f');" "$f"
        grep -Fqx "tnAccent: $(pal $v accent.primary | tr 'A-F' 'a-f');" "$f"
        grep -Eq '^windowBg: tnBase;' "$f"
        ! grep -q 'ctp' "$f"
        # Every name a key points at is defined above it.
        run awk -F': ' '/^[A-Za-z0-9]+: / { v = $2; sub(/;.*/, "", v); if (v !~ /^#/ && !(v in d)) print "undefined: " v; d[$1] = 1 }' "$f"
        [ -z "$output" ] || { echo "$f: $output"; return 1; }
    done
}

@test "telegram: a theme zip per variant with the palette and the matching wallpaper" {
    local v name wall tmp
    for v in dark light; do
        name="terminal-noir$([ "$v" = light ] && echo -paper || true)"
        wall="$([ "$v" = light ] && echo paper || echo noir)"
        [ "$(bsdtar -tf "$PORTS/telegram/$name.tdesktop-theme" | sort | tr '\n' ' ')" = "background.png colors.tdesktop-theme " ]
        tmp="$(temp_make)"
        bsdtar -xf "$PORTS/telegram/$name.tdesktop-theme" -C "$tmp"
        cmp -s "$tmp/colors.tdesktop-theme" "$PORTS/telegram/$name.tdesktop-palette" || { temp_del "$tmp"; echo "colors differ: $v"; return 1; }
        cmp -s "$tmp/background.png" "$PROJECT_ROOT/assets/wallpapers/$wall.png" || { temp_del "$tmp"; echo "wallpaper differs: $v"; return 1; }
        temp_del "$tmp"
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
