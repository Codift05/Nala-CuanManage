import assert from 'node:assert/strict';
import test from 'node:test';
import { parseTransactionDraft } from '../../src/utils/transactionDraft';

test('accepts a safe draft and rejects invalid money or another user wallet', () => {
  const wallets = new Set(['wallet-1']);
  const valid = {
    action: 'create_transaction',
    type: 'EXPENSE',
    amount: 25000,
    categoryId: 'Food',
    walletId: 'wallet-1',
    merchant: 'Kantin',
  };

  assert.deepEqual(parseTransactionDraft(valid, wallets), {
    type: 'EXPENSE',
    amount: 25000,
    categoryId: 'Food',
    walletId: 'wallet-1',
    merchant: 'Kantin',
  });
  assert.equal(
    parseTransactionDraft({ ...valid, amount: Number.NaN }, wallets),
    null,
  );
  assert.equal(
    parseTransactionDraft({ ...valid, walletId: 'wallet-user-lain' }, wallets),
    null,
  );
});

