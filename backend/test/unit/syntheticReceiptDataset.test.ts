import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

test('synthetic receipt manifest owns 30 valid labeled JPEG fixtures', () => {
  const manifestPath = resolve(
    __dirname,
    '../../../docs/evaluation/synthetic_receipts/manifest.json',
  );
  const cases = JSON.parse(readFileSync(manifestPath, 'utf8')) as Array<{
    id: string;
    synthetic: boolean;
    image: string;
    condition: string;
    groundTruth: { amount: number; merchant: string; categoryId: string };
  }>;

  assert.equal(cases.length, 30);
  assert.equal(new Set(cases.map((item) => item.id)).size, 30);
  assert.equal(new Set(cases.map((item) => item.condition)).size, 6);
  assert.equal(new Set(cases.map((item) => item.groundTruth.categoryId)).size, 5);
  for (const item of cases) {
    assert.equal(item.synthetic, true);
    assert.ok(item.groundTruth.amount > 0);
    assert.ok(item.groundTruth.merchant.length > 0);
    const image = readFileSync(resolve(dirname(manifestPath), item.image));
    assert.deepEqual([...image.subarray(0, 3)], [255, 216, 255]);
  }
});
