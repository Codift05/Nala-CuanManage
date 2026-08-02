import { NextFunction, Request, Response } from 'express';
import { createClient } from 'redis';
import { logError } from '../utils/logger';

const redis = createClient({ url: process.env.REDIS_URL });
redis.on('error', (error) => logError('redis.rate_limit_error', error));
let connecting: Promise<unknown> | undefined;

const memoryFallback = new Map<string, { count: number; expiresAt: number }>();

const hit = async (key: string, windowSeconds: number): Promise<number> => {
  try {
    if (!redis.isOpen) {
      connecting ??= redis.connect().finally(() => {
        connecting = undefined;
      });
      await connecting;
    }
    const count = await redis.eval(
      "local n=redis.call('INCR',KEYS[1]); if n==1 then redis.call('EXPIRE',KEYS[1],ARGV[1]); end; return n",
      { keys: [key], arguments: [String(windowSeconds)] },
    );
    return Number(count);
  } catch {
    const now = Date.now();
    const current = memoryFallback.get(key);
    const next = !current || current.expiresAt <= now
      ? { count: 1, expiresAt: now + windowSeconds * 1000 }
      : { ...current, count: current.count + 1 };
    memoryFallback.set(key, next);
    return next.count;
  }
};

export const rateLimit = ({
  prefix,
  limit,
  windowSeconds,
  includeEmail = false,
}: {
  prefix: string;
  limit: number;
  windowSeconds: number;
  includeEmail?: boolean;
}) => async (req: Request, res: Response, next: NextFunction) => {
  const ip = req.ip ?? req.socket.remoteAddress ?? 'unknown';
  const email = includeEmail && typeof req.body.email === 'string'
    ? `:${req.body.email.trim().toLowerCase()}`
    : '';
  const count = await hit(`rate:${prefix}:${ip}${email}`, windowSeconds);

  if (count > limit) {
    res.set('Retry-After', String(windowSeconds));
    res.status(429).json({
      message: 'Terlalu banyak percobaan. Coba lagi nanti.',
    });
    return;
  }
  next();
};
