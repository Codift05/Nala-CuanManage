const sensitiveKey = /authorization|cookie|email|password|secret|token|api.?key/i;

const redactText = (value: string) => value
  .replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[REDACTED_EMAIL]')
  .replace(/Bearer\s+\S+/gi, 'Bearer [REDACTED]')
  .replace(/\b(?:\d[ -]?){12,19}\b/g, '[REDACTED_NUMBER]');

const clean = (fields: Record<string, unknown>) => Object.fromEntries(
  Object.entries(fields).map(([key, value]) => [
    key,
    sensitiveKey.test(key)
      ? '[REDACTED]'
      : typeof value === 'string'
        ? redactText(value)
        : typeof value === 'bigint'
          ? value.toString()
          : value,
  ]),
);

export const formatLog = (
  level: 'info' | 'error',
  event: string,
  fields: Record<string, unknown>,
) => JSON.stringify({
  timestamp: new Date().toISOString(),
  level,
  event,
  ...clean(fields),
});

const write = (
  level: 'info' | 'error',
  event: string,
  fields: Record<string, unknown>,
) => console[level](formatLog(level, event, fields));

export const logInfo = (
  event: string,
  fields: Record<string, unknown> = {},
) => write('info', event, fields);

export const logError = (
  event: string,
  error: unknown,
  fields: Record<string, unknown> = {},
) => write('error', event, {
  ...fields,
  errorName: error instanceof Error ? error.name : 'UnknownError',
  errorMessage: redactText(error instanceof Error ? error.message : String(error)),
});
