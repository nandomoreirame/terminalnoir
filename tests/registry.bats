#!/usr/bin/env bats

# ports.json lists exactly the directories under ports/, with valid fields.

load test_helper

REGISTRY="$PROJECT_ROOT/ports.json"

@test "every ports/ directory is registered, and nothing else" {
    local dirs registered
    dirs="$(cd "$PROJECT_ROOT/ports" && ls -d -- */ | tr -d / | sort)"
    registered="$(jq -r '.ports[].slug' "$REGISTRY" | sort)"
    [ "$dirs" = "$registered" ]
}

@test "slugs are unique" {
    [ "$(jq '[.ports[].slug] | length' "$REGISTRY")" -eq "$(jq '[.ports[].slug] | unique | length' "$REGISTRY")" ]
}

@test "every port has a name, a known category, variants and an https homepage" {
    jq -e '
        .categories as $cats
        | all(.ports[];
            (.name | type == "string" and length > 0)
            and (.category as $c | $cats | has($c))
            and (.variants | length > 0 and all(. == "dark" or . == "light"))
            and (.homepage | startswith("https://"))
            and (.featured | type == "boolean"))' "$REGISTRY"
}

@test "ports with a light variant ship light files" {
    [ -f "$PROJECT_ROOT/ports/ghostty/terminal-noir-light" ]
    jq -e '.light' "$PROJECT_ROOT/ports/noctalia/Terminal Noir.json" >/dev/null
    [ "$(jq -r '[.ports[] | select(.variants | index("light")) | .slug] | sort | join(",")' "$REGISTRY")" = "ghostty,noctalia" ]
}
