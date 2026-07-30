export const getGeminiTimeoutMs = (value = process.env.GEMINI_TIMEOUT_MS): number => {
  const timeout = Number(value ?? 8000);
  return Number.isInteger(timeout) && timeout >= 1000 && timeout <= 30000
    ? timeout
    : 8000;
};

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
