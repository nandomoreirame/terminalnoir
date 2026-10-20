import type { Locale } from './locales';

// UI strings. Keys ending in "Html" hold trusted markup (links, <code>) and are
// rendered with set:html; everything else is plain text. {name} placeholders
// are filled by t(key, { name }).
const en = {
  'meta.title': 'Terminal Noir: a noir theme for everything you type in',
  'meta.description':
    'Terminal Noir: cold near-black surfaces, one amber accent. One palette, generated into every app you use.',
  'a11y.skip': 'Skip to content',
  'a11y.home': 'Terminal Noir, home',
  'nav.main': 'Main',
  'nav.footer': 'Footer',
  'nav.home': 'Home',
  'nav.about': 'About',
  'nav.ports': 'Ports',
  'nav.palette': 'Palette',
  'nav.docs': 'Docs',
  'nav.github': 'GitHub',
  'nav.getStarted': 'Get started',
  'nav.language': 'Language',
  'theme.group': 'Color theme',
  'theme.noir': 'noir',
  'theme.paper': 'paper',
  'footer.textHtml': 'MIT licensed. Born from the design of <a class="hover:text-fg" href="https://nandomoreira.dev">nandomoreira.dev</a>.',

  'hero.badge': 'v{version} — {count} ports, dark and light',
  'hero.title': 'A noir theme for everything you type in.',
  'hero.subtitle': 'Cold near-black surfaces, one amber accent. One palette, generated into every app on your desktop.',
  'hero.browse': 'Browse ports',
  'hero.viewPalette': 'View palette',
  'hero.statMit': 'MIT licensed',
  'hero.statPorts': '{count} ports',
  'hero.statTested': 'Tested against drift',

  'terminal.label': 'A Ghostty window in Terminal Noir: a shell prompt, then bat showing highlighted Rust code',
  'terminal.comment': '// luminance stepped by cold surfaces',
  'terminal.synced': 'synced with palette.json',

  'ports.eyebrow': 'Ecosystem',
  'ports.title': 'Ports',
  'ports.descriptionHome': 'Tuned for the shell, the compositor, terminals, editors and command-line tools.',
  'ports.description':
    'Tuned for the shell, the compositor, terminals, editors and command-line tools. Each port has its install steps.',
  'ports.metaDescription': 'Terminal Noir for your shell, compositor, terminal, editor, browser and CLI tools.',
  'ports.all': 'All {count} ports',
  'ports.searchLabel': 'Search ports',
  'ports.searchPlaceholder': 'Search {count} ports…',
  'ports.count': '{count} apps and growing',
  'ports.noResults': 'No port matches that search.',
  'ports.shownOne': '1 port shown',
  'ports.shownMany': '{count} ports shown',
  'ports.requestBadge': 'request',
  'ports.requestTitle': 'Request a port',
  'ports.requestBody': 'Missing your terminal, editor or tool? Open an issue on GitHub.',
  'ports.requestCta': 'Open issue',
  'ports.breadcrumb': 'Breadcrumb',
  'ports.pageTitle': 'Terminal Noir for {name}',
  'ports.source': 'Source',

  'variant.dark': 'dark',
  'variant.light': 'light',
  'category.desktop': 'Desktop',
  'category.terminal': 'Terminal',
  'category.editor': 'Editors',
  'category.cli': 'CLI tools',
  'category.apps': 'Apps',

  'quickstart.eyebrow': 'Quickstart',
  'quickstart.title': 'Installation',
  'quickstart.descriptionHome': 'Each port ships ready-made files. Copy, and you are done.',
  'quickstart.description':
    'Ports ship ready-made files, so nothing needs building. Every port page has the full steps.',
  'install.tablist': 'Install a port',
  'install.fromHtml': 'From {link}, in the repo root:',
  'install.copy': 'Copy',

  'copy.done': 'Copied {value}',
  'copy.doneGeneric': 'Copied to clipboard',
  'copy.failed': 'Copy failed',

  'cta.eyebrow': 'Open source',
  'cta.title': 'Missing your favorite tool? Build a port.',
  'cta.bodyHtml':
    'A port is one short script that reads <code class="font-mono text-fg">palette.json</code> and writes the app’s native theme, plus a test. Add yours and open a pull request.',
  'cta.github': 'GitHub repository',
  'cta.guide': 'Read the guide',

  'palette.metaDescription': 'Every Terminal Noir color, by role, for the noir and paper variants.',
  'palette.eyebrow': 'Color architecture',
  'palette.title': 'The palette',
  'palette.description':
    'Luminance-stepped surfaces, one warm accent and four status colors, named by role. Click a swatch to copy its hex.',
  'palette.variant': 'Variant',
  'palette.dark': 'Noir (Dark)',
  'palette.light': 'Paper (Light)',
  'palette.clickToCopy': 'Click swatch to copy hex',
  'palette.group.surface': 'Surfaces',
  'palette.group.text': 'Text',
  'palette.group.accent': 'Accents',
  'palette.ansiTitle': 'Full 16-color ANSI terminal map',
  'palette.copySwatch': 'Copy {role}, {hex}',
  'palette.copyAnsi': 'Copy ANSI {index}, {name}, {hex}',
  'ansi.black': 'black',
  'ansi.red': 'red',
  'ansi.green': 'green',
  'ansi.yellow': 'yellow',
  'ansi.blue': 'blue',
  'ansi.magenta': 'magenta',
  'ansi.cyan': 'cyan',
  'ansi.white': 'white',
  'ansi.bright': 'bright {name}',

  'role.surface.base': 'Windows & editors',
  'role.surface.raised': 'Inputs & widgets',
  'role.surface.elevated': 'Toolbars & cards',
  'role.surface.border': 'Hairlines',
  'role.surface.outline': 'Frames & targets',
  'role.surface.selection': 'Text selection',
  'role.surface.shadow': 'Shadows',
  'role.text.primary': 'Body text',
  'role.text.muted': 'Secondary & comments',
  'role.text.faint': 'Line numbers',
  'role.accent.primary': 'Accent & cursor',
  'role.accent.onPrimary': 'Text on amber',
  'role.accent.success': 'Strings & pass',
  'role.accent.warning': 'Numbers & warn',
  'role.accent.error': 'Errors & diffs',
  'role.accent.info': 'Functions & links',

  'docs.metaDescription': 'How Terminal Noir is built, how to install a port, and how to add one.',
  'docs.eyebrow': 'Engine & pipeline',
  'docs.title': 'How it works',
  'docs.description': "One palette, compiled into each app's native theme format, with tests that catch any drift.",
  'docs.step1Label': '01 / Source',
  'docs.step1Title': 'One palette.json',
  'docs.step1Html':
    'Every color, for noir and paper, lives by role in <code class="rounded bg-elevated px-1 py-0.5 font-mono text-fg">palette/palette.json</code>.',
  'docs.step2Label': '02 / Generation',
  'docs.step2Title': 'Generated ports',
  'docs.step2Html':
    '<code class="rounded bg-elevated px-1 py-0.5 font-mono text-fg">make build</code> runs one small bash and jq script per app, writing its native theme files.',
  'docs.step3Label': '03 / Validation',
  'docs.step3Title': 'Tested against drift',
  'docs.step3Html':
    "bats suites check the palette, each port's color mapping, and that committed ports match a fresh build.",
  'docs.buildTests': '{count} tests: palette, port mappings, build freshness',
  'docs.contributingEyebrow': 'Open source',
  'docs.contributingTitle': 'Contributing',

  'about.metaDescription': 'Where Terminal Noir comes from and the principles behind it.',
  'about.eyebrow': 'About',
  'about.title': 'A theme that started as a website.',
  'about.p1Html':
    'Terminal Noir began as the design tokens of <a class="text-accent underline underline-offset-4" href="https://nandomoreira.dev">nandomoreira.dev</a>: cold near-black surfaces stepped by luminance, an amber accent and an emerald status color. Living with it on the web made the desktop next to it look loud, so the palette moved into the shell, the compositor, the terminal and the editor, one app at a time.',
  'about.p2':
    "The paper variant follows the same roles on warm light tones, taken from the site's light reader theme. Apps that switch with the system get both.",
  'about.principlesEyebrow': 'Principles',
  'about.principlesTitle': 'Three rules',
  'about.rule1Label': '01 / Palette',
  'about.rule1Title': 'One palette',
  'about.rule1':
    'Every color lives in palette.json, named by role. Ports read roles, never raw hex, so a change lands everywhere at once.',
  'about.rule2Label': '02 / Restraint',
  'about.rule2Title': 'One warm note',
  'about.rule2':
    'Surfaces step by luminance, not hue. Amber appears only where the eye should go: the cursor, focus, keywords, the primary action.',
  'about.rule3Label': '03 / Trust',
  'about.rule3Title': 'Tested ports',
  'about.rule3': 'Ports are generated, committed and checked. What you install is what the palette says.',
  'about.creditsEyebrow': 'Standing on',
  'about.creditsTitle': 'Dracula and Catppuccin',
  'about.creditsHtml':
    'Terminal Noir borrows its shape from two projects that made themes a community effort: <a class="text-accent underline underline-offset-4" href="https://draculatheme.com">Dracula</a>, for one confident identity that goes everywhere, and <a class="text-accent underline underline-offset-4" href="https://catppuccin.com">Catppuccin</a>, for treating the palette itself as the product, with named roles and generated ports.',
};

