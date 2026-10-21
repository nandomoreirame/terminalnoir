# Terminal Noir for Hyper

A [Hyper](https://hyper.is) plugin that paints the terminal, the tabs and the cursor. Dark by default; set `variant: 'paper'` for the light one.

![Terminal Noir for Hyper](../../assets/screenshots/hyper.png)

## Install

Copy the plugin into Hyper's local plugins folder, next to your `.hyper.js` (`~/Library/Application Support/Hyper` on macOS):

```sh
mkdir -p ~/.config/Hyper/.hyper_plugins/local/hyper-terminal-noir
cp package.json index.js ~/.config/Hyper/.hyper_plugins/local/hyper-terminal-noir/
```

Then enable it in `.hyper.js` (`Ctrl+,` opens it):

```js
module.exports = {
  config: {
    terminalNoir: { variant: 'noir' }, // or 'paper'
  },
  localPlugins: ['hyper-terminal-noir'],
};
```

Reload with `Ctrl+Shift+R`.
