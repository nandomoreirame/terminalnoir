import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import { getPort } from '../lib/ports';
import PortCard from './PortCard.astro';

async function render(slug: string) {
  const container = await AstroContainer.create();
  return container.renderToString(PortCard, { props: { port: getPort(slug) } });
}

describe('PortCard', () => {
  it('shows the logo instead of the screenshot', async () => {
    const html = await render('ghostty');

    expect(html).not.toContain('<img');
    expect(html).toMatch(/<svg[^>]*data-icon="simple-icons:ghostty"/);
  });

  it('links to the port page with its name, variants and category', async () => {
    const html = await render('ghostty');

    expect(html).toMatch(/<a[^>]*href="\/ports\/ghostty"/);
    expect(html).toContain('Ghostty');
    expect(html).toContain('dark · light');
    expect(html).toContain('Terminal');
  });
});
