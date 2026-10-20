#!/usr/bin/env bats

# Translated docs exist for every port, and translation never touches code:
# fenced blocks must match the English README byte for byte.

load test_helper

LOCALES=(pt-br)

# Print every fenced code block of a markdown file, fences included.
code_blocks() {
    awk '/^```/ { inside = !inside; print; next } inside { print }' "$1"
}

@test "every port has a README in each locale with a translated title" {
    local dir locale
    for dir in "$PROJECT_ROOT"/ports/*/; do
        for locale in "${LOCALES[@]}"; do
            [ -f "$dir/README.$locale.md" ] || { echo "missing: $dir/README.$locale.md"; return 1; }
        done
        head -1 "$dir/README.pt-br.md" | grep -q '^# Terminal Noir para ' || { echo "bad title: $dir"; return 1; }
    done
}

@test "translated port READMEs keep the English code blocks unchanged" {
    local dir locale
    for dir in "$PROJECT_ROOT"/ports/*/; do
        for locale in "${LOCALES[@]}"; do
            diff <(code_blocks "$dir/README.md") <(code_blocks "$dir/README.$locale.md") || {
                echo "code blocks differ: $dir/README.$locale.md"
                return 1
            }
        done
    done
}

@test "the contributing guide is translated" {
    local locale
    for locale in "${LOCALES[@]}"; do
        [ -f "$PROJECT_ROOT/CONTRIBUTING.$locale.md" ]
        diff <(code_blocks "$PROJECT_ROOT/CONTRIBUTING.md") <(code_blocks "$PROJECT_ROOT/CONTRIBUTING.$locale.md")
    done
}
