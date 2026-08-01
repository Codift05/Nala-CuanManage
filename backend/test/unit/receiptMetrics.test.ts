import assert from 'node:assert/strict';
import test from 'node:test';
import { evaluateReceipts } from '../../src/utils/receiptMetrics';

test('receipt metrics use raw cases and flag incorrect extraction', () => {
  const metrics = evaluateReceipts(
    [
      {
        id: 'receipt-001',
        groundTruth: { amount: 25000, merchant: 'Toko Nala', categoryId: 'Food' },
      },
      {
        id: 'receipt-002',
        groundTruth: { amount: 50000, merchant: 'Kantin Unsrat', categoryId: 'Food' },
      },
      {
        id: 'receipt-003',
        groundTruth: { amount: 12000, merchant: 'Warung Kampus', categoryId: 'Food' },
      },
    ],
    [
      {
        id: 'receipt-001',
        prediction: { amount: 25000, merchant: ' toko  nala ', categoryId: 'Food' },
        reviewRequired: [],
        correctedFields: [],
        latencyMs: 1000,
      },
      {
        id: 'receipt-002',
        prediction: { amount: 5000, merchant: 'Kantin Unsrat', categoryId: 'Others' },
        reviewRequired: ['amount', 'categoryId'],
        correctedFields: ['amount', 'categoryId'],
        latencyMs: 3000,
      },
      {
        id: 'receipt-003',
        prediction: null,
        reviewRequired: [],
        correctedFields: [],
        latencyMs: 2000,
      },
    ],
  );

  assert.deepEqual(metrics, {
    sampleSize: 3,
    extractionSuccessRate: 2 / 3,
    amountExactMatch: 1 / 3,
    merchantExactMatch: 2 / 3,
    categoryAccuracy: 1 / 3,
    reviewFlagRecall: 1,
    correctionRate: 1 / 3,
    latencyMs: { p50: 2000, p95: 3000 },
  });
});
