export const parseText = (
  value: unknown,
  maxLength: number,
  options: { optional?: boolean } = {},
): string | undefined | null => {
  if (value === undefined || value === null) {
    return options.optional ? undefined : null;
  }
  if (typeof value !== 'string') return null;

  const text = value.trim();
  if (!text || text.length > maxLength) return null;
  return text;
};

export const parsePeriodPart = (
  value: unknown,
  minimum: number,
  maximum: number,
): number | null => {
  if (
    (typeof value !== 'number' && typeof value !== 'string') ||
    !/^\d+$/.test(String(value))
  ) return null;

  const number = Number(value);
  return Number.isSafeInteger(number) && number >= minimum && number <= maximum
    ? number
    : null;
};

const WALLET_TYPES: Record<string, string> = {
  cash: 'CASH',
  bank: 'BANK',
  ewallet: 'EWALLET',
  'e-wallet': 'EWALLET',
};

export const parseWalletType = (value: unknown): string | null =>
  typeof value === 'string'
    ? WALLET_TYPES[value.trim().toLowerCase()] ?? null
    : null;

export const parseBase64Image = (
  value: unknown,
): { data: string; mimeType: 'image/jpeg' | 'image/png' } | null => {
  if (typeof value !== 'string') return null;
  const dataUri = value.match(/^data:(image\/(?:jpeg|png));base64,(.*)$/);
  const data = dataUri?.[2] ?? value;
  if (
    data.length === 0 ||
    data.length > 1_500_000 ||
    data.length % 4 !== 0 ||
    !/^[A-Za-z0-9+/]*={0,2}$/.test(data)
  ) return null;
  return {
    data,
    mimeType: (dataUri?.[1] as 'image/jpeg' | 'image/png' | undefined) ?? 'image/jpeg',
  };
};
