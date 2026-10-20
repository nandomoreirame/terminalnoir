// Facts about the theme repo, read at build time so the site never states a
// number the repo does not back.
const suites = import.meta.glob<string>('../../../tests/*.bats', { query: '?raw', import: 'default', eager: true });

export function countBatsTests(source: string): number {
  return source.match(/^@test /gm)?.length ?? 0;
}

export function batsTestCount(): number {
  return Object.values(suites).reduce((sum, source) => sum + countBatsTests(source), 0);
}
