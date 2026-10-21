# Terminal Noir para Neovim e Vim

Esquemas de cores para o [Neovim](https://neovim.io) (`colors/terminal-noir.lua`, com grupos para Tree-sitter, LSP, diagnósticos, GitSigns e Telescope) e para o [Vim](https://www.vim.org) (`vim/colors/terminal-noir.vim`). Os dois seguem o `background`: dark aplica o Noir, light aplica o Paper.

![Terminal Noir para Neovim](../../assets/screenshots/nvim.png)

## Instalação

Copie o esquema em Lua para a sua configuração:

```sh
mkdir -p ~/.config/nvim/colors
cp colors/terminal-noir.lua ~/.config/nvim/colors/
```

Depois selecione-o no `init.lua`:

```lua
vim.o.background = 'dark' -- or 'light' for Paper
vim.cmd.colorscheme('terminal-noir')
```

No Vim, copie `vim/colors/terminal-noir.vim` para `~/.vim/colors/` e adicione `set termguicolors` e `colorscheme terminal-noir` ao seu `.vimrc`.
