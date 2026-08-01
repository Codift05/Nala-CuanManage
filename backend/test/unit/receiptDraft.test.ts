import assert from 'node:assert/strict';
import test from 'node:test';
import {
  parseReceiptDraft,
  parseReceiptDraftResponse,
} from '../../src/utils/receiptDraft';

test('receipt draft preserves safe data and marks uncertain fields for review', () => {
  assert.deepEqual(parseReceiptDraft({
    amount: 125000,
    merchant: '  Toko Nala  ',
    categoryId: 'Shopping',
    notes: 'Belanja bulanan',
    confidence: { amount: 0.95, merchant: 0.6, categoryId: 0.82 },
  }), {
    amount: 125000,
    merchant: 'Toko Nala',
    categoryId: 'Shopping',
    notes: 'Belanja bulanan',
    confidence: { amount: 0.95, merchant: 0.6, categoryId: 0.82 },
    reviewRequired: ['merchant'],
  });

  assert.equal(parseReceiptDraft({
    amount: 0,
    merchant: 'Toko Nala',
    categoryId: 'Shopping',
  }), null);
  assert.equal(parseReceiptDraftResponse('bukan json'), null);
});
