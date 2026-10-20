import { Marked, type Tokens } from 'marked';
import { createHighlighter, type ThemeRegistrationRaw } from 'shiki';
import vscodeTheme from '../../../ports/vscode/themes/terminal-noir-color-theme.json';

// Markdown comes only from files in this repo (port READMEs, CONTRIBUTING.md),
// so raw HTML in it is trusted. Code blocks use the theme's own VS Code port.
const theme = { ...vscodeTheme, name: 'terminal-noir' } as unknown as ThemeRegistrationRaw;
const LANGS = ['sh', 'bash', 'zsh', 'json', 'toml', 'css', 'ini', 'kdl', 'js', 'ts'] as const;

const highlighter = await createHighlighter({ themes: [theme], langs: [...LANGS] });

function highlight(code: string, lang: string | undefined): string {
  const known = (LANGS as readonly string[]).includes(lang ?? '');
  return highlighter.codeToHtml(code, { lang: known ? (lang as string) : 'text', theme: 'terminal-noir' });
}

const marked = new Marked({
  gfm: true,
  renderer: {
    code({ text, lang }: Tokens.Code) {
      return highlight(text, lang?.split(/\s/)[0]);
    },
    link({ href, title, tokens }: Tokens.Link) {
      const label = this.parser.parseInline(tokens);
      const external = /^https?:\/\//.test(href);
      const attrs = [`href="${href}"`];
      if (title) attrs.push(`title="${title}"`);
      if (external) attrs.push('target="_blank"', 'rel="noopener noreferrer"');
      return `<a ${attrs.join(' ')}>${label}</a>`;
    },
  },
});

// Image lines with a relative path (README screenshots) resolve on GitHub but
// not on the site, which shows each port's screenshot on its own.
const RELATIVE_IMAGE_LINE = /^!\[[^\]]*\]\((?![a-z]+:)[^)]+\)\s*$/gm;

export async function renderMarkdown(source: string, options: { dropTitle?: boolean } = {}): Promise<string> {
  const tokens = marked.lexer(source.replace(RELATIVE_IMAGE_LINE, ''));
  const body =
    options.dropTitle && tokens[0]?.type === 'heading' && (tokens[0] as Tokens.Heading).depth === 1
      ? Object.assign(tokens.slice(1), { links: tokens.links })
      : tokens;
  return marked.parser(body);
}
