#!/usr/bin/env bats

# The canonical palette is complete and well formed.

load test_helper

@test "dark and light define the same color paths" {
    local dark light
    dark="$(jq -c '.variants.dark | [paths(scalars)] | sort' "$PALETTE")"
    light="$(jq -c '.variants.light | [paths(scalars)] | sort' "$PALETTE")"
    [ "$dark" = "$light" ]
}

@test "every color is an uppercase #RRGGBB hex" {
    run jq -r '.variants[] | [paths(scalars) as $p | getpath($p)] | .[]' "$PALETTE"
    assert_success
    local c
    while IFS= read -r c; do
        [[ "$c" =~ ^#[0-9A-F]{6}$ ]] || { echo "bad color: $c"; return 1; }
    done <<<"$output"
}

@test "the ANSI block has all 16 colors" {
    [ "$(jq '.variants.dark.ansi | [.normal, .bright] | map(keys | length) | add' "$PALETTE")" -eq 16 ]
}

@test "every syntax role resolves to a palette color in both variants" {
    local path v
    while IFS= read -r path; do
        for v in dark light; do
            [[ "$(pal "$v" "$path")" =~ ^#[0-9A-F]{6}$ ]] || { echo "unresolved: $v $path"; return 1; }
        done
    done < <(jq -r '.tokens[] | .color // empty' "$SYNTAX")
}

@test "site anchors: amber accent on near-black, emerald success" {
    [ "$(pal dark accent.primary)" = "#F5A623" ]
    [ "$(pal dark surface.base)" = "#0B0B0C" ]
    [ "$(pal dark accent.success)" = "#34D399" ]
    [ "$(pal light accent.primary)" = "#865700" ]
}

@test "README palette tables match palette.json" {
    local readme="$PROJECT_ROOT/README.md" section role hex n=0
    for section in Dark Light; do
        while IFS='|' read -r _ role hex _; do
            role="$(tr -d ' `' <<<"$role")"
            hex="$(tr -d ' `' <<<"$hex")"
            [ "$(pal "${section,,}" "$role")" = "$hex" ] || { echo "$section $role: README $hex"; return 1; }
            n=$((n + 1))
        done < <(sed -n "/^### $section$/,/^#/p" "$readme" | grep -E '^\| `[a-z]+\.[A-Za-z]+` \|')
    done
    [ "$n" -ge 20 ]
}

@test "README states the contrast floors the suite enforces" {
    local section
    section="$(sed -n '/^## Accessibility$/,/^## /p' "$PROJECT_ROOT/README.md")"
    grep -q '4.5:1' <<<"$section"
    grep -q '3:1' <<<"$section"
    grep -q 'tests/contrast.bats' <<<"$section"
}
