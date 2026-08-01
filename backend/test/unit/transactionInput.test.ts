import assert from 'node:assert/strict';
import test from 'node:test';
import {
  createTransactionCursor,
  parseTransactionDate,
  parseTransactionCursor,
  parseTransactionLimit,
  parseTransactionType,
} from '../../src/utils/transactionInput';

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

  const cursor = createTransactionCursor({
    date: new Date('2026-07-31T10:00:00.000Z'),
    id: 'transaction-1',
  });
  assert.deepEqual(parseTransactionCursor(cursor), {
    date: new Date('2026-07-31T10:00:00.000Z'),
    id: 'transaction-1',
  });
  assert.equal(parseTransactionCursor('invalid'), null);
});

