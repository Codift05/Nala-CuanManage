import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { prepareAiUserMessage } from '../../src/utils/ai';
import { parseTransactionDraft } from '../../src/utils/transactionDraft';

type AdversarialCase = {
  name: string;
  input: string;
  mustHide: string;
  mustContain: string;
};

const cases = JSON.parse(readFileSync(
  join(__dirname, '../fixtures/aiCoachAdversarial.json'),
  'utf8',
)) as AdversarialCase[];

test('adversarial AI messages keep their boundary and redact common PII', () => {
  for (const scenario of cases) {
    const prepared = prepareAiUserMessage(scenario.input);
    assert.equal(prepared.includes(scenario.mustHide), false, scenario.name);
    assert.equal(prepared.includes(scenario.mustContain), true, scenario.name);
    assert.equal(/[<>]/.test(prepared), false, scenario.name);
  }
});

test('hostile AI drafts cannot select another wallet or bypass the schema', () => {
  const allowedWallets = new Set(['wallet-owner']);
  const valid = {
    action: 'create_transaction',
    type: 'EXPENSE',
    amount: 25_000,
    categoryId: 'Food',
    walletId: 'wallet-owner',
  };

  assert.equal(parseTransactionDraft({ ...valid, walletId: 'wallet-victim' }, allowedWallets), null);
  assert.equal(parseTransactionDraft({ ...valid, action: 'delete_account' }, allowedWallets), null);
  assert.equal(parseTransactionDraft({ ...valid, amount: '25000' }, allowedWallets), null);
  assert.equal(parseTransactionDraft({ ...valid, categoryId: 'SYSTEM_OVERRIDE' }, allowedWallets), null);
  assert.deepEqual(parseTransactionDraft(valid, allowedWallets), {
    type: 'EXPENSE',
    amount: 25_000,
    categoryId: 'Food',
    walletId: 'wallet-owner',
  });
});
