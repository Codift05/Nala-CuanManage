import { EmailConfig, getEmailConfig } from './config';

export const sendPasswordResetEmail = async (
  {
    to,
    token,
    idempotencyKey,
  }: { to: string; token: string; idempotencyKey: string },
  config: EmailConfig | null = getEmailConfig(),
  fetcher: typeof fetch = fetch,
): Promise<boolean> => {
  if (!config) return false;

  const resetUrl = new URL(config.appUrl);
  resetUrl.searchParams.set('token', token);
  const response = await fetcher('https://api.resend.com/emails', {
    method: 'POST',
    signal: AbortSignal.timeout(8000),
    headers: {
      Authorization: `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': idempotencyKey,
      'User-Agent': 'NALA/1.0',
    },
    body: JSON.stringify({
      from: config.from,
      to: [to],
      subject: 'Reset password NALA',
      text: `Buka tautan ini untuk mereset password NALA. Tautan berlaku 15 menit: ${resetUrl}`,
      html: `<p>Buka tautan berikut untuk mereset password NALA. Tautan berlaku 15 menit.</p><p><a href="${resetUrl}">Reset password NALA</a></p>`,
    }),
  });
  if (!response.ok) {
    throw new Error(`Email provider returned ${response.status}`);
  }
  return true;
};
