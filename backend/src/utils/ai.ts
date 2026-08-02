export const getGeminiTimeoutMs = (value = process.env.GEMINI_TIMEOUT_MS): number => {
  const timeout = Number(value ?? 8000);
  return Number.isInteger(timeout) && timeout >= 1000 && timeout <= 30000
    ? timeout
    : 8000;
};

export const getGeminiModel = (value = process.env.GEMINI_MODEL): string =>
  value?.trim() || 'gemini-3.5-flash-lite';

export const redactSensitiveText = (value: string): string => value
  .replace(/[\w.+-]+@[\w-]+(?:\.[\w-]+)+/gi, '[EMAIL]')
  .replace(/(?:\+62|62|0)[\s-]?8(?:[\s-]?\d){7,11}\b/g, '[NOMOR_TELEPON]')
  .replace(/\b(?:\d[\s-]?){12,18}\d\b/g, '[NOMOR_REKENING_ATAU_KARTU]');

export const prepareAiUserMessage = (value: string): string =>
  redactSensitiveText(value).replace(/[<>]/g, (character) =>
    character === '<' ? '‹' : '›');

export const withTimeout = async <T>(
  promise: Promise<T>,
  timeoutMs: number,
): Promise<T> => {
  let timer: NodeJS.Timeout | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(
      () => reject(new Error(`Gemini timeout after ${timeoutMs}ms`)),
      timeoutMs,
    );
  });

  try {
    return await Promise.race([promise, timeout]);
  } finally {
    if (timer) clearTimeout(timer);
  }
};
