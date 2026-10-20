#!/usr/bin/env bats

# Contrast is measured, never assumed: WCAG 2.1 relative luminance, computed in
# jq so the suite needs no runtime beyond the one the build already uses.

load test_helper

LIB="$PROJECT_ROOT/scripts/lib"

ratio() {
    jq -n -L "$LIB" --arg a "$1" --arg b "$2" 'include "contrast"; contrast($a; $b) * 100 | round / 100'
}

@test "contrast: black on white is 21:1" {
    [ "$(ratio '#000000' '#FFFFFF')" = "21" ]
}

@test "contrast: #777777 on white sits just under AA, as the reference says" {
    [ "$(ratio '#777777' '#FFFFFF')" = "4.48" ]
}

@test "contrast: order and case do not matter" {
    [ "$(ratio '#F5A623' '#0b0b0c')" = "9.71" ]
    [ "$(ratio '#0B0B0C' '#f5a623')" = "9.71" ]
}

@test "contrast: identical colors are 1:1" {
    [ "$(ratio '#777777' '#777777')" = "1" ]
}

@test "contrast: pure red on black weighs the red channel alone" {
    [ "$(ratio '#FF0000' '#000000')" = "5.25" ]
}
