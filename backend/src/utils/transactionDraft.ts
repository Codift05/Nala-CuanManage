export type TransactionDraft = {
  type: 'INCOME' | 'EXPENSE';
  amount: number;
  categoryId: string;
  walletId: string;
  merchant?: string;
  notes?: string;
};

const categories = new Set([
  'Food',
  'Transport',
  'Entertainment',
  'Shopping',
  'Bills',
  'Income',
  'Salary',
  'Others',
]);

const optionalText = (value: unknown, maxLength: number): string | undefined => {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value !== 'string') return undefined;
  const text = value.trim();
  return text && text.length <= maxLength ? text : undefined;
};

export const parseTransactionDraft = (
  value: unknown,
  allowedWalletIds: Set<string>,
): TransactionDraft | null => {
  if (!value || typeof value !== 'object') return null;

  const draft = value as Record<string, unknown>;
  if (draft.action !== 'create_transaction') return null;
  if (draft.type !== 'INCOME' && draft.type !== 'EXPENSE') return null;
  if (
    typeof draft.amount !== 'number' ||
    !Number.isSafeInteger(draft.amount) ||
    draft.amount <= 0 ||
    draft.amount > 1_000_000_000_000
  ) {
    return null;
  }
  if (typeof draft.walletId !== 'string' ||
      !allowedWalletIds.has(draft.walletId)) {
    return null;
  }
  if (typeof draft.categoryId !== 'string' ||
      !categories.has(draft.categoryId)) {
    return null;
  }

  const merchant = optionalText(draft.merchant, 120);
  const notes = optionalText(draft.notes, 300);

  return {
    type: draft.type,
    amount: draft.amount,
    categoryId: draft.categoryId,
    walletId: draft.walletId,
    ...(merchant ? { merchant } : {}),
    ...(notes ? { notes } : {}),
  };
};
