import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import { describe, expect, it } from 'vitest';
import { getPort } from '../lib/ports';
import Lightbox from './Lightbox.astro';

async function render() {
  const container = await AstroContainer.create();
  const image = getPort('ghostty')?.screenshot;
  return container.renderToString(Lightbox, {
    props: { id: 'shot-ghostty', image, alt: 'Terminal Noir for Ghostty', openLabel: 'Open', closeLabel: 'Close' },
  });
}

describe('Lightbox', () => {
  it('opens a popover from a labelled button around the preview', async () => {
    const html = await render();

    expect(html).toMatch(/<button[^>]*popovertarget="shot-ghostty"[^>]*>/);
    expect(html).toMatch(/<button[^>]*aria-label="Open"/);
    expect(html).toMatch(/<div[^>]*id="shot-ghostty"[^>]*popover/);
  });

  it('shows the full image with its alt text and a close button', async () => {
    const html = await render();
    const dialog = html.slice(html.indexOf('id="shot-ghostty"'));

    expect(dialog).toContain('alt="Terminal Noir for Ghostty"');
    expect(dialog).toMatch(/popovertargetaction="hide"/);
    expect(dialog).toMatch(/aria-label="Close"/);
  });
});
