export const TRANSACTION_TYPES = ['INCOME', 'EXPENSE'] as const;
export type TransactionType = (typeof TRANSACTION_TYPES)[number];

export const parseTransactionType = (value: unknown): TransactionType | null =>
  typeof value === 'string' &&
  TRANSACTION_TYPES.includes(value as TransactionType)
    ? (value as TransactionType)
    : null;

export const parseTransactionDate = (
  value: unknown,
): Date | undefined | null => {
  if (value === undefined || value === null || value === '') return undefined;
  if (
    typeof value !== 'string' ||
    !/^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z)?$/.test(value)
  ) return null;

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ||
    date.toISOString().slice(0, 10) !== value.slice(0, 10)
    ? null
    : date;
};

export const parseTransactionLimit = (value: unknown): number | undefined | null => {
  if (value === undefined) return undefined;
  if (typeof value !== 'string' || !/^\d+$/.test(value)) return null;

  const limit = Number(value);
  return Number.isSafeInteger(limit) && limit >= 1 && limit <= 100
    ? limit
    : null;
};
