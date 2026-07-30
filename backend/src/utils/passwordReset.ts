import { createHash, randomBytes } from 'node:crypto';

export const PASSWORD_RESET_MINUTES = 15;

export const createPasswordResetToken = () => {
  const token = randomBytes(32).toString('base64url');
  return {
    token,
    tokenHash: hashPasswordResetToken(token),
    expiresAt: new Date(Date.now() + PASSWORD_RESET_MINUTES * 60000),
  };
};

export const hashPasswordResetToken = (token: string): string =>
  createHash('sha256').update(token).digest('hex');
