import assert from 'node:assert/strict';
import test from 'node:test';
import {
  parseBase64Image,
  parsePeriodPart,
  parseText,
  parseWalletType,
} from '../../src/utils/resourceInput';

test('resource inputs accept normalized values and reject unsafe shapes', () => {
  assert.equal(parseText('  Dompet utama  ', 80), 'Dompet utama');
  assert.equal(parseText([], 80), null);
  assert.equal(parseText('x'.repeat(81), 80), null);

  assert.equal(parsePeriodPart('12', 1, 12), 12);
  assert.equal(parsePeriodPart('13', 1, 12), null);
  assert.equal(parsePeriodPart('1.5', 1, 12), null);

  assert.equal(parseWalletType('E-Wallet'), 'EWALLET');
  assert.equal(parseWalletType('crypto'), null);

  assert.deepEqual(parseBase64Image('data:image/png;base64,aGVsbG8='), {
    data: 'aGVsbG8=',
    mimeType: 'image/png',
  });
  assert.equal(parseBase64Image('not base64'), null);
});

