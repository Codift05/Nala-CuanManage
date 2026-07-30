export const MAX_RUPIAH = 1_000_000_000_000_000n;

export const parseRupiah = (
  value: unknown,
  { allowZero = false }: { allowZero?: boolean } = {},
): bigint | null => {
  if (
    (typeof value === 'number' && !Number.isSafeInteger(value)) ||
    (typeof value !== 'number' &&
      (typeof value !== 'string' || !/^\d+$/.test(value)))
  ) {
    return null;
  }

  const amount = BigInt(value);
  if (amount < 0n || (!allowZero && amount === 0n) || amount > MAX_RUPIAH) {
    return null;
  }
  return amount;
};

export const rupiahToJson = (value: bigint): number => {
  const amount = Number(value);
  if (!Number.isSafeInteger(amount)) {
    throw new RangeError('Nominal rupiah melewati batas aman JSON');
  }
  return amount;
};
