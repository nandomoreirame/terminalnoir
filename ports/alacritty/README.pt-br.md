# Terminal Noir para Alacritty

Arquivos de cores para o [Alacritty](https://alacritty.org): `terminal-noir.toml` (escuro) e `terminal-noir-paper.toml` (claro), com o cursor âmbar, os resultados de busca e as dicas.

![Terminal Noir para Alacritty](../../assets/screenshots/alacritty.png)

## Instalação

```sh
mkdir -p ~/.config/alacritty
cp terminal-noir.toml terminal-noir-paper.toml ~/.config/alacritty/
```

Importe um deles em `~/.config/alacritty/alacritty.toml`:

```toml
[general]
import = ["~/.config/alacritty/terminal-noir.toml"]
```

O Alacritty recarrega a configuração ao salvar.
