# Terminal Noir for niri

Window decorations for [niri](https://github.com/niri-wm/niri): an amber focus ring at 80% opacity, outline grey on unfocused windows, error pink on urgent ones, and an amber insert hint.

## Install

Copy the `focus-ring`, `border` and `insert-hint` blocks from `terminal-noir.kdl` into the `layout {}` section of `~/.config/niri/config.kdl`, then check it:

```sh
niri validate
```

niri reloads `config.kdl` on save.
