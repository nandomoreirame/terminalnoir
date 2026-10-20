import tailwindcss from '@tailwindcss/vite';
import icon from 'astro-icon';
import { defineConfig } from 'astro/config';

// Static site. Palette, ports registry and port READMEs are read from the repo
// root at build time, so the site can never drift from the theme itself.
export default defineConfig({
  site: 'https://terminalnoir.web.app',
  output: 'static',
  integrations: [icon()],
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'pt-br'],
    routing: { prefixDefaultLocale: false },
  },
  trailingSlash: 'never',
  build: {
    format: 'directory',
    inlineStylesheets: 'always',
  },
  vite: {
    plugins: [tailwindcss()],
    server: { fs: { allow: ['..'] } },
  },
});
