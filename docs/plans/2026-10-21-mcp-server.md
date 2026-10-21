# Plan: mcp-server

> **Spec:** docs/specs/mcp-server/SPEC.md

**Goal:** Serve a read-only Terminal Noir MCP at `https://terminalnoir.web.app/api/mcp` from Firebase Functions, ship a Claude Code plugin (skill `apply` + the MCP connection) from this repo, and add a bilingual `/mcp` page that explains both.
**Architecture:** A new `functions/` package (Node 22, TypeScript) answers from a catalog JSON generated from `palette/`, `ports/` and `assets/wallpapers/`. One `McpServer` and one stateless Streamable HTTP transport per request, behind a per-IP limiter, exported as the 2nd gen function `terminalnoirMcp` in the `terminalnoir` codebase; Hosting rewrites `/api/mcp` to it. The plugin lives in `plugins/terminal-noir/`, listed by `.claude-plugin/marketplace.json` at the repo root. The site reads the tool metadata straight from `functions/src/tools-meta.ts`, so the page and the server cannot list different tools.
**Tech Stack:** firebase-functions 7.4, @modelcontextprotocol/sdk 1.32.1, zod 4, TypeScript 5, Vitest 4, Astro 7, bats, Claude Code plugins.
**Total Tasks:** 15
**Estimated Complexity:** large

---

## Notes for the implementer

- The MCP code below was prototyped on 2026-10-21 with the exact SDK version: tools over `InMemoryTransport`, invalid input becoming `isError`, and `initialize` plus `tools/list` over a real POST answering JSON with `Cache-Control: no-store`. The catalog builder was run against the repo: 12 ports, raw URLs with spaces answer 200, wallpapers read as 3840x2160.
- Run bats only as `env -i HOME="$HOME" PATH="/usr/bin:/bin" TERM=dumb bash $HOME/.local/share/mise/installs/node/22.22.3/lib/node_modules/bats/bin/bats tests` (plain `bats` and `make test` do not work on this machine).
- Node tools by path, never bare: `./node_modules/.bin/vitest`, `./node_modules/.bin/tsc` (bare names hit a dead mise shim).
- **Every outward action waits for Fernando's explicit ok:** deploys, IAM changes, the Artifact Registry policy. Silence or a task notification is never consent.
- Deploy with `--only functions:terminalnoir`, never bare `--only functions`: the project `nandomoreira-dev` may hold functions of other codebases, and a bare deploy offers to delete them.

## Order and dependencies

| Batch | Tasks | Depends on |
|---|---|---|
| A, server | 1, 2, 3, 4, 5, 6 | in order |
| B, wiring | 7, 9 | 6 |
| C, first deploy | 8 | 7, Fernando |
| D, plugin | 10, 11 | none (can run beside A) |
| E, site and docs | 12, 13, 14 | 1 (tool metadata), 10 (commands) |
| F, launch | 15 | all |

---

### Task 1: Functions package and the tool metadata

**Requirement:** REQ-012 (shared metadata), REQ-002 to REQ-006 (names)
**Files:**
- Create: `functions/package.json`, `functions/tsconfig.json`, `functions/vitest.config.ts`, `functions/.gitignore`
- Create: `functions/src/tools-meta.ts`
- Create: `functions/src/tools-meta.test.ts`

**Team:**
- Track: backend
- Implementer: backend-engineer (skills: typescript-backend)
- Reviewers: type-safety-reviewer, test-reviewer

**Step 1: Write the failing test**
`functions/src/tools-meta.test.ts`:
```ts
import { describe, expect, it } from 'vitest';
import { MCP_TOOLS, toolMeta } from './tools-meta';

describe('tool metadata', () => {
  it('lists the five read-only tools, in the order the docs show them', () => {
    expect(MCP_TOOLS.map(tool => tool.name)).toEqual([
      'get_palette',
      'list_ports',
      'get_port',
      'check_contrast',
      'get_wallpapers',
    ]);
  });

  it('gives every tool a title and a description an agent can choose by', () => {
    for (const tool of MCP_TOOLS) {
      expect(tool.title.length, tool.name).toBeGreaterThan(3);
      expect(tool.description.length, tool.name).toBeGreaterThan(40);
    }
  });

  it('returns the title and description for one tool', () => {
    expect(toolMeta('get_port')).toEqual({
      title: MCP_TOOLS[2].title,
      description: MCP_TOOLS[2].description,
    });
  });
});
```

**Step 2: Run test to verify it fails**
Run: `cd functions && npm install && ./node_modules/.bin/vitest run`
Expected: FAIL (`Failed to load url ./tools-meta`).

**Step 3: Write minimal implementation**
`functions/package.json`:
```json
{
  "name": "terminalnoir-functions",
  "private": true,
  "type": "module",
  "main": "lib/index.js",
  "engines": { "node": "22" },
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "build:catalog": "node scripts/build-catalog.mjs",
    "test": "vitest run",
    "typecheck": "tsc -p tsconfig.json --noEmit"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "1.32.1",
    "firebase-admin": "13.6.0",
    "firebase-functions": "7.4.0",
    "zod": "4.6.7"
  },
  "devDependencies": {
    "@types/node": "22.19.0",
    "typescript": "5.9.3",
    "vitest": "4.0.18"
  }
}
```
(Before installing, check each pinned version exists with `npm view <pkg>@<version> version`; if one does not, pin the latest of the same major and note it. `firebase-admin` is a peer of `firebase-functions`, unused by our code.)

`functions/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "lib",
    "rootDir": "src",
    "strict": true,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["src/**/*.test.ts"]
}
```
`functions/vitest.config.ts`:
```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({ test: { include: ['src/**/*.test.ts', 'scripts/**/*.test.ts'] } });
```
`functions/.gitignore`:
```
node_modules/
lib/
```
`functions/src/tools-meta.ts` (no imports, so the site can import it too):
```ts
/**
 * Names, titles and descriptions of the MCP tools (docs/specs/mcp-server).
 * The server registers from this list and the site's /mcp page renders it, so
 * the two cannot list different tools. Keep it free of imports: the site
 * imports this file directly.
 */
export const MCP_TOOLS = [
  {
    name: 'get_palette',
    title: 'Get the palette',
    description:
      'Colors of Terminal Noir by role (surface, text, accent) plus the 16 ANSI colors, for the noir (dark) or paper (light) variant, or both.',
  },
  {
    name: 'list_ports',
    title: 'List the ports',
    description:
      'Every app Terminal Noir supports, with category, variants and page URL. Filter by category or by variant.',
  },
  {
    name: 'get_port',
    title: 'Get one port',
    description:
      'Everything needed to install the theme in one app: the README, the install command and each file with its raw GitHub URL.',
  },
  {
    name: 'check_contrast',
    title: 'Check contrast',
    description:
      'WCAG 2.1 contrast ratio between two #RRGGBB colors, and whether it passes 4.5:1 for text and 3:1 for graphics.',
  },
  {
    name: 'get_wallpapers',
    title: 'Get the wallpapers',
    description:
      'The noir (night) and paper (day) city wallpapers, with raw URL and size in pixels.',
  },
] as const;

export type McpToolName = (typeof MCP_TOOLS)[number]['name'];

export const toolMeta = (name: McpToolName): { title: string; description: string } => {
  const tool = MCP_TOOLS.find(entry => entry.name === name);
  if (!tool) throw new Error(`unknown tool ${name}`);
  return { title: tool.title, description: tool.description };
};
```

**Step 4: Run test to verify it passes**
Run: `cd functions && ./node_modules/.bin/vitest run && npm audit --omit=dev`
Expected: 3 tests pass; `npm audit` with no high or critical (Iron Law 11). Report anything it finds.

**Step 5: Commit**
Run: `/git commit` (include `functions/package-lock.json`)

---

### Task 2: Catalog generator

**Requirement:** REQ-001
**Depends on:** Task 1
**Files:**
- Create: `functions/scripts/build-catalog.mjs`
- Create: `functions/scripts/build-catalog.test.ts`
- Create: `functions/src/catalog.generated.json` (generated)

**Team:**
- Track: backend
- Implementer: backend-engineer (skills: typescript-backend)
- Reviewers: business-logic-reviewer, test-reviewer

