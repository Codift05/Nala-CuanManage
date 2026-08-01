import assert from 'node:assert/strict';
import test from 'node:test';
import { parseRupiah, rupiahToJson } from '../../src/utils/money';

test('rupiah stays integer across request, database, and JSON boundaries', () => {
  assert.equal(parseRupiah(25000), 25000n);
  assert.equal(parseRupiah('1000000000000'), 1000000000000n);
  assert.equal(parseRupiah(12.5), null);
  assert.equal(parseRupiah(-1), null);
  assert.equal(parseRupiah(0), null);
  assert.equal(parseRupiah(0, { allowZero: true }), 0n);
  assert.equal(rupiahToJson(25000n), 25000);
});

