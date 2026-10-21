#!/usr/bin/env bash
# Shared helpers for the bats suites. Loaded with `load test_helper`.

PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
export PROJECT_ROOT
export PALETTE="$PROJECT_ROOT/palette/palette.json"
export SYNTAX="$PROJECT_ROOT/palette/syntax.json"

temp_make() {
    mktemp -d "${BATS_TMPDIR:-/tmp}/terminalnoir-test.XXXXXX"
}

temp_del() {
    [ -n "${1:-}" ] && rm -rf "$1"
}

assert_success() {
    if [ "$status" -ne 0 ]; then
        echo "expected success, got status $status"
        echo "output: $output"
        return 1
    fi
}

assert_failure() {
    if [ "$status" -eq 0 ]; then
        echo "expected failure, got success"
        echo "output: $output"
        return 1
    fi
}

# Palette color by path, e.g. `pal dark accent.primary`.
pal() {
    jq -r --arg v "$1" --arg p "$2" '.variants[$v] | getpath($p | split("."))' "$PALETTE"
}

# "#RRGGBB" -> "[r,g,b]" (compact JSON), as Chrome themes expect.
rgb() {
    local hex="${1#\#}"
    printf '[%d,%d,%d]' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# "#RRGGBB" -> "r g b" as 0..1 reals, the way itermcolors stores components.
srgb() {
    local hex="${1#\#}"
    jq -rn --argjson r "$((16#${hex:0:2}))" --argjson g "$((16#${hex:2:2}))" --argjson b "$((16#${hex:4:2}))" \
        '"\($r / 255) \($g / 255) \($b / 255)"'
}

# Red, green and blue components of one color entry in an itermcolors plist.
itermcolor() {
    awk -v key="<key>$2</key>" '
        $0 ~ key { found = 1; next }
        found && /<key>(Red|Green|Blue) Component<\/key>/ { comp = $0; sub(/.*<key>/, "", comp); sub(/ Component.*/, "", comp); getline; gsub(/.*<real>|<\/real>.*/, ""); c[comp] = $0 }
        found && /<\/dict>/ { print c["Red"], c["Green"], c["Blue"]; exit }' "$1"
}

# "#RRGGBB" on stdin -> "rrggbb", the way fish themes write colors.
hex6() {
    tr -d '#' | tr 'A-F' 'a-f'
}

# Value of a key inside the [light] or [dark] section of a fish theme.
fishcolor() {
    awk -v sec="[$2]" -v key="$3" '
        /^\[/ { in_sec = ($0 == sec); next }
        in_sec && index($0, key " ") == 1 { print substr($0, length(key) + 2); exit }' "$1"
}
