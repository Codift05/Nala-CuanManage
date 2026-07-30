import { createHash, randomBytes } from 'node:crypto';

export const createEmailVerificationToken = () => {
  const token = randomBytes(32).toString('base64url');
  return {
    token,
    tokenHash: hashEmailVerificationToken(token),
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
  };
};

export const hashEmailVerificationToken = (token: string): string =>
  createHash('sha256').update(token).digest('hex');
