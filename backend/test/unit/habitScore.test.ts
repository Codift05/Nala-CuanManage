import assert from 'node:assert/strict';
import test from 'node:test';
import { calculateHabitScore, describeHabitScore } from '../../src/utils/habitScore';

const start = new Date('2026-08-01T00:00:00.000Z');
const end = new Date('2026-09-01T00:00:00.000Z');
const asOf = new Date('2026-08-10T12:00:00.000Z');

test('habit score stays unavailable instead of inventing a new-user score', () => {
  const result = calculateHabitScore([], 0, start, end, asOf);
  assert.equal(result.score, null);
  assert.equal(result.factors.every((factor) => !factor.available), true);
  assert.equal(describeHabitScore(result.score).status, 'Belum cukup data');
});

test('a budget without transaction activity does not produce a perfect score', () => {
  const result = calculateHabitScore([], 1_000_000, start, end, asOf);
  assert.equal(result.score, null);
  assert.equal(result.factors[1]?.score, null);
});

test('habit score excludes unavailable factors and never rewards diversification', () => {
  const transactions = [
    { type: 'INCOME', amount: 1_000_000n, date: new Date('2026-08-01T10:00:00Z') },
    { type: 'EXPENSE', amount: 700_000n, date: new Date('2026-08-02T10:00:00Z') },
    { type: 'EXPENSE', amount: 100_000n, date: new Date('2026-08-03T10:00:00Z') },
    { type: 'EXPENSE', amount: 50_000n, date: new Date('2026-08-04T10:00:00Z') },
  ];
  const result = calculateHabitScore(transactions, 1_000_000, start, end, asOf);

  assert.equal(result.score, 88);
  assert.deepEqual(result.factors.map((factor) => factor.key), [
    'savingRatio',
    'budgetCompliance',
    'consistency',
  ]);
  assert.equal(result.actions.length, 3);
});

test('zero income and missing budget do not receive arbitrary points', () => {
  const result = calculateHabitScore([
    { type: 'EXPENSE', amount: 50_000n, date: new Date('2026-08-02T10:00:00Z') },
  ], 0, start, end, asOf);

  assert.equal(result.factors[0]?.score, null);
  assert.equal(result.factors[1]?.score, null);
  assert.equal(result.score, 25);
});
