# shellcheck shell=bash
# /dev/null TUI color theme per variant: a `custom_themes` entry to merge into tui.json.
# Output: ports/devnull/terminal-noir.json, ports/devnull/terminal-noir-paper.json

build_devnull() {
    local v name
    for v in dark light; do
        name="terminal-noir$([ "$v" = light ] && echo -paper || true)"
        jq -S --arg v "$v" '
            .variants[$v] as $c
            | def hex: ltrimstr("#") | ascii_downcase;
              def chan($h; $i): $h[$i:$i + 2] | explode | map(if . > 96 then . - 87 else . - 48 end) | .[0] * 16 + .[1];
              def h2($n): ($n | floor) as $x | ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"] as $d | $d[($x / 16 | floor)] + $d[$x % 16];
              # Mix `$fg` over `$bg` at `$pct` percent, as the translucent amber wash behind selections.
              def mix($fg; $bg; $pct):
                  ($fg | hex) as $f | ($bg | hex) as $b
                  | "#" + ([0, 2, 4] | map(h2(chan($b; .) + (chan($f; .) - chan($b; .)) * $pct / 100)) | join(""));
              {custom_themes: [{
                  name: "Terminal Noir\(if $v == "light" then " Paper" else "" end)",
                  base: $v,
                  colors: {
                      shell: ($c.surface.base | ascii_downcase),
                      wash: ($c.surface.elevated | ascii_downcase),
                      hairline: ($c.surface.border | ascii_downcase),
                      ink: ($c.text.primary | ascii_downcase),
                      muted: ($c.text.muted | ascii_downcase),
                      blue: ($c.accent.primary | ascii_downcase),
                      soft: mix($c.accent.primary; $c.surface.base; 15),
                      code: ($c.accent.warning | ascii_downcase),
                      warning: ($c.accent.warning | ascii_downcase),
                      success: ($c.accent.success | ascii_downcase),
                      danger: ($c.ansi.normal.red | ascii_downcase),
                      lane1: ($c.accent.primary | ascii_downcase),
                      lane2: ($c.ansi.normal.green | ascii_downcase),
                      lane3: ($c.ansi.normal.magenta | ascii_downcase),
                      lane4: ($c.ansi.normal.cyan | ascii_downcase),
                      lane5: ($c.ansi.normal.red | ascii_downcase),
                      lane6: ($c.ansi.normal.blue | ascii_downcase),
                      graph: "",
                      peak: ""
                  }
              }]}
        ' "$PALETTE" > "$OUT/ports/devnull/$name.json"
    done
}
