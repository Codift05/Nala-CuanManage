import { createHash, randomBytes } from 'node:crypto';
import jwt from 'jsonwebtoken';
import prisma from './prisma';
import { getJwtSecret } from './config';

const JWT_SECRET = getJwtSecret();
const REFRESH_TOKEN_DAYS = 30;

export const hashRefreshToken = (token: string): string =>
  createHash('sha256').update(token).digest('hex');

const createRefreshToken = (): string => randomBytes(32).toString('base64url');

export const createAccessToken = (userId: string, sessionId: string): string =>
  jwt.sign({ userId, sessionId }, JWT_SECRET, { expiresIn: '15m' });

export const createSession = async (
  userId: string,
  deviceName: unknown,
) => {
  const refreshToken = createRefreshToken();
  const session = await prisma.session.create({
    data: {
      userId,
      refreshTokenHash: hashRefreshToken(refreshToken),
      deviceName: typeof deviceName === 'string' && deviceName.trim()
        ? deviceName.trim().slice(0, 100)
        : 'Unknown device',
      expiresAt: new Date(Date.now() + REFRESH_TOKEN_DAYS * 86400000),
    },
  });
  return {
    accessToken: createAccessToken(userId, session.id),
    refreshToken,
    expiresIn: 900,
  };
};

export const rotateSession = async (refreshToken: unknown) => {
  if (typeof refreshToken !== 'string' || refreshToken.length < 32) return null;

  const currentHash = hashRefreshToken(refreshToken);
  const session = await prisma.session.findUnique({
    where: { refreshTokenHash: currentHash },
  });
  if (!session || session.revokedAt || session.expiresAt <= new Date()) return null;

  const nextRefreshToken = createRefreshToken();
  const updated = await prisma.session.updateMany({
    where: {
      id: session.id,
      refreshTokenHash: currentHash,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
    data: { refreshTokenHash: hashRefreshToken(nextRefreshToken) },
  });
  if (updated.count !== 1) return null;

  return {
    accessToken: createAccessToken(session.userId, session.id),
    refreshToken: nextRefreshToken,
    expiresIn: 900,
  };
};
