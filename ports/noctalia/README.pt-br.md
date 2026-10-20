# Terminal Noir para Noctalia

Paleta para o shell [Noctalia](https://noctalia.dev), com os modos escuro e claro.

## Instalação

Noctalia v5:

```sh
mkdir -p ~/.config/noctalia/palettes
cp "Terminal Noir.json" ~/.config/noctalia/palettes/
```

Depois escolha em Configurações > Tema > Fonte da paleta: Personalizada, Paleta personalizada: Terminal Noir. Ou defina no `config.toml`:

```toml
[theme]
source = "custom"
custom_palette = "Terminal Noir"
```

O Noctalia v4 lê o mesmo arquivo em `~/.config/noctalia/colorschemes/Terminal Noir/Terminal Noir.json`.

Dica: os modelos nativos do Noctalia (GTK, btop e outros) passam a pintar esses apps com esta paleta também.
