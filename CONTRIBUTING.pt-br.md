# Como contribuir

## Regras básicas

- As cores ficam só no `palette/palette.json`. Um port nunca fixa um valor hex; ele lê papéis da paleta.
- As cores de sintaxe ficam no `palette/syntax.json`, como caminhos da paleta (`accent.primary`, `ansi.bright.cyan`).
- Os arquivos gerados em `ports/` são commitados, para que qualquer pessoa instale um port sem rodar nada. O `make test` falha quando eles divergem da paleta.

## Mudando uma cor

1. Edite o `palette/palette.json`.
2. Rode `make build` e `make test`.
3. Faça o commit da mudança na paleta junto com os ports regenerados.

## Adicionando um port

1. Crie `scripts/ports/<app>.sh` definindo `build_<app>`, que escreve os arquivos em `"$OUT/ports/<app>/"`. Leia as cores de `"$PALETTE"` (e de `"$SYNTAX"` para o destaque de sintaxe) com `jq`; veja `scripts/ports/btop.sh` como exemplo curto.
2. Adicione `<app>` à lista `PORTS` em `scripts/build`.
3. Adicione os arquivos gerados a `GENERATED` em `tests/build.bats`, e um teste de mapeamento em `tests/ports.bats` que confira as cores principais do app contra `pal <variant> <role>`.
4. Escreva o `ports/<app>/README.md` com o passo a passo: um título `# Terminal Noir for <App>`, um parágrafo de descrição (o site mostra no card do port) e os passos. Escreva também o `README.pt-br.md`, com o título `# Terminal Noir para <App>` e os mesmos blocos de código.
5. Registre o port no `ports.json` (nome, categoria, variantes, site) e liste no README principal.
6. Rode `make build test lint`.

Prefira o formato de tema nativo do app, e inclua uma variante clara quando o app permitir trocar de tema.
