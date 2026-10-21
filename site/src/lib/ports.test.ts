import { existsSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { getPort, getPorts, installSnippet, portDescription, portsByCategory } from './ports';

describe('getPorts', () => {
  it('returns every registered port with its README', () => {
    const ports = getPorts();

    expect(ports.length).toBeGreaterThanOrEqual(11);
    for (const port of ports) {
      expect(port.readme, port.slug).toMatch(/^# Terminal Noir for /);
    }
  });

  it('gives every port a prose description for its card', () => {
    for (const port of getPorts()) {
      expect(port.description, port.slug).not.toMatch(/^#/);
      expect(port.description.length, port.slug).toBeGreaterThan(10);
    }
  });
});

describe('getPort', () => {
  it('finds a port by slug', () => {
    expect(getPort('ghostty')?.variants).toEqual(['dark', 'light']);
  });

  it('returns undefined for an unknown slug', () => {
    expect(getPort('nope')).toBeUndefined();
  });
});

describe('portDescription', () => {
  it('takes the first paragraph after the title', () => {
    const readme = '# Terminal Noir for X\n\nA short *description*\nover two lines.\n\n## Install\n\nsteps';

    expect(portDescription(readme)).toBe('A short description over two lines.');
  });

  it('strips links and inline code to plain text', () => {
    const readme = '# T\n\n[Ghostty](https://ghostty.org) themes for `dark`.\n';

    expect(portDescription(readme)).toBe('Ghostty themes for dark.');
  });
});

describe('portsByCategory', () => {
  it('groups ports in registry category order', () => {
    const groups = portsByCategory();

    expect(groups[0].label).toBe('Desktop');
    expect(groups.flatMap(g => g.ports).length).toBe(getPorts().length);
  });
});

describe('installSnippet', () => {
  it('returns the first shell block of a README', () => {
    const readme = '# T\n\nIntro.\n\n```sh\nmkdir -p ~/x\ncp a ~/x/\n```\n\n```toml\n[a]\n```\n';

    expect(installSnippet(readme)).toBe('mkdir -p ~/x\ncp a ~/x/');
  });

  it('returns undefined when there is no shell block', () => {
    expect(installSnippet('# T\n\n1. Open Settings.\n')).toBeUndefined();
  });

  it('gives the quickstart ports a real install command', () => {
    for (const slug of ['ghostty', 'vscode', 'bat', 'fzf']) {
      expect(getPort(slug)?.install, slug).toBeTruthy();
    }
  });
});

describe('port icons', () => {
  it('maps every port to an icon set glyph or a logo file in src/icons', () => {
    for (const port of getPorts()) {
      if (/^(lucide|simple-icons):/.test(port.icon)) continue;
      expect(existsSync(new URL(`../icons/${port.icon}.svg`, import.meta.url)), port.slug).toBe(true);
    }
  });

  it('uses the project logo when simple-icons has none', () => {
    expect(getPort('noctalia')?.icon).toBe('noctalia');
    expect(getPort('btop')?.icon).toBe('btop');
    expect(getPort('shiki')?.icon).toBe('shiki');
    expect(getPort('bat')?.icon).toBe('simple-icons:bat');
  });

  it('uses the brand logo when simple-icons has one', () => {
    expect(getPort('ghostty')?.icon).toBe('simple-icons:ghostty');
    expect(getPort('fish')?.icon).toBe('simple-icons:fishshell');
    expect(getPort('vscode')?.icon).toBe('simple-icons:visualstudiocode');
    expect(getPort('fzf')?.icon).toMatch(/^lucide:/);
  });

  it('gives every port its own glyph, never the fallback', () => {
    for (const port of getPorts()) {
      expect(port.icon, port.slug).not.toBe('lucide:palette');
    }
  });
});

describe('localized ports', () => {
  it('reads the pt-br README, description and install for each port', () => {
    for (const port of getPorts('pt-br')) {
      expect(port.readme, port.slug).toMatch(/^# Terminal Noir para /);
      expect(port.description, port.slug).not.toMatch(/^#/);
    }
    expect(getPort('ghostty', 'pt-br')?.description).toContain('Temas para o Ghostty');
  });

  it('keeps install commands identical across locales', () => {
    for (const port of getPorts()) {
      expect(getPort(port.slug, 'pt-br')?.install, port.slug).toBe(port.install);
    }
  });
});

describe('port screenshots', () => {
  it('gives every port its screenshot', () => {
    for (const port of getPorts()) {
      expect(port.screenshot?.src, port.slug).toBeTruthy();
      expect(port.screenshot?.width, port.slug).toBeGreaterThan(0);
    }
  });
});
