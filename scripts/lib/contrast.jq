# WCAG 2.1 contrast between two #RRGGBB colors (tests/contrast.bats).
def hex_byte: ascii_downcase | explode | map(if . >= 97 then . - 87 else . - 48 end) | .[0] * 16 + .[1];
def channel: . / 255 | if . <= 0.04045 then . / 12.92 else pow((. + 0.055) / 1.055; 2.4) end;
def luminance: ltrimstr("#") | [.[0:2], .[2:4], .[4:6]] | map(hex_byte | channel)
  | 0.2126 * .[0] + 0.7152 * .[1] + 0.0722 * .[2];
def contrast($a; $b): [($a | luminance), ($b | luminance)] | (max + 0.05) / (min + 0.05);
