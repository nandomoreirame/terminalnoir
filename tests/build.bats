#!/usr/bin/env bats

# Every generated port is committed and matches a fresh build of the palette.

load test_helper

GENERATED=(
    "ports/noctalia/Terminal Noir.json"
    "ports/ghostty/terminal-noir-dark"
    "ports/ghostty/terminal-noir-light"
    "ports/iterm2/Terminal Noir.itermcolors"
    "ports/iterm2/Terminal Noir Paper.itermcolors"
    "ports/zsh/terminal-noir.zsh"
    "ports/zsh/terminal-noir-paper.zsh"
    "ports/fish/terminal-noir.theme"
    "ports/vscode/package.json"
    "ports/vscode/themes/terminal-noir-color-theme.json"
    "ports/bat/Terminal Noir.tmTheme"
    "ports/chrome/manifest.json"
    "ports/btop/terminal-noir.theme"
    "ports/fzf/terminal-noir.sh"
    "ports/gtk/gtk.css"
    "ports/niri/terminal-noir.kdl"
    "ports/obsidian/Terminal Noir/theme.css"
    "ports/obsidian/Terminal Noir/manifest.json"
    "ports/p10k/terminal-noir.p10k.zsh"
    "ports/shiki/terminal-noir.json"
    "ports/shiki/terminal-noir-paper.json"
)

setup() {
    TEST_DIR="$(temp_make)"
}

teardown() {
    temp_del "$TEST_DIR"
}

@test "committed ports match a fresh build" {
    run "$PROJECT_ROOT/scripts/build" "$TEST_DIR"
    assert_success

    local f
    for f in "${GENERATED[@]}"; do
        [ -f "$TEST_DIR/$f" ] || { echo "not built: $f"; return 1; }
        cmp -s "$TEST_DIR/$f" "$PROJECT_ROOT/$f" || {
            echo "out of date: $f (run make build)"
            return 1
        }
    done
}

@test "the build is deterministic" {
    "$PROJECT_ROOT/scripts/build" "$TEST_DIR/a"
    "$PROJECT_ROOT/scripts/build" "$TEST_DIR/b"
    diff -r "$TEST_DIR/a" "$TEST_DIR/b"
}

@test "every port has a README" {
    local dir
    for dir in "$PROJECT_ROOT"/ports/*/; do
        [ -f "$dir/README.md" ] || { echo "missing README: $dir"; return 1; }
    done
}
