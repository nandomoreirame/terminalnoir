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