**Step 1: Write the failing test**
`functions/scripts/build-catalog.test.ts`:
```ts
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { buildCatalog, serialise } from './build-catalog.mjs';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const catalog = buildCatalog(ROOT);

describe('catalog', () => {
  it('carries both variants of the palette under their public names', () => {
    expect(Object.keys(catalog.palette)).toEqual(['noir', 'paper']);
    expect(catalog.palette.noir.accent.primary).toBe('#F5A623');
    expect(catalog.palette.paper.surface.base).toBe('#FBFAF7');
  });

  it('lists every registered port with its install snippet and raw file URLs', () => {
    const registry = JSON.parse(readFileSync(`${ROOT}/ports.json`, 'utf8'));
    expect(catalog.ports.map((p: { slug: string }) => p.slug)).toEqual(
      registry.ports.map((p: { slug: string }) => p.slug),
    );
    const noctalia = catalog.ports.find((p: { slug: string }) => p.slug === 'noctalia');
    expect(noctalia.variants).toEqual(['noir', 'paper']);
    expect(noctalia.page).toBe('https://terminalnoir.web.app/ports/noctalia');
    expect(noctalia.install).toContain('~/.config/noctalia/palettes');
    expect(noctalia.files).toEqual([
      {
        path: 'ports/noctalia/Terminal Noir.json',
        url: 'https://raw.githubusercontent.com/nandomoreirame/terminalnoir/main/ports/noctalia/Terminal%20Noir.json',
      },
    ]);
  });

  it('never lists a README as a port file', () => {
    for (const port of catalog.ports) {
      expect(port.files.some((f: { path: string }) => /README/.test(f.path)), port.slug).toBe(false);
    }
  });

  it('reads the wallpaper size from the PNG header', () => {
    expect(catalog.wallpapers).toEqual([
      expect.objectContaining({ variant: 'noir', width: 3840, height: 2160 }),
      expect.objectContaining({ variant: 'paper', width: 3840, height: 2160 }),
    ]);
  });

  it('is committed in sync with the repo (run npm run build:catalog after any palette or port change)', () => {
    const committed = readFileSync(new URL('../src/catalog.generated.json', import.meta.url), 'utf8');
    expect(committed).toBe(serialise(catalog));
  });
});
```

**Step 2: Run test to verify it fails**
Run: `cd functions && ./node_modules/.bin/vitest run scripts`
Expected: FAIL (`Failed to load url ./build-catalog.mjs`).

**Step 3: Write minimal implementation**
`functions/scripts/build-catalog.mjs` (prototyped on 2026-10-21):
```js
// Builds the catalog the MCP server answers from (docs/specs/mcp-server, REQ-001).
// The function deploys only functions/, so everything it needs from the repo is
// copied here at build time. Run after any change to palette/, ports/ or the wallpapers.
import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO = 'nandomoreirame/terminalnoir';
const RAW = `https://raw.githubusercontent.com/${REPO}/main`;
const SITE = 'https://terminalnoir.web.app';
const VARIANTS = { noir: 'dark', paper: 'light' };

const rawUrl = path => `${RAW}/${path.split('/').map(encodeURIComponent).join('/')}`;
const readJson = (root, path) => JSON.parse(readFileSync(join(root, path), 'utf8'));
const installSnippet = readme => readme.match(/```(?:sh|bash|zsh)\n([\s\S]*?)\n```/)?.[1] ?? null;

/** Width and height from a PNG's IHDR chunk. */
const pngSize = bytes => ({ width: bytes.readUInt32BE(16), height: bytes.readUInt32BE(20) });

const filesUnder = dir =>
  readdirSync(dir).flatMap(entry => {
    const path = join(dir, entry);
    return statSync(path).isDirectory() ? filesUnder(path) : [path];
  });

export const buildCatalog = root => {
  const palette = readJson(root, 'palette/palette.json');
  const syntax = readJson(root, 'palette/syntax.json');
  const registry = readJson(root, 'ports.json');
  const ports = registry.ports.map(port => {
    const dir = join(root, 'ports', port.slug);
    const readme = readFileSync(join(dir, 'README.md'), 'utf8');
    const files = filesUnder(dir)
      .map(path => relative(root, path))
      .filter(path => !/\/README(\.[a-z-]+)?\.md$/.test(path))
      .sort()
      .map(path => ({ path, url: rawUrl(path) }));
    return {
      slug: port.slug,
      name: port.name,
      category: port.category,
      variants: port.variants.map(v => (v === 'dark' ? 'noir' : 'paper')),
      homepage: port.homepage,
      page: `${SITE}/ports/${port.slug}`,
      install: installSnippet(readme),
      readme,
      files,
    };
  });
  const wallpapers = Object.keys(VARIANTS).map(variant => {
    const path = `assets/wallpapers/${variant}.png`;
    return { variant, url: rawUrl(path), ...pngSize(readFileSync(join(root, path))) };
  });
  return {
    name: palette.name,
    version: palette.version,
    homepage: SITE,
    palette: Object.fromEntries(Object.entries(VARIANTS).map(([v, key]) => [v, palette.variants[key]])),
    syntax: syntax.tokens,
    categories: registry.categories,
    ports,
    wallpapers,
  };
};

export const serialise = catalog => `${JSON.stringify(catalog, null, 2)}\n`;

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const root = fileURLToPath(new URL('../..', import.meta.url));
  writeFileSync(fileURLToPath(new URL('../src/catalog.generated.json', import.meta.url)), serialise(buildCatalog(root)));
}
```
Then: `cd functions && npm run build:catalog`. If TypeScript complains about importing `.mjs` in the test, add `"allowJs": true` to a `functions/tsconfig.test.json` or a `// @ts-expect-error` on the import line; Vitest itself runs it.

**Step 4: Run test to verify it passes**
Run: `cd functions && ./node_modules/.bin/vitest run`
Expected: all tests pass.

**Step 5: Commit**
Run: `/git commit`

---

### Task 3: Queries over the catalog

**Requirement:** REQ-002, REQ-003, REQ-004, REQ-005, REQ-006
**Depends on:** Task 2
**Files:**
- Create: `functions/src/catalog.ts`
- Create: `functions/src/catalog.test.ts`

**Team:**
- Track: backend
- Implementer: backend-engineer (skills: typescript-backend)
- Reviewers: business-logic-reviewer, type-safety-reviewer, test-reviewer

**Step 1: Write the failing test**
```ts
import { describe, expect, it } from 'vitest';
import { checkContrast, getPalette, getPort, getWallpapers, listPorts } from './catalog';

describe('catalog queries', () => {
  it('returns one variant or both', () => {
    expect(Object.keys(getPalette())).toEqual(['noir', 'paper']);
    expect(Object.keys(getPalette('paper'))).toEqual(['paper']);
    expect(getPalette('noir').noir.ansi.normal.red).toMatch(/^#[0-9A-F]{6}$/);
  });

  it('lists ports without the heavy fields, filtered by category and variant', () => {
    const all = listPorts();
    expect(all.length).toBeGreaterThanOrEqual(12);
    expect(Object.keys(all[0]!).sort()).toEqual(['category', 'name', 'page', 'slug', 'variants']);
    expect(listPorts({ category: 'terminal' }).every(p => p.category === 'terminal')).toBe(true);
    expect(listPorts({ variant: 'paper' }).map(p => p.slug).sort()).toEqual(['ghostty', 'noctalia', 'shiki']);
  });

  it('returns one port in full, and undefined for an unknown slug', () => {
    const ghostty = getPort('ghostty');
    expect(ghostty?.install).toContain('ghostty');
    expect(ghostty?.files.length).toBe(2);
    expect(getPort('nope')).toBeUndefined();
  });

  it('measures contrast with the WCAG 2.1 formula', () => {
    expect(checkContrast('#000000', '#FFFFFF')).toEqual({ ratio: 21, text: true, graphics: true });
    expect(checkContrast('#777777', '#ffffff')).toEqual({ ratio: 4.48, text: false, graphics: true });
    expect(checkContrast('#F5A623', '#0B0B0C').ratio).toBe(9.71);
  });

  it('returns both wallpapers', () => {
    expect(getWallpapers().map(w => w.variant)).toEqual(['noir', 'paper']);
  });
});
```

