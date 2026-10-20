import { describe, expect, it } from 'vitest';
import { renderMarkdown } from './markdown';

describe('renderMarkdown', () => {
  it('renders headings and paragraphs', async () => {
    const html = await renderMarkdown('## Install\n\nCopy the file.');

    expect(html).toContain('<h2');
    expect(html).toContain('<p>Copy the file.</p>');
  });

  it('highlights fenced code with the Terminal Noir VS Code theme', async () => {
    const html = await renderMarkdown('```sh\nmkdir -p ~/.config\n```');

    expect(html).toContain('class="shiki');
    expect(html).toContain('background-color:#0B0B0C');
  });

  it('drops the leading h1, since pages render their own title', async () => {
    const html = await renderMarkdown('# Terminal Noir for X\n\nBody.', { dropTitle: true });

    expect(html).not.toContain('<h1');
    expect(html).toContain('Body.');
  });

  it('opens external links in a new tab with rel noopener', async () => {
    const html = await renderMarkdown('[bat](https://github.com/sharkdp/bat)');

    expect(html).toContain('href="https://github.com/sharkdp/bat"');
    expect(html).toContain('rel="noopener noreferrer"');
  });
});
