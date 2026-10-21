# Terminal Noir for kitty

[kitty](https://sw.kovidgoyal.net/kitty/) themes: `terminal-noir.conf` (dark) and `terminal-noir-paper.conf` (light), with amber tabs, borders and cursor.

![Terminal Noir for kitty](../../assets/screenshots/kitty.png)

## Install

```sh
mkdir -p ~/.config/kitty/themes
cp terminal-noir.conf terminal-noir-paper.conf ~/.config/kitty/themes/
kitten themes --reload-in=all "Terminal Noir"
```

To follow the system light/dark preference, copy each file to the names kitty watches:

```sh
cp terminal-noir.conf ~/.config/kitty/dark-theme.auto.conf
cp terminal-noir-paper.conf ~/.config/kitty/light-theme.auto.conf
```
