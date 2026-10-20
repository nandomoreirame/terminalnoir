# Terminal Noir para Shiki

Temas do [Shiki](https://shiki.style) para código em sites: `terminal-noir.json` (escuro) e `terminal-noir-paper.json` (claro). Todos os tokens passam no WCAG AA sobre o fundo do tema.

![Terminal Noir para Shiki](../../assets/screenshots/shiki.png)

## Instalação

Copie os dois arquivos para junto da sua configuração e passe-os como objetos de tema:

```js
import noir from './terminal-noir.json' with { type: 'json' };
import paper from './terminal-noir-paper.json' with { type: 'json' };

const html = await codeToHtml(code, { lang: 'ts', themes: { dark: noir, light: paper } });
```

No Astro, defina `markdown.shikiConfig.themes` como `{ dark: noir, light: paper }`. Com `defaultColor: false`, o Shiki gera as variáveis `--shiki-dark` e `--shiki-light` e o seu CSS escolhe uma delas.
