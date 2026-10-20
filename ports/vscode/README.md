# Terminal Noir for VS Code and Cursor

A dark color theme extension: editor chrome, integrated terminal and syntax highlighting.

## Install

From the repo root:

```sh
scripts/install-vscode   # packages a .vsix and installs it in VS Code and Cursor
```

Then select it: Preferences > Color Theme > Terminal Noir, or in `settings.json`:

```json
"workbench.colorTheme": "Terminal Noir"
```

A folder dropped into `~/.vscode/extensions` is ignored by current VS Code and Cursor, which only load extensions registered by `--install-extension`. Rerun the script after `make build` changes the theme.
