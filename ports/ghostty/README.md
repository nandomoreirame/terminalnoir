# Terminal Noir for Ghostty

[Ghostty](https://ghostty.org) themes for dark and light.

## Install

```sh
mkdir -p ~/.config/ghostty/themes
cp terminal-noir-dark terminal-noir-light ~/.config/ghostty/themes/
```

In `~/.config/ghostty/config`, follow the system light/dark preference:

```
theme = light:terminal-noir-light,dark:terminal-noir-dark
```

New windows pick it up; reload open ones with `Ctrl+Shift+,`.
