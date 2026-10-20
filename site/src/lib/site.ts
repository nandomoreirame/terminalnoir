import type { UiKey } from '../i18n/ui';

// The theme's repository on GitHub.
export const REPO_URL = 'https://github.com/nandomoreirame/terminalnoir';

export const NAV: readonly { href: string; key: UiKey }[] = [
  { href: '/', key: 'nav.home' },
  { href: '/about', key: 'nav.about' },
  { href: '/ports', key: 'nav.ports' },
  { href: '/palette', key: 'nav.palette' },
  { href: '/docs', key: 'nav.docs' },
];

// Both arguments are site paths in the same locale (e.g. /pt-br/ports).
export function isActive(href: string, pathname: string, home = '/'): boolean {
  const path = pathname.replace(/\/$/, '') || '/';
  return href === home ? path === home : path === href || path.startsWith(`${href}/`);
}
