# Terminal Noir para GTK 4 / libadwaita

Cores escuras e o acento âmbar para apps GTK 4 e libadwaita (Nautilus, seletor de arquivos, diálogos de configuração), além de um tema de ícones com pastas em âmbar.

## Cores e acento

```sh
cp gtk.css ~/.config/gtk-4.0/gtk.css     # or @import it from your own gtk.css
```

O libadwaita 1.6+ tira o acento da cor predefinida do sistema por meio de variáveis CSS; o `gtk.css` define essas variáveis com o âmbar exato. Escolha também a predefinição mais próxima, para os apps que só leem o portal:

```sh
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface accent-color orange
```

O Nautilus e o seletor de arquivos forçam um acento cinza nas listas de arquivos; o `gtk.css` sobrescreve isso para que a seleção e o foco fiquem em âmbar.

## Pastas em âmbar

Os ícones de pasta do Adwaita são de um azul fixo. O `scripts/build-gtk-icons` cria um tema de ícones `Terminal-Noir` a partir do Adwaita instalado, recolorindo só as pastas:

```sh
scripts/build-gtk-icons            # writes ~/.local/share/icons/Terminal-Noir
gsettings set org.gnome.desktop.interface icon-theme Terminal-Noir
```

Rode de novo depois de uma atualização do `adwaita-icon-theme`. Reabra os apps GTK para ver as mudanças.
