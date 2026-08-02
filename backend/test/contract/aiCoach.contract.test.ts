import assert from 'node:assert/strict';
import test from 'node:test';
import { buildChatResponse } from '../../src/utils/chatResponse';

test('AI Coach response has a stable success and fallback envelope', () => {
  const draft = {
    type: 'EXPENSE' as const,
    amount: 25_000,
    categoryId: 'Food',
    walletId: 'wallet-1',
  };

  assert.deepEqual(buildChatResponse(' Periksa draft. ', draft), {
    reply: 'Periksa draft.',
    transactionDraft: draft,
    fallback: false,
  });
  assert.deepEqual(buildChatResponse('AI tidak tersedia.', null, true), {
    reply: 'AI tidak tersedia.',
    transactionDraft: null,
    fallback: true,
  });
  assert.equal(buildChatResponse('').reply, 'Respons Nala belum tersedia.');
});
