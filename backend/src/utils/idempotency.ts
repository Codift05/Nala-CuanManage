const IDEMPOTENCY_KEY_PATTERN = /^[A-Za-z0-9._:-]{16,128}$/;

export const parseIdempotencyKey = (value: unknown): string | null =>
  typeof value === 'string' && IDEMPOTENCY_KEY_PATTERN.test(value)
    ? value
    : null;

export const recurringPeriod = (date: Date): string =>
  `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

export const recurringIdempotencyKey = (
  recurringBillId: string,
  date: Date,
): string => `recurring:${recurringBillId}:${recurringPeriod(date)}`;

export const recurringDueDays = (date: Date): number[] => {
  const day = date.getDate();
  const lastDay = new Date(
    date.getFullYear(),
    date.getMonth() + 1,
    0,
  ).getDate();
  return day === lastDay
    ? Array.from({ length: 32 - day }, (_, index) => day + index)
    : [day];
};
