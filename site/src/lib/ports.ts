import registry from '../../../ports.json';
import { DEFAULT_LOCALE, type Locale } from '../i18n/locales';

export type Category = keyof typeof registry.categories;

export interface Port {
  slug: string;
  name: string;
  category: Category;
  variants: string[];
  homepage: string;
  featured: boolean;
  readme: string;
  description: string;
  install: string | undefined;
  icon: string;
  screenshot: ImageMetadata | undefined;
}

// assets/screenshots/<slug>.png, as imported image assets (src, width, height).
const screenshots = import.meta.glob<{ default: ImageMetadata }>('../../../assets/screenshots/*.png', {
  eager: true,
});

function screenshotFor(slug: string): ImageMetadata | undefined {
  return Object.entries(screenshots).find(([path]) => path.endsWith(`/screenshots/${slug}.png`))?.[1].default;
}

// Lucide icons per port, in the spirit of the generic glyphs of the Stitch design.
const ICONS: Record<string, string> = {
  noctalia: 'lucide:panels-top-left',
  niri: 'lucide:columns-3',
  gtk: 'lucide:app-window',
  ghostty: 'lucide:terminal',
  p10k: 'lucide:square-chevron-right',
  vscode: 'lucide:code',
  obsidian: 'lucide:notebook-pen',
  bat: 'lucide:file-code-2',
  btop: 'lucide:activity',
  fzf: 'lucide:list-filter',
  chrome: 'lucide:globe',
};

// README.md is English; README.<locale>.md holds each translation.
const readmes = import.meta.glob<string>('../../../ports/*/README*.md', {
  query: '?raw',
  import: 'default',
  eager: true,
});

function readmeFor(slug: string, locale: Locale): string {
  const file = locale === DEFAULT_LOCALE ? 'README.md' : `README.${locale}.md`;
  const entry = Object.entries(readmes).find(([path]) => path.endsWith(`/ports/${slug}/${file}`));
  if (!entry) throw new Error(`ports/${slug}/${file} not found`);
  return entry[1];
}

// First paragraph after the title, as plain text.
export function portDescription(readme: string): string {
  const body = readme.replace(/^#[^\n]*\n+/, '');
  const paragraph = body.split(/\n\s*\n/)[0] ?? '';
  return paragraph
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/(\*\*|\*|__|_)(.+?)\1/g, '$2')
    .replace(/\s*\n\s*/g, ' ')
    .trim();
}

// First ```sh block of a README: the port's install command.
export function installSnippet(readme: string): string | undefined {
  return readme.match(/```(?:sh|bash|zsh)\n([\s\S]*?)\n```/)?.[1];
}

const cache = new Map<Locale, Port[]>();

export function getPorts(locale: Locale = DEFAULT_LOCALE): Port[] {
  let ports = cache.get(locale);
  if (!ports) {
    ports = registry.ports.map(p => {
      const readme = readmeFor(p.slug, locale);
      return {
        ...p,
        category: p.category as Category,
        readme,
        description: portDescription(readme),
        install: installSnippet(readme),
        icon: ICONS[p.slug] ?? 'lucide:palette',
        screenshot: screenshotFor(p.slug),
      };
    });
    cache.set(locale, ports);
  }
  return ports;
}

export function getPort(slug: string, locale: Locale = DEFAULT_LOCALE): Port | undefined {
  return getPorts(locale).find(p => p.slug === slug);
}

export function portsByCategory(locale: Locale = DEFAULT_LOCALE): { id: Category; label: string; ports: Port[] }[] {
  const ports = getPorts(locale);
  return (Object.entries(registry.categories) as [Category, string][])
    .map(([id, label]) => ({ id, label, ports: ports.filter(p => p.category === id) }))
    .filter(group => group.ports.length > 0);
}
