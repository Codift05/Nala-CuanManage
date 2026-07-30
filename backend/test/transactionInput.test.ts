import assert from 'node:assert/strict';
import test from 'node:test';
import {
  parseTransactionDate,
  parseTransactionLimit,
  parseTransactionType,
} from '../src/utils/transactionInput';

test('transaction inputs reject invalid types, dates, and list limits', () => {
  assert.equal(parseTransactionType('INCOME'), 'INCOME');
  assert.equal(parseTransactionType('TRANSFER'), null);

  assert.equal(parseTransactionDate(undefined), undefined);
  assert.equal(parseTransactionDate('2026-07-30T12:00:00.000Z')?.toISOString(), '2026-07-30T12:00:00.000Z');
  assert.equal(parseTransactionDate('not-a-date'), null);
  assert.equal(parseTransactionDate('2026-02-31'), null);

  assert.equal(parseTransactionLimit(undefined), undefined);
  assert.equal(parseTransactionLimit('50'), 50);
  assert.equal(parseTransactionLimit('0'), null);
  assert.equal(parseTransactionLimit('101'), null);
  assert.equal(parseTransactionLimit('NaN'), null);
});
