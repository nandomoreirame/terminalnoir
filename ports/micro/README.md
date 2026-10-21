# Terminal Noir for micro

Colorschemes for the [micro](https://micro-editor.github.io) editor: `terminal-noir.micro` (dark) and `terminal-noir-paper.micro` (light), with amber keywords, emerald strings and blue functions.

![Terminal Noir for micro](../../assets/screenshots/micro.png)

## Install

```sh
mkdir -p ~/.config/micro/colorschemes
cp terminal-noir.micro terminal-noir-paper.micro ~/.config/micro/colorschemes/
```

In micro, press `Ctrl+E` and run `set colorscheme terminal-noir`. The colors are 24-bit hex, so set `MICRO_TRUECOLOR=1` if your micro version does not detect true color.
