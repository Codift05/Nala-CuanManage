import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../utils/prisma';

const JWT_SECRET = process.env.JWT_SECRET || 'nala_super_secret_key_2026';

export interface AuthRequest extends Request {
  user?: { userId: string; sessionId: string };
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    res.status(401).json({ message: 'Authentication token required' });
    return;
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as {
      userId?: string;
      sessionId?: string;
    };
    if (!decoded.userId || !decoded.sessionId) throw new Error('Invalid token');

    const session = await prisma.session.findFirst({
      where: {
        id: decoded.sessionId,
        userId: decoded.userId,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      select: { id: true },
    });
    if (!session) throw new Error('Session revoked');

    req.userId = decoded.userId;
    req.user = { userId: decoded.userId, sessionId: decoded.sessionId };
    next();
  } catch {
    res.status(403).json({ message: 'Invalid or expired token' });
  }
};
