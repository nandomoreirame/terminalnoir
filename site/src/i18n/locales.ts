export const LOCALES = ['en', 'pt-br'] as const;
export type Locale = (typeof LOCALES)[number];
export const DEFAULT_LOCALE: Locale = 'en';

export const LOCALE_LABELS: Record<Locale, { short: string; name: string }> = {
  en: { short: 'EN', name: 'English' },
  'pt-br': { short: 'PT', name: 'Português (Brasil)' },
};

export function toLocale(value: string | undefined): Locale {
  return (LOCALES as readonly string[]).includes(value ?? '') ? (value as Locale) : DEFAULT_LOCALE;
}

export function htmlLang(locale: Locale): string {
  return locale === 'pt-br' ? 'pt-BR' : locale;
}

// '/ports' -> '/pt-br/ports'; English stays unprefixed.
export function localizePath(path: string, locale: Locale): string {
  if (locale === DEFAULT_LOCALE) return path;
  const [pathname, hash] = path.split('#');
  const localized = pathname === '/' ? `/${locale}` : `/${locale}${pathname}`;
  return hash === undefined ? localized : `${localized}#${hash}`;
}

// The same page in another locale.
export function switchLocalePath(pathname: string, target: Locale): string {
  const prefix = LOCALES.find(l => l !== DEFAULT_LOCALE && (pathname === `/${l}` || pathname.startsWith(`/${l}/`)));
  const base = prefix ? pathname.slice(prefix.length + 1) || '/' : pathname;
  const clean = base.length > 1 ? base.replace(/\/$/, '') : base;
  return localizePath(clean, target);
}