**Step 2: Run test to verify it fails**
Expected: FAIL (`Failed to load url ./catalog`).

**Step 3: Write minimal implementation**
`functions/src/catalog.ts`:
```ts
import catalog from './catalog.generated.json' with { type: 'json' };

export type Variant = 'noir' | 'paper';

type Port = (typeof catalog.ports)[number];
export type PortSummary = Pick<Port, 'slug' | 'name' | 'category' | 'variants' | 'page'>;

export const getPalette = (variant?: Variant) =>
  variant ? { [variant]: catalog.palette[variant] } : catalog.palette;

export const listPorts = (filter: { category?: string; variant?: Variant } = {}): PortSummary[] =>
  catalog.ports
    .filter(port => !filter.category || port.category === filter.category)
    .filter(port => !filter.variant || port.variants.includes(filter.variant))
    .map(({ slug, name, category, variants, page }) => ({ slug, name, category, variants, page }));

export const getPort = (slug: string): Port | undefined => catalog.ports.find(port => port.slug === slug);

export const getWallpapers = () => catalog.wallpapers;

export const catalogInfo = () => ({ name: catalog.name, version: catalog.version, homepage: catalog.homepage });

// WCAG 2.1 relative luminance, the same math as scripts/lib/contrast.jq.
const channel = (c: number) => {
  const s = c / 255;
  return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
};

const luminance = (hex: string) => {
  const [r, g, b] = [1, 3, 5].map(i => channel(Number.parseInt(hex.slice(i, i + 2), 16)));
  return 0.2126 * r! + 0.7152 * g! + 0.0722 * b!;
};

export const checkContrast = (foreground: string, background: string) => {
  const [hi, lo] = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  const ratio = Math.round(((hi! + 0.05) / (lo! + 0.05)) * 100) / 100;
  return { ratio, text: ratio >= 4.5, graphics: ratio >= 3 };
};
```
(If `with { type: 'json' }` fails under NodeNext, use `assert` or read the JSON with `createRequire`; keep the import static so the deploy bundle carries it.)

**Step 4: Run test to verify it passes**
Run: `cd functions && ./node_modules/.bin/vitest run && npm run typecheck`
Expected: PASS, no type errors.

**Step 5: Commit**
Run: `/git commit`

---

### Task 4: MCP server with the five tools

**Requirement:** REQ-002, REQ-003, REQ-004, REQ-005, REQ-006
**Depends on:** Task 3
**Files:**
- Create: `functions/src/server.ts`
- Create: `functions/src/server.test.ts`

**Team:**
- Track: backend
- Implementer: backend-engineer (skills: typescript-backend)
- Reviewers: business-logic-reviewer, security-reviewer, test-reviewer

**Step 1: Write the failing test**
```ts
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { InMemoryTransport } from '@modelcontextprotocol/sdk/inMemory.js';
import { beforeEach, describe, expect, it } from 'vitest';
import { createMcpServer } from './server';
import { MCP_TOOLS } from './tools-meta';

let client: Client;

beforeEach(async () => {
  const [serverSide, clientSide] = InMemoryTransport.createLinkedPair();
  client = new Client({ name: 'test', version: '1.0.0' });
  await Promise.all([createMcpServer().connect(serverSide), client.connect(clientSide)]);
});

const call = (name: string, args: Record<string, unknown> = {}) => client.callTool({ name, arguments: args });

describe('Terminal Noir MCP', () => {
  it('registers exactly the tools in the shared metadata', async () => {
    const { tools } = await client.listTools();
    expect(tools.map(t => t.name)).toEqual(MCP_TOOLS.map(t => t.name));
  });

  it('answers get_palette for one variant', async () => {
    const result = await call('get_palette', { variant: 'paper' });
    expect(result.structuredContent).toMatchObject({ palette: { paper: { surface: { base: '#FBFAF7' } } } });
  });

  it('filters list_ports by variant', async () => {
    const result = await call('list_ports', { variant: 'paper' });
    expect((result.structuredContent as { total: number }).total).toBe(3);
  });

  it('returns a port, and a tool error naming list_ports for an unknown slug', async () => {
    expect((await call('get_port', { slug: 'ghostty' })).structuredContent).toMatchObject({ slug: 'ghostty' });
    const missing = await call('get_port', { slug: 'emacs' });
    expect(missing.isError).toBe(true);
    expect(JSON.stringify(missing.content)).toContain('list_ports');
  });

  it('checks contrast and rejects anything that is not #RRGGBB', async () => {
    expect((await call('check_contrast', { foreground: '#000000', background: '#FFFFFF' })).structuredContent)
      .toMatchObject({ ratio: 21, text: true });
    expect((await call('check_contrast', { foreground: 'red', background: '#FFFFFF' })).isError).toBe(true);
  });

  it('lists both wallpapers', async () => {
    const result = await call('get_wallpapers');
    expect((result.structuredContent as { wallpapers: unknown[] }).wallpapers).toHaveLength(2);
  });
});
```

**Step 2: Run test to verify it fails**
Expected: FAIL (`Failed to load url ./server`).

**Step 3: Write minimal implementation**
`functions/src/server.ts`:
```ts
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { catalogInfo, checkContrast, getPalette, getPort, getWallpapers, listPorts } from './catalog';
import { toolMeta } from './tools-meta';

const HEX = z.string().regex(/^#[0-9A-Fa-f]{6}$/, 'a #RRGGBB color');
const VARIANT = z.enum(['noir', 'paper']);

/** Text for readers, structured content for parsers; the protocol needs a record. */
const answer = (payload: Record<string, unknown>) => ({
  content: [{ type: 'text' as const, text: JSON.stringify(payload, null, 2) }],
  structuredContent: payload,
});

/**
 * A NEW server per request: in stateless mode a shared instance collides
 * request IDs between concurrent clients (same design as nandomoreira.dev).
 */
export const createMcpServer = (): McpServer => {
  const info = catalogInfo();
  const server = new McpServer({ name: 'terminal-noir', version: info.version });

  server.registerTool(
    'get_palette',
    { ...toolMeta('get_palette'), inputSchema: { variant: VARIANT.optional().describe('noir (dark) or paper (light); both when omitted') } },
    async ({ variant }) => answer({ ...info, palette: getPalette(variant) }),
  );

  server.registerTool(
    'list_ports',
    {
      ...toolMeta('list_ports'),
      inputSchema: {
        category: z.string().min(1).optional().describe('desktop, terminal, editor, cli or apps'),
        variant: VARIANT.optional(),
      },
    },
    async filter => {
      const ports = listPorts(filter);
      return answer({ ports, total: ports.length });
    },
  );

  server.registerTool(
    'get_port',
    { ...toolMeta('get_port'), inputSchema: { slug: z.string().min(1).describe('A slug from list_ports') } },
    async ({ slug }) => {
      const port = getPort(slug);
      if (!port) {
        return {
          content: [{ type: 'text' as const, text: `No port "${slug}". Call list_ports for the valid slugs.` }],
          isError: true,
        };
      }
      return answer(port);
    },
  );

  server.registerTool(
    'check_contrast',
    { ...toolMeta('check_contrast'), inputSchema: { foreground: HEX, background: HEX } },
    async ({ foreground, background }) => answer({ foreground, background, ...checkContrast(foreground, background) }),
  );

  server.registerTool('get_wallpapers', toolMeta('get_wallpapers'), async () => answer({ wallpapers: getWallpapers() }));

  return server;
};
```

**Step 4: Run test to verify it passes**
Expected: 6 tests pass.

**Step 5: Commit**
Run: `/git commit`

---

### Task 5: HTTP handler and rate limiter

**Requirement:** REQ-007
**Depends on:** Task 4
**Files:**
- Create: `functions/src/rate-limit.ts`, `functions/src/rate-limit.test.ts`
- Create: `functions/src/http.ts`, `functions/src/http.test.ts`

**Team:**
- Track: backend
- Implementer: backend-engineer (skills: typescript-backend)
- Reviewers: security-reviewer, business-logic-reviewer, test-reviewer

