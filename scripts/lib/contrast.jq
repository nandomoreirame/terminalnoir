# WCAG 2.1 contrast between two #RRGGBB colors (tests/contrast.bats).
def hex_byte: ascii_downcase | explode | map(if . >= 97 then . - 87 else . - 48 end) | .[0] * 16 + .[1];
def channel: . / 255 | if . <= 0.04045 then . / 12.92 else pow((. + 0.055) / 1.055; 2.4) end;
def luminance: ltrimstr("#") | [.[0:2], .[2:4], .[4:6]] | map(hex_byte | channel)
  | 0.2126 * .[0] + 0.7152 * .[1] + 0.0722 * .[2];
def contrast($a; $b): [($a | luminance), ($b | luminance)] | (max + 0.05) / (min + 0.05);

def surfaces: [.surface.base, .surface.raised, .surface.elevated];

# One line per failing pair. $min, not $floor: a parameter shadows the builtin.
def below($variant; $role; $fg; $bgs; $min):
  $bgs[] as $bg | contrast($fg; $bg) as $r | select($r < $min)
  | "\($variant) \($role) \($fg) on \($bg): \(($r * 100 | floor) / 100) < \($min)";

# A terminal paints these as background, never as text on it.
def background_slot($variant; $group; $name):
  ($variant == "dark" and $group == "normal" and $name == "black")
  or ($variant == "light" and $group == "bright" and $name == "white");

# Text and accents at 4.5:1; faint and outline at 3:1 (non-text, WCAG 1.4.11).
def palette_failures:
  .variants | to_entries[] | .key as $v | .value as $c | ($c | surfaces) as $s
  | (
      ($c.text | to_entries[] | below($v; "text.\(.key)"; .value; $s; if .key == "faint" then 3 else 4.5 end)),
      ($c.accent | to_entries[] | select(.key != "onPrimary") | below($v; "accent.\(.key)"; .value; $s; 4.5)),
      below($v; "surface.outline"; $c.surface.outline; $s; 3),
      below($v; "accent.onPrimary"; $c.accent.onPrimary; [$c.accent.primary]; 4.5),
      below($v; "text.primary on selection"; $c.text.primary; [$c.surface.selection]; 4.5),
      ($c.ansi | to_entries[] | .key as $g | .value | to_entries[]
        | select(background_slot($v; $g; .key) | not)
        | below($v; "ansi.\($g).\(.key)"; .value; $s; 4.5))
    );

def syntax_failures($tokens):
  .variants | to_entries[] | .key as $v | .value as $c | ($c | surfaces) as $s
  | $tokens[] | select(.color) | .name as $n | .color as $p
  | below($v; "syntax \($n)"; ($c | getpath($p | split("."))); $s; 4.5);
