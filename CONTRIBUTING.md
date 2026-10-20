# Contributing

## Ground rules

- Colors live only in `palette/palette.json`. A port never hardcodes a hex value; it reads palette roles.
- Syntax colors live in `palette/syntax.json` as palette paths (`accent.primary`, `ansi.bright.cyan`).
- Generated files under `ports/` are committed, so people can install a port without running anything. `make test` fails when they drift from the palette.

## Changing a color

1. Edit `palette/palette.json`.
2. Run `make build` and `make test`.
3. Commit the palette change together with the regenerated ports.

## Adding a port

1. Create `scripts/ports/<app>.sh` defining `build_<app>`, which writes its files under `"$OUT/ports/<app>/"`. Read colors from `"$PALETTE"` (and `"$SYNTAX"` for highlighting) with `jq`; see `scripts/ports/btop.sh` for a small example.
2. Add `<app>` to the `PORTS` list in `scripts/build`.
3. Add the generated files to `GENERATED` in `tests/build.bats`, and a mapping test in `tests/ports.bats` that checks the app's key slots against `pal <variant> <role>`.
4. Write `ports/<app>/README.md` with install steps: a `# Terminal Noir for <App>` title, a one-paragraph description (the site shows it on the port card), then the steps. Add `README.pt-br.md` too, titled `# Terminal Noir para <App>`, with the same code blocks.
5. Register the port in `ports.json` (name, category, variants, homepage) and list it in the main README.
6. Run `make build test lint`.

Prefer the app's native theme format, and ship a light variant when the app supports switching.