**Step 1: Write the failing tests**
`functions/src/rate-limit.test.ts`:
```ts
import { describe, expect, it } from 'vitest';
import { clientIp, createRateLimiter } from './rate-limit';

describe('rate limiter', () => {
  it('allows the limit, refuses the next, and resets after the window', () => {
    let now = 0;
    const allow = createRateLimiter({ limit: 2, windowMs: 1000, now: () => now });
    expect([allow('a'), allow('a'), allow('a')]).toEqual([true, true, false]);
    expect(allow('b')).toBe(true);
    now = 1001;
    expect(allow('a')).toBe(true);
  });

  it('keys by the first x-forwarded-for address, falling back to the socket', () => {
    expect(clientIp({ headers: { 'x-forwarded-for': '203.0.113.7, 10.0.0.1' }, ip: '10.0.0.1' })).toBe('203.0.113.7');
    expect(clientIp({ headers: {}, ip: '198.51.100.2' })).toBe('198.51.100.2');
    expect(clientIp({ headers: {} })).toBe('unknown');
  });
});
```
`functions/src/http.test.ts` (prototyped on 2026-10-21):
```ts
import { createServer } from 'node:http';
import type { AddressInfo } from 'node:net';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createMcpHandler } from './http';

let url = '';
const handler = createMcpHandler({ limit: 3, windowMs: 60_000 });
const server = createServer(async (req, res) => {
  let raw = '';
  for await (const chunk of req) raw += chunk;
  Object.assign(req, { body: raw ? JSON.parse(raw) : undefined, ip: '127.0.0.1' });
  await handler(req as never, res);
});

beforeAll(async () => {
  await new Promise<void>(resolve => server.listen(0, '127.0.0.1', resolve));
  url = `http://127.0.0.1:${(server.address() as AddressInfo).port}/`;
});
afterAll(() => {
  server.close();
});

const rpc = (body: unknown, ip = '192.0.2.1') =>
  fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json', accept: 'application/json, text/event-stream', 'x-forwarded-for': ip },
    body: JSON.stringify(body),
  });

describe('MCP over HTTP', () => {
  it('answers initialize and tools/list in plain JSON, never cached', async () => {
    const init = await rpc({
      jsonrpc: '2.0', id: 1, method: 'initialize',
      params: { protocolVersion: '2025-11-25', capabilities: {}, clientInfo: { name: 't', version: '1' } },
    });
    expect(init.status).toBe(200);
    expect(init.headers.get('cache-control')).toBe('no-store');
    expect((await init.json()).result.serverInfo.name).toBe('terminal-noir');
    const list = await rpc({ jsonrpc: '2.0', id: 2, method: 'tools/list' });
    expect((await list.json()).result.tools).toHaveLength(5);
  });

  it('answers 429 with a JSON-RPC error once an IP passes the limit', async () => {
    const body = { jsonrpc: '2.0', id: 3, method: 'tools/list' };
    for (let i = 0; i < 3; i += 1) expect((await rpc(body, '192.0.2.99')).status).toBe(200);
    const refused = await rpc(body, '192.0.2.99');
    expect(refused.status).toBe(429);
    expect((await refused.json()).error.code).toBe(-32000);
  });
});
```

**Step 2: Run tests to verify they fail**
Expected: FAIL (modules missing).

**Step 3: Write minimal implementation**
`functions/src/rate-limit.ts`:
```ts
/**
 * Fixed-window limiter, per function instance (REQ-007). Approximate by design:
 * with maxInstances 2 the real ceiling is twice the limit, which is enough for
 * a public, read-only catalog. Old keys are dropped when their window ends.
 */
export const createRateLimiter = ({ limit, windowMs, now = Date.now }: { limit: number; windowMs: number; now?: () => number }) => {
  const windows = new Map<string, { start: number; count: number }>();
  return (key: string): boolean => {
    const t = now();
    for (const [k, w] of windows) if (t - w.start > windowMs) windows.delete(k);
    const w = windows.get(key);
    if (!w) {
      windows.set(key, { start: t, count: 1 });
      return true;
    }
    w.count += 1;
    return w.count <= limit;
  };
};

/** Firebase Hosting forwards the client address first in x-forwarded-for. */
export const clientIp = (req: { headers: Record<string, string | string[] | undefined>; ip?: string }): string => {
  const forwarded = req.headers['x-forwarded-for'];
  const first = (Array.isArray(forwarded) ? forwarded[0] : forwarded)?.split(',')[0]?.trim();
  return first || req.ip || 'unknown';
};
```
`functions/src/http.ts`:
```ts
import type { IncomingMessage, ServerResponse } from 'node:http';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { clientIp, createRateLimiter } from './rate-limit';
import { createMcpServer } from './server';

type Req = IncomingMessage & { body?: unknown; ip?: string; headers: Record<string, string | string[] | undefined> };

const jsonError = (res: ServerResponse, status: number, code: number, message: string) => {
  res.statusCode = status;
  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify({ jsonrpc: '2.0', error: { code, message }, id: null }));
};