export type UiKey = keyof typeof en;

const ptBr: Record<UiKey, string> = {
  'meta.title': 'Terminal Noir: um tema noir para tudo o que você digita',
  'meta.description':
    'Terminal Noir: superfícies frias quase pretas e um único acento âmbar. Uma paleta, gerada para cada app que você usa.',
  'a11y.skip': 'Pular para o conteúdo',
  'a11y.home': 'Terminal Noir, início',
  'nav.main': 'Principal',
  'nav.footer': 'Rodapé',
  'nav.home': 'Início',
  'nav.about': 'Sobre',
  'nav.ports': 'Ports',
  'nav.palette': 'Paleta',
  'nav.docs': 'Docs',
  'nav.github': 'GitHub',
  'nav.getStarted': 'Começar',
  'nav.language': 'Idioma',
  'theme.group': 'Tema de cores',
  'theme.noir': 'noir',
  'theme.paper': 'paper',
  'footer.textHtml':
    'Licença MIT. Nasceu do design do <a class="hover:text-fg" href="https://nandomoreira.dev">nandomoreira.dev</a>.',

  'hero.badge': 'v{version} — {count} ports, escuro e claro',
  'hero.title': 'Um tema noir para tudo o que você digita.',
  'hero.subtitle':
    'Superfícies frias quase pretas, um único acento âmbar. Uma paleta, gerada para cada app do seu desktop.',
  'hero.browse': 'Ver ports',
  'hero.viewPalette': 'Ver paleta',
  'hero.statMit': 'Licença MIT',
  'hero.statPorts': '{count} ports',
  'hero.statTested': 'Testado contra divergências',

  'terminal.label':
    'Uma janela do Ghostty no Terminal Noir: um prompt de shell e o bat mostrando código Rust destacado',
  'terminal.comment': '// superfícies frias em degraus de luminância',
  'terminal.synced': 'sincronizado com palette.json',

  'ports.eyebrow': 'Ecossistema',
  'ports.title': 'Ports',
  'ports.descriptionHome': 'Ajustado para o shell, o compositor, terminais, editores e ferramentas de linha de comando.',
  'ports.description':
    'Ajustado para o shell, o compositor, terminais, editores e ferramentas de linha de comando. Cada port tem seu passo a passo de instalação.',
  'ports.metaDescription': 'Terminal Noir para o seu shell, compositor, terminal, editor, navegador e ferramentas CLI.',
  'ports.all': 'Todos os {count} ports',
  'ports.searchLabel': 'Buscar ports',
  'ports.searchPlaceholder': 'Buscar entre {count} ports…',
  'ports.count': '{count} apps e contando',
  'ports.noResults': 'Nenhum port corresponde a essa busca.',
  'ports.shownOne': '1 port exibido',
  'ports.shownMany': '{count} ports exibidos',
  'ports.requestBadge': 'pedido',
  'ports.requestTitle': 'Peça um port',
  'ports.requestBody': 'Falta o seu terminal, editor ou ferramenta? Abra uma issue no GitHub.',
  'ports.requestCta': 'Abrir issue',
  'ports.breadcrumb': 'Trilha de navegação',
  'ports.pageTitle': 'Terminal Noir para {name}',
  'ports.source': 'Código',

  'variant.dark': 'escuro',
  'variant.light': 'claro',
  'category.desktop': 'Desktop',
  'category.terminal': 'Terminal',
  'category.editor': 'Editores',
  'category.cli': 'Ferramentas CLI',
  'category.apps': 'Apps',

  'quickstart.eyebrow': 'Início rápido',
  'quickstart.title': 'Instalação',
  'quickstart.descriptionHome': 'Cada port já vem com os arquivos prontos. Copie e pronto.',
  'quickstart.description':
    'Os ports já vêm com os arquivos prontos, então não há nada para compilar. A página de cada port tem o passo a passo completo.',
  'install.tablist': 'Instalar um port',
  'install.fromHtml': 'De {link}, na raiz do repositório:',
  'install.copy': 'Copiar',

  'copy.done': '{value} copiado',
  'copy.doneGeneric': 'Copiado para a área de transferência',
  'copy.failed': 'Não foi possível copiar',

  'cta.eyebrow': 'Código aberto',
  'cta.title': 'Falta sua ferramenta favorita? Crie um port.',
  'cta.bodyHtml':
    'Um port é um script curto que lê o <code class="font-mono text-fg">palette.json</code> e escreve o tema no formato nativo do app, mais um teste. Adicione o seu e abra um pull request.',
  'cta.github': 'Repositório no GitHub',
  'cta.guide': 'Ler o guia',

  'palette.metaDescription': 'Todas as cores do Terminal Noir, por papel, nas variantes noir e paper.',
  'palette.eyebrow': 'Arquitetura de cores',
  'palette.title': 'A paleta',
  'palette.description':
    'Superfícies em degraus de luminância, um acento quente e quatro cores de status, nomeadas por papel. Clique numa cor para copiar o hex.',
  'palette.variant': 'Variante',
  'palette.dark': 'Noir (escuro)',
  'palette.light': 'Paper (claro)',
  'palette.clickToCopy': 'Clique para copiar o hex',
  'palette.group.surface': 'Superfícies',
  'palette.group.text': 'Texto',
  'palette.group.accent': 'Acentos',
  'palette.ansiTitle': 'Mapa ANSI completo de 16 cores',
  'palette.copySwatch': 'Copiar {role}, {hex}',
  'palette.copyAnsi': 'Copiar ANSI {index}, {name}, {hex}',
  'ansi.black': 'preto',
  'ansi.red': 'vermelho',
  'ansi.green': 'verde',
  'ansi.yellow': 'amarelo',
  'ansi.blue': 'azul',
  'ansi.magenta': 'magenta',
  'ansi.cyan': 'ciano',
  'ansi.white': 'branco',
  'ansi.bright': '{name} brilhante',

  'role.surface.base': 'Janelas e editores',
  'role.surface.raised': 'Campos e widgets',
  'role.surface.elevated': 'Barras e cards',
  'role.surface.border': 'Linhas finas',
  'role.surface.outline': 'Molduras e alvos',
  'role.surface.selection': 'Seleção de texto',
  'role.surface.shadow': 'Sombras',
  'role.text.primary': 'Texto principal',
  'role.text.muted': 'Secundário e comentários',
  'role.text.faint': 'Números de linha',
  'role.accent.primary': 'Acento e cursor',
  'role.accent.onPrimary': 'Texto sobre o âmbar',
  'role.accent.success': 'Strings e sucesso',
  'role.accent.warning': 'Números e alertas',
  'role.accent.error': 'Erros e remoções',
  'role.accent.info': 'Funções e links',

  'docs.metaDescription': 'Como o Terminal Noir é construído, como instalar um port e como criar um.',
  'docs.eyebrow': 'Motor e pipeline',
  'docs.title': 'Como funciona',
  'docs.description':
    'Uma paleta, compilada no formato de tema nativo de cada app, com testes que pegam qualquer divergência.',
  'docs.step1Label': '01 / Fonte',
  'docs.step1Title': 'Um palette.json',
  'docs.step1Html':
    'Todas as cores, de noir e paper, ficam por papel no <code class="rounded bg-elevated px-1 py-0.5 font-mono text-fg">palette/palette.json</code>.',
  'docs.step2Label': '02 / Geração',
  'docs.step2Title': 'Ports gerados',
  'docs.step2Html':
    'O <code class="rounded bg-elevated px-1 py-0.5 font-mono text-fg">make build</code> roda um pequeno script em bash e jq por app, que escreve os arquivos de tema nativos.',
  'docs.step3Label': '03 / Validação',
  'docs.step3Title': 'Testado contra divergências',
  'docs.step3Html':
    'Suítes bats conferem a paleta, o mapeamento de cores de cada port e se os ports commitados batem com um build novo.',
  'docs.buildTests': '{count} testes: paleta, mapeamento dos ports, build atualizado',
  'docs.contributingEyebrow': 'Código aberto',
  'docs.contributingTitle': 'Como contribuir',

  'about.metaDescription': 'De onde vem o Terminal Noir e os princípios por trás dele.',
  'about.eyebrow': 'Sobre',
  'about.title': 'Um tema que começou como um site.',
  'about.p1Html':
    'O Terminal Noir nasceu dos design tokens do <a class="text-accent underline underline-offset-4" href="https://nandomoreira.dev">nandomoreira.dev</a>: superfícies frias quase pretas em degraus de luminância, um acento âmbar e uma cor de status esmeralda. Conviver com ele na web fez o desktop ao lado parecer barulhento, então a paleta foi para o shell, o compositor, o terminal e o editor, um app de cada vez.',
  'about.p2':
    'A variante paper segue os mesmos papéis em tons claros e quentes, tirados do tema claro do modo leitura do site. Apps que trocam de tema com o sistema recebem as duas.',
  'about.principlesEyebrow': 'Princípios',
  'about.principlesTitle': 'Três regras',
  'about.rule1Label': '01 / Paleta',
  'about.rule1Title': 'Uma paleta',
  'about.rule1':
    'Todas as cores ficam no palette.json, nomeadas por papel. Os ports leem papéis, nunca hex soltos, então uma mudança chega a todos de uma vez.',
  'about.rule2Label': '02 / Contenção',
  'about.rule2Title': 'Uma nota quente',
  'about.rule2':
    'As superfícies variam em luminância, não em matiz. O âmbar aparece só onde o olhar deve ir: o cursor, o foco, as palavras-chave, a ação principal.',
  'about.rule3Label': '03 / Confiança',
  'about.rule3Title': 'Ports testados',
  'about.rule3': 'Os ports são gerados, commitados e conferidos. O que você instala é o que a paleta diz.',
  'about.creditsEyebrow': 'Inspirações',
  'about.creditsTitle': 'Dracula e Catppuccin',
  'about.creditsHtml':
    'O Terminal Noir pega emprestada a forma de dois projetos que fizeram dos temas um esforço da comunidade: o <a class="text-accent underline underline-offset-4" href="https://draculatheme.com">Dracula</a>, por uma identidade segura que vai a todo lugar, e o <a class="text-accent underline underline-offset-4" href="https://catppuccin.com">Catppuccin</a>, por tratar a própria paleta como o produto, com papéis nomeados e ports gerados.',
};

export const ui: Record<Locale, Record<UiKey, string>> = { en, 'pt-br': ptBr };

export type Translate = (key: UiKey, vars?: Record<string, string | number>) => string;

export function useTranslations(locale: Locale): Translate {
  return (key, vars = {}) =>
    ui[locale][key].replace(/\{(\w+)\}/g, (match, name: string) => (name in vars ? String(vars[name]) : match));
}
