# Terminal Noir para fish

Um tema para o [fish](https://fishshell.com) com comandos em azul, palavras-chave em âmbar, strings em esmeralda e a sugestão automática discreta. Um arquivo só traz as duas variantes: o fish escolhe a seção clara ou escura conforme o fundo do terminal.

![Terminal Noir para fish](../../assets/screenshots/fish.png)

## Instalação

Copie o tema e selecione-o:

```sh
mkdir -p ~/.config/fish/themes
cp terminal-noir.theme ~/.config/fish/themes/
fish_config theme choose terminal-noir
```

Se rodar `fish_config theme save terminal-noir` no lugar, as cores ficam salvas como variáveis universais, compartilhadas por todas as sessões do fish.
