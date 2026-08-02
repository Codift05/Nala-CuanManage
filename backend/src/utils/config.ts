type Environment = Record<string, string | undefined>;

export const getJwtSecret = (env: Environment = process.env): string => {
  const secret = env.JWT_SECRET?.trim();
  if (env.NODE_ENV === 'production' && (!secret || secret.length < 32)) {
    throw new Error('JWT_SECRET production wajib memiliki minimal 32 karakter');
  }
  return secret || 'nala-development-only-secret';
};

export const getCorsOrigins = (
  env: Environment = process.env,
): Set<string> | null => {
  const values = env.CORS_ORIGINS?.split(',')
    .map((origin) => origin.trim())
    .filter(Boolean) ?? [];

  if (env.NODE_ENV === 'production' && values.length === 0) {
    throw new Error('CORS_ORIGINS production wajib dikonfigurasi');
  }
  for (const origin of values) {
    const url = new URL(origin);
    if (!['http:', 'https:'].includes(url.protocol) || url.origin !== origin) {
      throw new Error(`CORS origin tidak valid: ${origin}`);
    }
  }
  return values.length ? new Set(values) : null;
};

export const isOriginAllowed = (
  origin: string | undefined,
  allowedOrigins: Set<string> | null,
): boolean => !origin || !allowedOrigins || allowedOrigins.has(origin);

export type EmailConfig = {
  apiKey: string;
  from: string;
  appUrl: string;
};

export const getEmailConfig = (
  env: Environment = process.env,
): EmailConfig | null => {
  const apiKey = env.RESEND_API_KEY?.trim();
  const from = env.EMAIL_FROM?.trim();
  const appUrl = env.APP_URL?.trim();
  if (env.NODE_ENV === 'production' && (!apiKey || !from || !appUrl)) {
    throw new Error(
      'RESEND_API_KEY, EMAIL_FROM, dan APP_URL wajib dikonfigurasi di production',
    );
  }
  if (!apiKey || !from || !appUrl) return null;
  return { apiKey, from, appUrl: new URL(appUrl).toString() };
};

export const validateProductionServices = (
  env: Environment = process.env,
): void => {
  if (env.NODE_ENV !== 'production') return;
  for (const name of ['DATABASE_URL', 'REDIS_URL'] as const) {
    if (!env[name]?.trim()) throw new Error(`${name} wajib dikonfigurasi`);
  }
};
