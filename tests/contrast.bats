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

palette_failures() {
    jq -r -L "$LIB" 'include "contrast"; palette_failures' "$PALETTE"
}

syntax_failures() {
    jq -r -L "$LIB" --slurpfile syn "$SYNTAX" 'include "contrast"; syntax_failures($syn[0].tokens)' "$PALETTE"
}

@test "every readable role clears its floor on every surface, in both variants" {
    run palette_failures
    assert_success
    [ -z "$output" ] || { echo "$output"; return 1; }
}

@test "every syntax role clears AA on every surface, in both variants" {
    run syntax_failures
    assert_success
    [ -z "$output" ] || { echo "$output"; return 1; }
}

@test "the gate can fail: the old Paper bright cyan is reported" {
    run jq -r -L "$LIB" 'include "contrast"; .variants.light.ansi.bright.cyan = "#3192AA" | palette_failures' "$PALETTE"
    assert_success
    grep -q '^light ansi.bright.cyan #3192AA on #E9E6DF: 2.89 < 4.5$' <<<"$output"
}

@test "background slots are the only exemptions" {
    run jq -r -L "$LIB" -n 'include "contrast";
        [background_slot("dark"; "normal"; "black"), background_slot("light"; "bright"; "white"),
         background_slot("dark"; "bright"; "black"), background_slot("light"; "normal"; "white")]
        | map(tostring) | join(",")'
    [ "$output" = "true,true,false,false" ]
}

# Runs a gate against the palette after a jq edit, so each floor is seen failing.
gate_with() {
    jq -r -L "$LIB" --slurpfile syn "$SYNTAX" "include \"contrast\"; $1 | $2" "$PALETTE"
}

@test "each floor reports its own failure" {
    run gate_with '.variants.dark.text.faint = "#222222"' palette_failures
    grep -Eq '^dark text\.faint #222222 on #0B0B0C: [0-9.]+ < 3$' <<<"$output"
    run gate_with '.variants.light.surface.outline = "#FBFAF7"' palette_failures
    grep -Eq '^light surface\.outline #FBFAF7 on #FBFAF7: 1 < 3$' <<<"$output"
    run gate_with '.variants.dark.accent.onPrimary = "#F5A623"' palette_failures
    grep -Eq '^dark accent\.onPrimary #F5A623 on #F5A623: 1 < 4\.5$' <<<"$output"
    run gate_with '.variants.light.surface.selection = "#1C1A17"' palette_failures
    grep -Eq '^light text\.primary on selection #1C1A17 on #1C1A17: 1 < 4\.5$' <<<"$output"
}

@test "the gate skips the background slots and nothing else" {
    run gate_with '.variants.dark.ansi.normal.black = "#0B0B0C" | .variants.light.ansi.bright.white = "#FBFAF7" | .variants.dark.ansi.bright.black = "#0B0B0C"' palette_failures
    assert_success
    if grep -q 'ansi.normal.black\|ansi.bright.white' <<<"$output"; then echo "$output"; return 1; fi
    grep -q '^dark ansi.bright.black #0B0B0C on #0B0B0C: 1 < 4.5$' <<<"$output"
}

@test "the syntax gate can fail" {
    run gate_with '.variants.dark.text.muted = "#222222"' 'syntax_failures($syn[0].tokens)'
    assert_success
    grep -Eq '^dark syntax Comment #222222 on #0B0B0C: [0-9.]+ < 4\.5$' <<<"$output"
}