export const createMcpHandler = ({ limit = 60, windowMs = 60_000 } = {}) => {
  const allow = createRateLimiter({ limit, windowMs });

  return async (req: Req, res: ServerResponse): Promise<void> => {
    // Hosting would otherwise be free to cache a JSON-RPC answer.
    res.setHeader('Cache-Control', 'no-store');
    if (!allow(clientIp(req))) return jsonError(res, 429, -32000, 'Too many requests, try again in a minute');

    const server = createMcpServer();
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    res.on('close', () => {
      void transport.close();
      void server.close();
    });
    try {
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch {
      // Never a stack trace or a path in the answer.
      if (!res.headersSent) jsonError(res, 500, -32603, 'Internal server error');
    }
  };
};
```

**Step 4: Run tests to verify they pass**
Expected: all functions tests pass.

**Step 5: Commit**
Run: `/git commit`

---

### Task 6: The Firebase function

**Requirement:** REQ-007, REQ-008
**Depends on:** Task 5
**Files:**
- Create: `functions/src/index.ts`, `functions/src/index.test.ts`

**Team:**
- Track: backend
- Implementer: backend-engineer (skills: typescript-backend)
- Reviewers: security-reviewer, consequences-reviewer

**Step 1: Write the failing test**
```ts
import { describe, expect, it } from 'vitest';
import { terminalnoirMcp } from './index';

describe('terminalnoirMcp', () => {
  it('is a public 2nd gen HTTPS function in us-central1 with tight limits', () => {
    const endpoint = (terminalnoirMcp as unknown as { __endpoint: Record<string, unknown> }).__endpoint;
    expect(endpoint.region).toEqual(['us-central1']);
    expect(endpoint.platform).toBe('gcfv2');
    expect(endpoint.maxInstances).toBe(2);
    expect(endpoint.timeoutSeconds).toBe(15);
    expect(endpoint.availableMemoryMb).toBe(256);
    expect(endpoint.httpsTrigger).toMatchObject({ invoker: ['public'] });
  });
});
```
(If a field name differs in firebase-functions 7.4, print `__endpoint` once and adjust the assertion to the real shape; the values stay.)

**Step 2: Run test to verify it fails**
Expected: FAIL (`Failed to load url ./index`).

**Step 3: Write minimal implementation**
```ts
import { onRequest } from 'firebase-functions/v2/https';
import { createMcpHandler } from './http';

const handle = createMcpHandler();

/**
 * Terminal Noir MCP (docs/specs/mcp-server). Hosting rewrites
 * https://terminalnoir.web.app/api/mcp here. Read-only and public, so the
 * limits are about cost, not access: two instances, 15 s, 256 MiB.
 */
export const terminalnoirMcp = onRequest(
  { region: 'us-central1', memory: '256MiB', timeoutSeconds: 15, maxInstances: 2, concurrency: 40, invoker: 'public' },
  (req, res) => handle(req as never, res),
);
```

**Step 4: Run test to verify it passes**
Run: `cd functions && ./node_modules/.bin/vitest run && npm run build`
Expected: PASS; `lib/index.js` built.

**Step 5: Commit**
Run: `/git commit`

---

### Task 7: firebase.json codebase and rewrite

**Requirement:** REQ-008
**Depends on:** Task 6
**Files:**
- Modify: `firebase.json`
- Create: `tests/firebase.bats`

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: cloud-cli, bash-linux)
- Reviewers: security-reviewer, consequences-reviewer

**Step 1: Write the failing test**
```bash
#!/usr/bin/env bats

# Firebase wiring for the MCP: one codebase of our own, and /api/mcp on the site's domain.

load test_helper

F="$PROJECT_ROOT/firebase.json"

@test "firebase: functions live in the terminalnoir codebase, built before deploy" {
    jq -e '.functions | length == 1' "$F"
    jq -e '.functions[0] | .source == "functions" and .codebase == "terminalnoir" and .runtime == "nodejs22"' "$F"
    jq -e '.functions[0].predeploy | any(test("run build"))' "$F"
}

@test "firebase: /api/mcp rewrites to terminalnoirMcp in us-central1" {
    jq -e '.hosting.rewrites | any(.source == "/api/mcp" and .function.functionId == "terminalnoirMcp" and .function.region == "us-central1")' "$F"
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL (`.functions` is null).

**Step 3: Write minimal implementation**
Add to `firebase.json` (keep everything already there):
```json
  "functions": [
    {
      "source": "functions",
      "codebase": "terminalnoir",
      "runtime": "nodejs22",
      "ignore": ["node_modules", ".git", "*.log", "src/**/*.test.ts", "scripts/**/*.test.ts"],
      "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
    }
  ]
```
and inside `"hosting"`:
```json
    "rewrites": [
      { "source": "/api/mcp", "function": { "functionId": "terminalnoirMcp", "region": "us-central1" } }
    ],
```

**Step 4: Run test to verify it passes**
Expected: 2 ok; full bats suite green.

**Step 5: Commit**
Run: `/git commit`

---

### Task 8: First deploy, IAM and verification script

**Requirement:** REQ-008, REQ-009
**Depends on:** Task 7. **Outward:** every command that changes the cloud waits for Fernando's ok.
**Files:**
- Create: `scripts/verify-mcp`
- Modify: `Makefile:2` (`SCRIPTS` gains `scripts/verify-mcp`)

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: cloud-cli, bash-linux)
- Reviewers: security-reviewer

**Step 1: The script (shellcheck is its gate)**
`scripts/verify-mcp`:
```bash
#!/usr/bin/env bash
# verify-mcp — Prove an MCP endpoint answers: initialize, tools/list with the
# five tools, one tool call, and no caching. Ends with MCP VERIFIED.
# Usage: scripts/verify-mcp [URL]   (default: https://terminalnoir.web.app/api/mcp)
set -euo pipefail

URL="${1:-https://terminalnoir.web.app/api/mcp}"

rpc() {
    curl -sS -D "$HEADERS" -H 'content-type: application/json' \
        -H 'accept: application/json, text/event-stream' --data "$1" "$URL"
}

HEADERS="$(mktemp)"
trap 'rm -f "$HEADERS"' EXIT

rpc '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"verify-mcp","version":"1"}}}' \
    | jq -e '.result.serverInfo.name == "terminal-noir"' >/dev/null || { echo "FAIL: initialize"; exit 1; }
grep -qi '^cache-control: no-store' "$HEADERS" || { echo "FAIL: response is cacheable"; exit 1; }
rpc '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
    | jq -e '[.result.tools[].name] == ["get_palette","list_ports","get_port","check_contrast","get_wallpapers"]' >/dev/null \
    || { echo "FAIL: tools/list"; exit 1; }
rpc '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"check_contrast","arguments":{"foreground":"#000000","background":"#FFFFFF"}}}' \
    | jq -e '.result.structuredContent.ratio == 21' >/dev/null || { echo "FAIL: tools/call"; exit 1; }
echo "MCP VERIFIED: $URL"
```
`chmod +x scripts/verify-mcp`; `make lint` must stay silent.

**Step 2: Local proof with the emulators**
Run: `cd functions && npm run build && cd .. && npx --yes firebase-tools@15.34.0 emulators:exec --only functions,hosting --project nandomoreira-dev "scripts/verify-mcp http://127.0.0.1:5000/api/mcp"`
Expected: `MCP VERIFIED: http://127.0.0.1:5000/api/mcp` (the Hosting emulator applies the rewrite, so this also proves `firebase.json`).

**Step 3: First deploy (Fernando's ok, his account)**
1. `npx --yes firebase-tools@15.34.0 functions:artifacts:setpolicy --location us-central1 --days 7 --project nandomoreira-dev` (without it a non-interactive deploy fails on the cleanup policy).
2. `npx --yes firebase-tools@15.34.0 deploy --only functions:terminalnoir,hosting:terminalnoir --project nandomoreira-dev` (enables the APIs on first run).
3. `scripts/verify-mcp` against production. Expected: `MCP VERIFIED: https://terminalnoir.web.app/api/mcp`.

**Step 4: Let CI deploy functions (Fernando's ok)**
Grant the deploy identity what a functions deploy needs, then confirm with the next CI run (Task 9):
```bash
SA=gh-terminalnoir-deploy@nandomoreira-dev.iam.gserviceaccount.com
for role in roles/cloudfunctions.developer roles/run.viewer roles/artifactregistry.reader roles/cloudbuild.builds.viewer; do
  gcloud projects add-iam-policy-binding nandomoreira-dev --member="serviceAccount:$SA" --role="$role" --condition=None
done
RUNTIME="$(gcloud projects describe nandomoreira-dev --format='value(projectNumber)')-compute@developer.gserviceaccount.com"
gcloud iam service-accounts add-iam-policy-binding "$RUNTIME" --member="serviceAccount:$SA" --role=roles/iam.serviceAccountUser --project nandomoreira-dev
```
If the CI deploy still fails on a permission, add only the role its error names and record it in `STATE.md`.

**Step 5: Commit**
Run: `/git commit` (the script and the Makefile line)

---

### Task 9: CI tests and deploys the function

**Requirement:** REQ-009
**Depends on:** Task 7 (Task 8 Step 4 before the first push that runs it)
**Files:**
- Modify: `.github/workflows/deploy.yml`
- Create: `tests/workflows.bats`

**Team:**
- Track: infra
- Implementer: infra-engineer (skills: cloud-cli, bash-linux)
- Reviewers: security-reviewer, consequences-reviewer

**Step 1: Write the failing test**
```bash
#!/usr/bin/env bats

load test_helper

WF="$PROJECT_ROOT/.github/workflows/deploy.yml"

@test "deploy: functions are installed and tested before any deploy" {
    grep -q 'working-directory: functions' "$WF"
    grep -q 'npm test' "$WF"
}

@test "deploy: hosting and only our functions codebase ship together" {
    grep -q -- '--only hosting:terminalnoir,functions:terminalnoir' "$WF"
    if grep -n -- '--only functions\b' "$WF" | grep -v 'functions:terminalnoir'; then return 1; fi
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL.

**Step 3: Write minimal implementation**
In `.github/workflows/deploy.yml`, after "Check, test and build" (cache path gains `functions/package-lock.json`):
```yaml
      - name: Install functions
        working-directory: functions
        run: npm ci

      - name: Test and build functions
        working-directory: functions
        run: npm test && npm run build
```
and the deploy step becomes:
```yaml
      - name: Deploy to Firebase Hosting and Functions
        run: npx --yes firebase-tools@15.34.0 deploy --only hosting:terminalnoir,functions:terminalnoir --project nandomoreira-dev --non-interactive
```
Update the file's header comment to mention the function.

**Step 4: Run test to verify it passes**
Expected: `tests/workflows.bats` ok.

**Step 5: Commit**
Run: `/git commit`

---

### Task 10: Plugin marketplace and plugin manifest

**Requirement:** REQ-010
**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/terminal-noir/.claude-plugin/plugin.json`
- Create: `plugins/terminal-noir/.mcp.json`
- Create: `tests/plugin.bats`

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: consequences-reviewer

**Step 1: Write the failing test**
```bash
#!/usr/bin/env bats

# The repo is a Claude Code plugin marketplace with one plugin: the apply skill plus the MCP.

load test_helper

M="$PROJECT_ROOT/.claude-plugin/marketplace.json"
P="$PROJECT_ROOT/plugins/terminal-noir"

@test "plugin: the marketplace lists terminal-noir from ./plugins/terminal-noir" {
    jq -e '.name == "terminal-noir" and .owner.name == "Fernando Moreira"' "$M"
    jq -e '.plugins == [.plugins[0]] and .plugins[0].name == "terminal-noir" and .plugins[0].source == "./plugins/terminal-noir"' "$M"
}

@test "plugin: manifest name matches the entry, version matches the palette" {
    jq -e '.name == "terminal-noir"' "$P/.claude-plugin/plugin.json"
    [ "$(jq -r .version "$P/.claude-plugin/plugin.json")" = "$(jq -r .version "$PALETTE")" ]
}

@test "plugin: it connects the public HTTP MCP" {
    jq -e '.mcpServers["terminal-noir"] == {"type": "http", "url": "https://terminalnoir.web.app/api/mcp"}' "$P/.mcp.json"
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL (files missing).

**Step 3: Write minimal implementation**
`.claude-plugin/marketplace.json`:
```json
{
  "name": "terminal-noir",
  "description": "Terminal Noir for AI agents: a skill that applies the theme to your apps and an MCP server with the palette and every port.",
  "owner": { "name": "Fernando Moreira" },
  "plugins": [
    {
      "name": "terminal-noir",
      "source": "./plugins/terminal-noir",
      "description": "Apply Terminal Noir (noir or paper) to the apps on your machine."
    }
  ]
}
```
`plugins/terminal-noir/.claude-plugin/plugin.json`:
```json
{
  "name": "terminal-noir",
  "displayName": "Terminal Noir",
  "version": "0.1.0-beta",
  "description": "Apply the Terminal Noir theme to your apps, with the palette and ports served by the Terminal Noir MCP.",
  "author": { "name": "Fernando Moreira", "url": "https://github.com/nandomoreirame" },
  "homepage": "https://terminalnoir.web.app/mcp",
  "repository": "https://github.com/nandomoreirame/terminalnoir",
  "license": "MIT",
  "keywords": ["theme", "colors", "terminal", "linux", "accessibility"]
}
```
`plugins/terminal-noir/.mcp.json`:
```json
{
  "mcpServers": {
    "terminal-noir": { "type": "http", "url": "https://terminalnoir.web.app/api/mcp" }
  }
}
```
The release flow must bump `plugin.json` with the palette; the test enforces it.

**Step 4: Run test to verify it passes**
Run: the bats suite, then `claude plugin validate .` and `claude plugin validate ./plugins/terminal-noir`.
Expected: 3 ok; both validations end in `Validation passed` (warnings about the skill missing are fine until Task 11).

**Step 5: Commit**
Run: `/git commit`

---

### Task 11: The apply skill

**Requirement:** REQ-011
**Depends on:** Task 10
**Files:**
- Create: `plugins/terminal-noir/skills/apply/SKILL.md`
- Modify: `tests/plugin.bats`

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: security-reviewer (the skill tells an agent to write files)

**Step 1: Write the failing test**
Append to `tests/plugin.bats`:
```bash
@test "skill: apply is described, prefers the MCP, falls back to GitHub, backs up and confirms" {
    local s="$P/skills/apply/SKILL.md"
    head -1 "$s" | grep -qx -- '---'
    grep -q '^name: apply$' "$s"
    grep -q '^description: ' "$s"
    local tool
    for tool in get_palette list_ports get_port get_wallpapers; do grep -q "$tool" "$s" || { echo "no $tool"; return 1; }; done
    grep -q 'raw.githubusercontent.com/nandomoreirame/terminalnoir/main/ports.json' "$s"
    grep -qi 'backup' "$s"
    grep -qi 'never use sudo' "$s"
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL (file missing).

**Step 3: Write minimal implementation**
`plugins/terminal-noir/skills/apply/SKILL.md`:
````markdown
---
name: apply
description: Apply the Terminal Noir theme (noir dark or paper light) to the apps on this machine, such as Ghostty, Noctalia, niri, VS Code, Cursor, bat, btop, fzf, Powerlevel10k, Obsidian or a website's Shiki. Use when the user asks to install, apply, switch or remove Terminal Noir, or to match their apps to its colors.
---

# Apply Terminal Noir

Terminal Noir is one palette generated into every app: cold near-black surfaces, one amber accent, an emerald status color, and a light variant called paper. Every text color meets WCAG AA.

## 1. Find the source

Prefer the `terminal-noir` MCP tools (this plugin connects them):

- `list_ports` (filter by `variant: "paper"` when the user wants the light theme)
- `get_port` with a slug, for the README, the install command and each file's raw URL
- `get_palette` for hex values by role, `get_wallpapers` for the two wallpapers, `check_contrast` before suggesting any color of your own

Without the MCP, read the same data from GitHub: `https://raw.githubusercontent.com/nandomoreirame/terminalnoir/main/ports.json` lists the ports, and each port's files live under `ports/<slug>/` next to a `README.md` with the install steps.

## 2. Plan before touching anything

1. Detect which supported apps are installed (`command -v ghostty`, `~/.config/<app>` existing, `code --list-extensions`, and so on). Only plan for apps that are present, unless the user names one.
2. Pick the variant: ask when the user did not say. Only some ports have paper; `list_ports` with `variant: "paper"` says which, and you tell the user which apps will stay noir.
3. Show the plan: for each app, the files you will write and the command you will run, taken from the port's README. Wait for the user's ok.

## 3. Apply safely

- Backup first: copy every file you would replace to `<file>.terminal-noir.bak` (keep an existing backup, never overwrite it).
- Download each file from its raw URL into the path the README gives; create directories as needed.
- Follow the README's activation step (a config line, a reload, a theme picker). Edit only the line the README names; do not rewrite a user's whole config.
- Never use sudo and never write outside the user's home directory. If a port needs a system path, explain and let the user run it.
- After each app, say what changed and how to undo it (restore the `.terminal-noir.bak`).

## 4. Switch or remove

- Switching variant: apply the other variant's files for the ports that have both; leave the rest as they are and say so.
- Removing: restore each `.terminal-noir.bak` and undo the activation line.

Project, previews and every port: https://terminalnoir.web.app
````

**Step 4: Run test to verify it passes**
Run: the bats suite, `claude plugin validate ./plugins/terminal-noir`, then `claude plugin validate .`.
Expected: ok; `Validation passed`.

**Step 5: Commit**
Run: `/git commit`

---

### Task 12: Site data for the /mcp page

**Requirement:** REQ-012
**Depends on:** Task 1, Task 10
**Files:**
- Create: `site/src/lib/mcp.ts`, `site/src/lib/mcp.test.ts`
- Modify: `site/src/lib/site.ts:6-12` (`NAV` gains `/mcp`)
- Modify: `site/src/lib/site.test.ts` (if it pins the nav)
- Modify: `site/src/i18n/ui.ts` (keys in `en` and `ptBr`)

**Team:**
- Track: frontend
- Implementer: frontend-engineer (skills: frontend-design)
- Reviewers: type-safety-reviewer, test-reviewer

**Step 1: Write the failing test**
`site/src/lib/mcp.test.ts`:
```ts
import { describe, expect, it } from 'vitest';
import { MCP_TOOLS } from '../../../functions/src/tools-meta';
import { ui } from '../i18n/ui';
import { MCP_ENDPOINT, PLUGIN_COMMANDS, mcpClients } from './mcp';
import { NAV } from './site';

describe('/mcp data', () => {
  it('points at the public endpoint on the site domain', () => {
    expect(MCP_ENDPOINT).toBe('https://terminalnoir.web.app/api/mcp');
  });

  it('gives the two plugin commands', () => {
    expect(PLUGIN_COMMANDS).toEqual([
      '/plugin marketplace add nandomoreirame/terminalnoir',
      '/plugin install terminal-noir@terminal-noir',
    ]);
  });

  it('explains five clients, each with the endpoint in its snippet', () => {
    const clients = mcpClients(MCP_ENDPOINT);
    expect(clients.map(c => c.id)).toEqual(['claudeCode', 'claude', 'chatgpt', 'cursor', 'any']);
    for (const client of clients) expect(client.code, client.id).toContain(MCP_ENDPOINT);
  });

  it('has a translated line for every tool, in both locales', () => {
    for (const locale of ['en', 'pt-br'] as const) {
      for (const tool of MCP_TOOLS) expect(ui[locale][`mcp.tool.${tool.name}`], `${locale} ${tool.name}`).toBeTruthy();
    }
  });

  it('is in the main nav', () => {
    expect(NAV.map(item => item.href)).toContain('/mcp');
  });
});
```

**Step 2: Run test to verify it fails**
Run: `cd site && npx vitest run src/lib/mcp.test.ts`
Expected: FAIL (`Failed to load url ./mcp`).

**Step 3: Write minimal implementation**
`site/src/lib/mcp.ts`:
```ts
/** The /mcp page's data (docs/specs/mcp-server, REQ-012). Snippets are code, so they are not translated. */
export const MCP_ENDPOINT = 'https://terminalnoir.web.app/api/mcp';

export const PLUGIN_COMMANDS = [
  '/plugin marketplace add nandomoreirame/terminalnoir',
  '/plugin install terminal-noir@terminal-noir',
] as const;

export type ClientId = 'claudeCode' | 'claude' | 'chatgpt' | 'cursor' | 'any';

export const mcpClients = (endpoint: string): { id: ClientId; name: string; code: string }[] => [
  { id: 'claudeCode', name: 'Claude Code', code: `claude mcp add --transport http terminal-noir ${endpoint}` },
  { id: 'claude', name: 'Claude', code: endpoint },
  { id: 'chatgpt', name: 'ChatGPT', code: endpoint },
  {
    id: 'cursor',
    name: 'Cursor',
    code: JSON.stringify({ mcpServers: { 'terminal-noir': { url: endpoint } } }, null, 2),
  },
  { id: 'any', name: 'MCP', code: endpoint },
];
```
`site/src/lib/site.ts`: add `{ href: '/mcp', key: 'nav.mcp' }` after `/docs`.
`site/src/i18n/ui.ts`, in `en`:
```ts
  'nav.mcp': 'MCP',
  'mcp.metaDescription': 'Use Terminal Noir from an AI agent: the MCP server, the Claude Code plugin and what each tool answers.',
  'mcp.eyebrow': 'For AI agents',
  'mcp.title': 'Let your agent apply the theme.',
  'mcp.description': 'Connect the Terminal Noir MCP, or install the Claude Code plugin, and ask your agent to theme your apps. Read-only, no account, no key.',
  'mcp.endpointLabel': 'MCP endpoint',
  'mcp.endpointNote': 'Streamable HTTP, read-only.',
  'mcp.copy': 'Copy',
  'mcp.pluginEyebrow': 'Claude Code',
  'mcp.pluginTitle': 'The plugin',
  'mcp.pluginDescription': 'Two commands install the apply skill and connect the MCP. Then just ask.',
  'mcp.examplesTitle': 'Try asking',
  'mcp.example1': 'Apply Terminal Noir to my Ghostty and Noctalia.',
  'mcp.example2': 'Switch my apps to the paper variant.',
  'mcp.example3': 'Is #3192AA readable on the paper background?',
  'mcp.clientsEyebrow': 'Any client',
  'mcp.clientsTitle': 'Connect the MCP',
  'mcp.client.claudeCode': 'In a terminal, add the server:',
  'mcp.client.claude': 'In Settings, Connectors, add a custom connector with this URL:',
  'mcp.client.chatgpt': 'In Settings, Apps and connectors, enable developer mode and create a connector with this URL:',
  'mcp.client.cursor': 'Add this to ~/.cursor/mcp.json:',
  'mcp.client.any': 'Register a Streamable HTTP server with this URL:',
  'mcp.toolsEyebrow': 'Tools',
  'mcp.toolsTitle': 'What the agent can ask',
  'mcp.tool.get_palette': 'The colors by role and the 16 ANSI colors, for noir, paper or both.',
  'mcp.tool.list_ports': 'Every supported app, filtered by category or variant.',
  'mcp.tool.get_port': 'How to install one app: the README, the command and each file.',
  'mcp.tool.check_contrast': 'The WCAG ratio of two colors and whether it passes AA.',
  'mcp.tool.get_wallpapers': 'The night and day city wallpapers.',
```
and in `ptBr` (same keys):
```ts
  'nav.mcp': 'MCP',
  'mcp.metaDescription': 'Use o Terminal Noir a partir de um agente de IA: o servidor MCP, o plugin do Claude Code e o que cada tool responde.',
  'mcp.eyebrow': 'Para agentes de IA',
  'mcp.title': 'Deixe o seu agente aplicar o tema.',
  'mcp.description': 'Conecte o MCP do Terminal Noir, ou instale o plugin do Claude Code, e peça para o seu agente aplicar o tema nos seus apps. Só leitura, sem conta e sem chave.',
  'mcp.endpointLabel': 'Endpoint MCP',
  'mcp.endpointNote': 'Streamable HTTP, só leitura.',
  'mcp.copy': 'Copiar',
  'mcp.pluginEyebrow': 'Claude Code',
  'mcp.pluginTitle': 'O plugin',
  'mcp.pluginDescription': 'Dois comandos instalam a skill apply e conectam o MCP. Depois é só pedir.',
  'mcp.examplesTitle': 'Experimente pedir',
  'mcp.example1': 'Aplique o Terminal Noir no meu Ghostty e no Noctalia.',
  'mcp.example2': 'Troque os meus apps para a variante paper.',
  'mcp.example3': 'O #3192AA dá pra ler sobre o fundo paper?',
  'mcp.clientsEyebrow': 'Qualquer cliente',
  'mcp.clientsTitle': 'Conecte o MCP',
  'mcp.client.claudeCode': 'No terminal, adicione o servidor:',
  'mcp.client.claude': 'Em Configurações, Conectores, adicione um conector personalizado com este endereço:',
  'mcp.client.chatgpt': 'Em Configurações, Apps e conectores, ative o modo desenvolvedor e crie um conector com este endereço:',
  'mcp.client.cursor': 'Adicione isto ao ~/.cursor/mcp.json:',
  'mcp.client.any': 'Cadastre um servidor Streamable HTTP com este endereço:',
  'mcp.toolsEyebrow': 'Tools',
  'mcp.toolsTitle': 'O que o agente pode perguntar',
  'mcp.tool.get_palette': 'As cores por papel e as 16 cores ANSI, de noir, paper ou das duas.',
  'mcp.tool.list_ports': 'Todos os apps suportados, com filtro por categoria ou variante.',
  'mcp.tool.get_port': 'Como instalar em um app: o README, o comando e cada arquivo.',
  'mcp.tool.check_contrast': 'A razão WCAG entre duas cores e se passa no AA.',
  'mcp.tool.get_wallpapers': 'Os papéis de parede da cidade, de noite e de dia.',
```
If `site.test.ts` pins the nav list, add `/mcp` there too.

**Step 4: Run test to verify it passes**
Run: `cd site && npx vitest run`
Expected: all site tests pass (including the existing i18n parity tests).

**Step 5: Commit**
Run: `/git commit`

---

### Task 13: The /mcp page, in English and Portuguese

**Requirement:** REQ-012
**Depends on:** Task 12
**Files:**
- Create: `site/src/views/Mcp.astro`
- Create: `site/src/pages/mcp.astro`, `site/src/pages/pt-br/mcp.astro`

**Team:**
- Track: frontend
- Implementer: frontend-engineer (skills: frontend-design)
- Reviewers: accessibility-guardrails, test-reviewer

**Step 1: Write the failing check**
The page is verified on the build output (the site has no page-render tests). Write the check first:
Run: `cd site && npm run build && for p in dist/mcp/index.html dist/pt-br/mcp/index.html; do grep -c 'https://terminalnoir.web.app/api/mcp' "$p"; for t in get_palette list_ports get_port check_contrast get_wallpapers; do grep -q "$t" "$p" || echo "missing $t in $p"; done; done`
Expected now: FAIL (`dist/mcp/index.html: No such file`).

**Step 2: Write the pages**
`site/src/pages/mcp.astro`:
```astro
---
import Mcp from '../views/Mcp.astro';
---

<Mcp />
```
`site/src/pages/pt-br/mcp.astro`:
```astro
---
import Mcp from '../../views/Mcp.astro';
---

<Mcp />
```
`site/src/views/Mcp.astro`:
```astro
---
import { Icon } from 'astro-icon/components';
import { MCP_TOOLS } from '../../../functions/src/tools-meta';
import CopyStatus from '../components/CopyStatus.astro';
import Section from '../components/Section.astro';
import SectionHeader from '../components/SectionHeader.astro';
import { getI18n } from '../i18n/context';
import Layout from '../layouts/Layout.astro';
import { MCP_ENDPOINT, PLUGIN_COMMANDS, mcpClients } from '../lib/mcp';

const { t } = getI18n(Astro.currentLocale);
const clients = mcpClients(MCP_ENDPOINT);
const examples = [1, 2, 3] as const;
const code = 'block overflow-x-auto rounded border border-hairline bg-base px-3 py-2 font-mono text-xs text-fg whitespace-pre';
const copyButton =
  'flex shrink-0 items-center gap-1.5 rounded border border-outline px-2.5 py-1 font-mono text-[11px] text-fg transition-colors hover:border-accent focus-visible:outline-2 focus-visible:outline-accent';
---

<Layout title={t('nav.mcp')} description={t('mcp.metaDescription')}>
  <Section>
    <SectionHeader eyebrow={t('mcp.eyebrow')} title={t('mcp.title')} level={1} description={t('mcp.description')} />
    <div class="rounded border border-outline bg-raised p-5">
      <h2 class="font-mono text-xs tracking-wider text-muted uppercase">{t('mcp.endpointLabel')}</h2>
      <div class="mt-3 flex items-center gap-3">
        <code class={`${code} flex-1 text-accent`}>{MCP_ENDPOINT}</code>
        <button type="button" data-copy={MCP_ENDPOINT} class={copyButton}>
          <Icon name="lucide:copy" class="size-3" aria-hidden="true" />{t('mcp.copy')}
        </button>
      </div>
      <p class="mt-3 text-sm text-muted">{t('mcp.endpointNote')}</p>
    </div>
  </Section>

  <Section id="plugin">
    <SectionHeader eyebrow={t('mcp.pluginEyebrow')} title={t('mcp.pluginTitle')} description={t('mcp.pluginDescription')} />
    <ol class="grid gap-3">
      {
        PLUGIN_COMMANDS.map(command => (
          <li class="flex items-center gap-3">
            <code class={`${code} flex-1`}>{command}</code>
            <button type="button" data-copy={command} class={copyButton}>
              <Icon name="lucide:copy" class="size-3" aria-hidden="true" />{t('mcp.copy')}
            </button>
          </li>
        ))
      }
    </ol>
    <h3 class="mt-8 font-mono text-xs tracking-wider text-muted uppercase">{t('mcp.examplesTitle')}</h3>
    <ul class="mt-3 grid gap-2">
      {examples.map(n => <li class="rounded border border-hairline bg-raised px-4 py-3 text-fg">{t(`mcp.example${n}`)}</li>)}
    </ul>
  </Section>

  <Section id="clients">
    <SectionHeader eyebrow={t('mcp.clientsEyebrow')} title={t('mcp.clientsTitle')} />
    <ul class="grid grid-cols-1 gap-6 md:grid-cols-2">
      {
        clients.map(client => (
          <li class="rounded border border-outline bg-raised p-5">
            <h3 class="font-mono text-sm text-fg">{client.name}</h3>
            <p class="mt-2 text-sm text-muted">{t(`mcp.client.${client.id}`)}</p>
            <div class="mt-3 flex items-start gap-3">
              <code class={`${code} flex-1`}>{client.code}</code>
              <button type="button" data-copy={client.code} class={copyButton}>
                <Icon name="lucide:copy" class="size-3" aria-hidden="true" />{t('mcp.copy')}
              </button>
            </div>
          </li>
        ))
      }
    </ul>
  </Section>

  <Section id="tools">
    <SectionHeader eyebrow={t('mcp.toolsEyebrow')} title={t('mcp.toolsTitle')} />
    <dl class="grid gap-4">
      {
        MCP_TOOLS.map(tool => (
          <div class="rounded border border-hairline bg-raised px-4 py-3">
            <dt class="font-mono text-sm text-accent">{tool.name}</dt>
            <dd class="mt-1 text-sm text-muted">{t(`mcp.tool.${tool.name}`)}</dd>
          </div>
        ))
      }
    </dl>
  </Section>

  <CopyStatus />
</Layout>
```
(Class tokens are the site's own: `bg-raised`, `bg-base`, `border-outline`, `border-hairline`, `text-muted`, `text-fg`, `text-accent`. If one does not exist in `global.css`, use the equivalent the Docs view uses.)

**Step 3: Run the check to verify it passes**
Run: the Step 1 command, then `cd site && npm run verify`.
Expected: each page counts the endpoint at least twice, no `missing` line; `verify` green.

**Step 4: Browser check**
`cd site && npm run dev`: `/mcp` and `/pt-br/mcp` at 1280 and 390 px, nav link active, every Copy button copies and the status is announced, keyboard focus visible on each button, nothing overflows on mobile (the Cursor JSON scrolls inside its block).

**Step 5: Commit**
Run: `/git commit`

---

### Task 14: README "Use with AI"

**Requirement:** REQ-013
**Files:**
- Modify: `README.md` (new `## Use with AI` section after `## Ports`)
- Modify: `tests/plugin.bats`

**Team:**
- Track: docs
- Implementer: rpi-implementer (direct)
- Reviewers: self-review

**Step 1: Write the failing test**
```bash
@test "README: Use with AI points to /mcp and gives the plugin commands" {
    local section
    section="$(sed -n '/^## Use with AI$/,/^## /p' "$PROJECT_ROOT/README.md")"
    grep -q 'https://terminalnoir.web.app/mcp' <<<"$section"
    grep -q '/plugin marketplace add nandomoreirame/terminalnoir' <<<"$section"
    grep -q '/plugin install terminal-noir@terminal-noir' <<<"$section"
    grep -q 'https://terminalnoir.web.app/api/mcp' <<<"$section"
}
```

**Step 2: Run test to verify it fails**
Expected: FAIL.

**Step 3: Write minimal implementation**
```markdown
## Use with AI

An AI agent can apply Terminal Noir for you. In Claude Code, install the plugin (the `apply` skill plus the MCP server):

```text
/plugin marketplace add nandomoreirame/terminalnoir
/plugin install terminal-noir@terminal-noir
```

Any other MCP client connects to the read-only server at `https://terminalnoir.web.app/api/mcp`. Setup for each client and what every tool answers: [terminalnoir.web.app/mcp](https://terminalnoir.web.app/mcp).
```

**Step 4: Run test to verify it passes**
Expected: ok, and `tests/palette.bats` (README tables) still green.

**Step 5: Commit**
Run: `/git commit`

---

### Task 15: Launch and verify

**Requirement:** REQ-001 to REQ-013
**Depends on:** all; Fernando's ok to push.

**Steps:**
1. Full gates: bats suite, `make lint`, `cd functions && npm test && npm run build && npm audit --omit=dev`, `cd site && npm run verify`, `claude plugin validate .`.
2. On Fernando's ok, push `main`. Watch the CI run (`gh run watch`); a failure is reported, never retried blindly.
3. `scripts/verify-mcp` against production: `MCP VERIFIED`.
4. In a fresh Claude Code session on this machine: `/plugin marketplace add nandomoreirame/terminalnoir`, `/plugin install terminal-noir@terminal-noir`, then ask "list the Terminal Noir ports that have a paper variant" (expects ghostty, noctalia, shiki through the MCP) and "plan applying Terminal Noir to my Ghostty" (expects a plan with a backup step, no write before the ok).
5. `https://terminalnoir.web.app/mcp` and `/pt-br/mcp` answer 200 with the endpoint and the five tools.
6. Traceability to Done; `STATE.md` to `phase: review`.
