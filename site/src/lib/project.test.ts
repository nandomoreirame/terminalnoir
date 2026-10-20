import { describe, expect, it } from 'vitest';
import { batsTestCount, countBatsTests } from './project';

describe('countBatsTests', () => {
  it('counts @test lines only', () => {
    const suite = '#!/usr/bin/env bats\nload x\n\n@test "a" {\n}\n\n@test "b" {\n  # @test "not this"\n}\n';

    expect(countBatsTests(suite)).toBe(2);
  });
});

describe('batsTestCount', () => {
  it('counts the tests across the repo suites', () => {
    expect(batsTestCount()).toBeGreaterThanOrEqual(30);
  });
});
