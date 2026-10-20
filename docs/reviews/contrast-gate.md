# Revisão — contrast-gate

- **Rodada:** 2026-10-20
- **Achados abertos:** 3
- **Estado:** aguardando correção
- **Implementado por:** claude

> Arquivo reescrito por inteiro a cada `/rpi-review`. Um achado só desaparece
> daqui por ter deixado de existir no código: quem corrige não marca resolvido.

<!-- findings:begin -->

| Severidade | Arquivo:linha | Problema | Correção sugerida |
|------------|---------------|----------|-------------------|
| Low | scripts/ports/vscode.sh:79 | editorWhitespace.foreground usa surface.outline, que agora mede 3,37:1 no dark (era 1,88): o ponto de espaço em branco, decorativo, ficou bem mais forte que antes | Mapear para surface.border ou para outline com alpha (por exemplo + "80"); o indent guide ativo pode continuar em outline |
| Low | scripts/ports/p10k.sh:15 | MULTILINE_FIRST_PROMPT_GAP_FOREGROUND (preenchimento decorativo do prompt) usa surface.outline e ficou muito mais visível com o novo valor | Se for só decoração, usar surface.border |
| Low | site/vitest.config.ts:4 | Com o fsModuleCache do Vitest, o import.meta.glob de ports.ts fica velho quando entra um port novo e 12 testes falham com 'README not found' localmente até limpar o cache | Definir test.fsModuleCache: false, ou documentar npx vitest --clearCache no passo de adicionar port do CONTRIBUTING |

<!-- findings:end -->
