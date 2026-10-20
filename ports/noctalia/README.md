# Terminal Noir for Noctalia

[Noctalia](https://noctalia.dev) shell palette with dark and light modes.

## Install

Noctalia v5:

```sh
mkdir -p ~/.config/noctalia/palettes
cp "Terminal Noir.json" ~/.config/noctalia/palettes/
```

Then pick it in Settings > Theme > Palette source: Custom, Custom palette: Terminal Noir. Or set it in `config.toml`:

```toml
[theme]
source = "custom"
custom_palette = "Terminal Noir"
```

Noctalia v4 reads the same file from `~/.config/noctalia/colorschemes/Terminal Noir/Terminal Noir.json`.

Tip: Noctalia's built-in templates (GTK, btop and others) then repaint those apps from this palette too.
