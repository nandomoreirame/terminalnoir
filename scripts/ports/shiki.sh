# shellcheck shell=bash
# Shiki themes (TextMate JSON, the format Shiki and VS Code read), one per variant.
# Output: ports/shiki/terminal-noir.json (dark), ports/shiki/terminal-noir-paper.json (light)

build_shiki() {
    local variant slug name
    for variant in dark light; do
        if [ "$variant" = dark ]; then
            slug=terminal-noir name="Terminal Noir"
        else
            slug=terminal-noir-paper name="Terminal Noir Paper"
        fi
        jq --arg v "$variant" --arg slug "$slug" --arg name "$name" --slurpfile syn "$SYNTAX" '
            .variants[$v] as $c
            | def ref($p): $c | getpath($p | split("."));
            {
                name: $slug,
                displayName: $name,
                type: $v,
                colors: { "editor.background": $c.surface.base, "editor.foreground": $c.text.primary },
                tokenColors: [
                    $syn[0].tokens[]
                    | {
                        name,
                        scope,
                        settings: ((if .color then { foreground: ref(.color) } else {} end)
                            + (if .fontStyle then { fontStyle } else {} end))
                    }
                ]
            }' "$PALETTE" > "$OUT/ports/shiki/$slug.json"
    done
}
