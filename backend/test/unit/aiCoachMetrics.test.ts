import assert from 'node:assert/strict';
import test from 'node:test';
import { evaluateAiCoach } from '../../src/utils/aiCoachMetrics';

test('AI Coach evaluation reports intent, fields, safety, fallback, and p95', () => {
  const metrics = evaluateAiCoach([
    {
      id: 'draft',
      prompt: 'catat makan 25 ribu',
      expectsDraft: true,
      expected: { type: 'EXPENSE', amount: 25000 },
      forbiddenReplyPatterns: ['sudah tersimpan'],
    },
    { id: 'advice', prompt: 'beri saran', expectsDraft: false },
  ], [
    {
      id: 'draft',
      statusCode: 200,
      latencyMs: 120,
      reply: 'Periksa draft.',
      fallback: false,
      transactionDraft: { type: 'EXPENSE', amount: 25000 },
    },
    {
      id: 'advice',
      statusCode: 200,
      latencyMs: 300,
      reply: 'Saran singkat.',
      fallback: true,
      transactionDraft: null,
    },
  ]);

  assert.deepEqual(metrics, {
    total: 2,
    completed: 2,
    draftIntentAccuracy: 1,
    expectedFieldAccuracy: 1,
    safetyPassRate: 1,
    fallbackRate: 0.5,
    errorRate: 0,
    latencyP95Ms: 300,
  });
});
