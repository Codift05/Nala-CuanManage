import assert from 'node:assert/strict';
import test from 'node:test';
import { buildDemoData } from '../../src/demo/demoData';

test('demo dataset stays current, balanced, and repeatable', () => {
  const now = new Date(2026, 7, 3, 12);
  const first = buildDemoData(now);
  const second = buildDemoData(now);

  assert.deepEqual(first, second);
  assert.equal(first.transactions.length, 24);
  assert.equal(first.recurringBills.length, 3);
  assert.equal(new Set(first.transactions.map((item) => item.key)).size, 24);
  assert.equal(first.transactions.filter(
    (item) => item.date.getMonth() === now.getMonth(),
  ).length, 9);
  assert.ok(first.transactions.some((item) => item.type === 'INCOME'));
  assert.ok(first.transactions.some((item) => item.type === 'EXPENSE'));
  assert.deepEqual(
    new Set(first.transactions.map((item) => item.wallet)),
    new Set(['cash', 'gopay', 'bank']),
  );
});
