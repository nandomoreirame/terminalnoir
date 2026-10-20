# Terminal Noir for bat

A [bat](https://github.com/sharkdp/bat) syntax theme (TextMate format).

## Install

```sh
mkdir -p "$(bat --config-dir)/themes"
cp "Terminal Noir.tmTheme" "$(bat --config-dir)/themes/"
bat cache --build
```

Use it with `--theme="Terminal Noir"` in `$(bat --config-dir)/config`, or `export BAT_THEME="Terminal Noir"`.

[delta](https://github.com/dandavison/delta) reads bat's themes: set `syntax-theme = Terminal Noir` under `[delta]` in your git config.
