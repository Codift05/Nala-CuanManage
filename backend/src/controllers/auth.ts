import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';
import { createSession, rotateSession } from '../utils/authTokens';
import {
  createPasswordResetToken,
  hashPasswordResetToken,
} from '../utils/passwordReset';
import { sendEmailVerification, sendPasswordResetEmail } from '../utils/email';
import { logError } from '../utils/logger';
import {
  createEmailVerificationToken,
  hashEmailVerificationToken,
} from '../utils/emailVerification';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const normalizeEmail = (email: unknown): string =>
  typeof email === 'string' ? email.trim().toLowerCase() : '';

const normalizeName = (name: unknown): string =>
  typeof name === 'string' ? name.trim() : '';

const readPassword = (password: unknown): string =>
  typeof password === 'string' ? password : '';

const MAX_NAME_LENGTH = 80;
const MAX_AVATAR_BASE64_LENGTH = 1_500_000;

const isValidBase64 = (value: string): boolean =>
  value.length % 4 === 0 && /^[A-Za-z0-9+/]*={0,2}$/.test(value);

export const register = async (req: Request, res: Response) => {
  try {
    const name = normalizeName(req.body.name);
    const email = normalizeEmail(req.body.email);
    const password = readPassword(req.body.password);

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Nama, email, dan password wajib diisi' });
    }

    if (name.length < 2 || name.length > MAX_NAME_LENGTH) {
      return res.status(400).json({
        message: `Nama harus terdiri dari 2-${MAX_NAME_LENGTH} karakter`
      });
    }

    if (!EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ message: 'Format email tidak valid' });
    }

    if (password.length < 8 || password.length > 72) {
      return res.status(400).json({ message: 'Password harus terdiri dari 8-72 karakter' });
    }

    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(409).json({ message: 'Email sudah terdaftar' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const verification = createEmailVerificationToken();
    const user = await prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: {
          name,
          email,
          passwordHash
        }
      });

      await tx.wallet.create({
        data: {
          userId: createdUser.id,
          name: 'Dompet Utama',
          type: 'CASH',
          balance: 0
        }
      });
      await tx.emailVerificationToken.create({
        data: {
          userId: createdUser.id,
          tokenHash: verification.tokenHash,
          expiresAt: verification.expiresAt,
        },
      });
      await tx.auditLog.create({
        data: {
          actorUserId: createdUser.id,
          action: 'ACCOUNT_REGISTERED',
          resourceType: 'USER',
          resourceId: createdUser.id,
          requestId: res.locals.requestId,
        },
      });

      return createdUser;
    });

    if (process.env.NODE_ENV === 'production') {
      try {
        await sendEmailVerification({
          to: user.email,
          token: verification.token,
          idempotencyKey: `verify-${user.id}`,
        });
      } catch (error) {
        logError('email.verification_failed', error);
      }
    }

    res.status(201).json({
      message: 'Akun dibuat. Periksa email untuk melakukan verifikasi.',
      ...(process.env.NODE_ENV !== 'production'
        ? { verificationToken: verification.token }
        : {}),
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    logError('auth.registration_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const login = async (req: Request, res: Response) => {
  try {
    const email = normalizeEmail(req.body.email);
    const password = readPassword(req.body.password);

    if (!email || !password) {
      return res.status(400).json({ message: 'Email dan password wajib diisi' });
    }

    if (!EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ message: 'Format email tidak valid' });
    }

    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      return res.status(401).json({ message: 'Email atau password salah' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Email atau password salah' });
    }
    if (!user.emailVerifiedAt) {
      return res.status(403).json({ message: 'Email belum diverifikasi' });
    }

    const tokens = await createSession(
      user.id,
      req.body.deviceName,
      res.locals.requestId,
    );

    res.json({
      message: 'Login successful',
      token: tokens.accessToken,
      ...tokens,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    logError('auth.login_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const verifyEmail = async (req: Request, res: Response) => {
  const token = typeof req.body.token === 'string' ? req.body.token : '';
  const verification = token
    ? await prisma.emailVerificationToken.findUnique({
        where: { tokenHash: hashEmailVerificationToken(token) },
      })
    : null;
  if (!verification || verification.usedAt || verification.expiresAt <= new Date()) {
    return res.status(400).json({ message: 'Token verifikasi tidak valid atau kedaluwarsa' });
  }

  const verified = await prisma.$transaction(async (tx) => {
    const consumed = await tx.emailVerificationToken.updateMany({
      where: {
        id: verification.id,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      data: { usedAt: new Date() },
    });
    if (consumed.count !== 1) return false;
    await tx.user.update({
      where: { id: verification.userId },
      data: { emailVerifiedAt: new Date() },
    });
    await tx.auditLog.create({
      data: {
        actorUserId: verification.userId,
        action: 'EMAIL_VERIFIED',
        resourceType: 'USER',
        resourceId: verification.userId,
        requestId: res.locals.requestId,
      },
    });
    return true;
  });
  return verified
    ? res.json({ message: 'Email berhasil diverifikasi. Silakan masuk.' })
    : res.status(400).json({ message: 'Token verifikasi tidak valid atau kedaluwarsa' });
};

export const resendVerification = async (req: Request, res: Response) => {
  const email = normalizeEmail(req.body.email);
  const user = EMAIL_PATTERN.test(email)
    ? await prisma.user.findUnique({ where: { email } })
    : null;
  let verificationToken: string | undefined;

  if (user && !user.emailVerifiedAt) {
    const generated = createEmailVerificationToken();
    const verification = await prisma.$transaction(async (tx) => {
      await tx.emailVerificationToken.deleteMany({
        where: { userId: user.id, usedAt: null },
      });
      return tx.emailVerificationToken.create({
        data: {
          userId: user.id,
          tokenHash: generated.tokenHash,
          expiresAt: generated.expiresAt,
        },
      });
    });
    if (process.env.NODE_ENV !== 'production') {
      verificationToken = generated.token;
    } else {
      try {
        await sendEmailVerification({
          to: user.email,
          token: generated.token,
          idempotencyKey: verification.id,
        });
      } catch (error) {
        logError('email.verification_failed', error);
      }
    }
  }

  return res.json({
    message: 'Jika akun belum terverifikasi, email baru akan dikirim.',
    ...(verificationToken ? { verificationToken } : {}),
  });
};

export const me = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ message: 'Sesi tidak valid' });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: { id: true, name: true, email: true, avatar: true, createdAt: true }
    });

    if (!user) {
      return res.status(404).json({ message: 'Pengguna tidak ditemukan' });
    }

    return res.json({ user });
  } catch (error) {
    logError('auth.current_user_failed', error);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Sesi tidak valid' });
    }

    const name = normalizeName(req.body.name);
    const email = normalizeEmail(req.body.email);
    const avatar = req.body.avatar;

    if (!name || !email) {
      return res.status(400).json({ message: 'Nama dan email wajib diisi' });
    }

    if (name.length < 2 || name.length > MAX_NAME_LENGTH) {
      return res.status(400).json({
        message: `Nama harus terdiri dari 2-${MAX_NAME_LENGTH} karakter`
      });
    }

    if (!EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ message: 'Format email tidak valid' });
    }

    if (avatar !== undefined && avatar !== null) {
      if (typeof avatar !== 'string') {
        return res.status(400).json({ message: 'Format foto profil tidak valid' });
      }
      if (avatar.length > MAX_AVATAR_BASE64_LENGTH) {
        return res.status(413).json({ message: 'Ukuran foto profil terlalu besar' });
      }
      if (avatar.length > 0 && !isValidBase64(avatar)) {
        return res.status(400).json({ message: 'Data foto profil tidak valid' });
      }
    }

    const emailOwner = await prisma.user.findUnique({ where: { email } });
    if (emailOwner && emailOwner.id !== userId) {
      return res.status(409).json({ message: 'Email sudah digunakan akun lain' });
    }

    const user = await prisma.$transaction(async (tx) => {
      const updated = await tx.user.update({
        where: { id: userId },
        data: {
          name,
          email,
          ...(avatar !== undefined ? { avatar } : {})
        }
      });
      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'PROFILE_UPDATED',
          resourceType: 'USER',
          resourceId: userId,
          requestId: res.locals.requestId,
          metadata: {
            changedFields: [
              'name',
              'email',
              ...(avatar !== undefined ? ['avatar'] : []),
            ],
          },
        },
      });
      return updated;
    });

    return res.json({
      message: 'Profil berhasil diperbarui',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        avatar: user.avatar
      }
    });
  } catch (error) {
    logError('profile.update_failed', error);
    return res.status(500).json({ message: 'Gagal memperbarui profil' });
  }
};

export const changePassword = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Sesi tidak valid' });
    }

    const oldPassword = readPassword(req.body.oldPassword);
    const newPassword = readPassword(req.body.newPassword);

    if (!oldPassword || !newPassword) {
      return res.status(400).json({
        message: 'Password lama dan password baru wajib diisi'
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ message: 'Password baru minimal 8 karakter' });
    }

    if (newPassword.length > 72) {
      return res.status(400).json({ message: 'Password baru maksimal 72 karakter' });
    }

    if (oldPassword === newPassword) {
      return res.status(400).json({
        message: 'Password baru harus berbeda dari password lama'
      });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ message: 'Pengguna tidak ditemukan' });
    }

    const isPasswordValid = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(400).json({ message: 'Password lama tidak sesuai' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: { passwordHash }
      }),
      prisma.session.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() }
      }),
      prisma.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'PASSWORD_CHANGED',
          resourceType: 'USER',
          resourceId: userId,
          requestId: res.locals.requestId,
        },
      })
    ]);

    return res.json({ message: 'Password berhasil diubah. Silakan masuk kembali.' });
  } catch (error) {
    logError('auth.password_change_failed', error);
    return res.status(500).json({ message: 'Gagal mengubah password' });
  }
};

export const refreshSession = async (req: Request, res: Response) => {
  try {
    const tokens = await rotateSession(req.body.refreshToken);
    if (!tokens) {
      return res.status(401).json({ message: 'Refresh token tidak valid atau kedaluwarsa' });
    }
    return res.json(tokens);
  } catch (error) {
    logError('auth.session_refresh_failed', error);
    return res.status(500).json({ message: 'Gagal memperbarui sesi' });
  }
};

export const logout = async (req: AuthRequest, res: Response) => {
  if (!req.user?.sessionId) {
    return res.status(401).json({ message: 'Sesi tidak valid' });
  }
  await prisma.$transaction([
    prisma.session.updateMany({
      where: { id: req.user.sessionId, userId: req.user.userId },
      data: { revokedAt: new Date() },
    }),
    prisma.auditLog.create({
      data: {
        actorUserId: req.user.userId,
        action: 'LOGOUT',
        resourceType: 'SESSION',
        resourceId: req.user.sessionId,
        requestId: res.locals.requestId,
      },
    }),
  ]);
  return res.json({ message: 'Logout berhasil' });
};

export const getSessions = async (req: AuthRequest, res: Response) => {
  const sessions = await prisma.session.findMany({
    where: { userId: req.user!.userId, revokedAt: null, expiresAt: { gt: new Date() } },
    select: { id: true, deviceName: true, createdAt: true, updatedAt: true },
    orderBy: { updatedAt: 'desc' },
  });
  return res.json(sessions.map((session) => ({
    ...session,
    current: session.id === req.user!.sessionId,
  })));
};

export const revokeSession = async (req: AuthRequest, res: Response) => {
  const id = req.params.id as string;
  const revoked = await prisma.$transaction(async (tx) => {
    const result = await tx.session.updateMany({
      where: { id, userId: req.user!.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (result.count) {
      await tx.auditLog.create({
        data: {
          actorUserId: req.user!.userId,
          action: 'SESSION_REVOKED',
          resourceType: 'SESSION',
          resourceId: id,
          requestId: res.locals.requestId,
        },
      });
    }
    return result;
  });
  if (!revoked.count) {
    return res.status(404).json({ message: 'Sesi tidak ditemukan' });
  }
  return res.json({ message: 'Sesi berhasil dicabut' });
};

export const requestPasswordReset = async (req: Request, res: Response) => {
  const email = normalizeEmail(req.body.email);
  const user = EMAIL_PATTERN.test(email)
    ? await prisma.user.findUnique({ where: { email }, select: { id: true } })
    : null;

  let resetToken: string | undefined;
  if (user) {
    const generated = createPasswordResetToken();
    const reset = await prisma.$transaction(async (tx) => {
      await tx.passwordResetToken.deleteMany({
        where: { userId: user.id, usedAt: null },
      });
      return tx.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash: generated.tokenHash,
          expiresAt: generated.expiresAt,
        },
      });
    });
    if (process.env.NODE_ENV !== 'production') {
      resetToken = generated.token;
    } else {
      try {
        await sendPasswordResetEmail({
          to: email,
          token: generated.token,
          idempotencyKey: reset.id,
        });
      } catch (error) {
        await prisma.passwordResetToken.delete({ where: { id: reset.id } });
        logError('email.password_reset_failed', error);
      }
    }
  }

  return res.json({
    message: 'Jika email terdaftar, instruksi reset password akan dikirim.',
    ...(resetToken ? { resetToken } : {}),
  });
};

export const resetPassword = async (req: Request, res: Response) => {
  const token = typeof req.body.token === 'string' ? req.body.token : '';
  const password = readPassword(req.body.password);
  if (password.length < 8 || password.length > 72) {
    return res.status(400).json({ message: 'Password harus terdiri dari 8-72 karakter' });
  }

  const reset = token
    ? await prisma.passwordResetToken.findUnique({
        where: { tokenHash: hashPasswordResetToken(token) },
      })
    : null;
  if (!reset || reset.usedAt || reset.expiresAt <= new Date()) {
    return res.status(400).json({ message: 'Token reset tidak valid atau kedaluwarsa' });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const changed = await prisma.$transaction(async (tx) => {
    const consumed = await tx.passwordResetToken.updateMany({
      where: { id: reset.id, usedAt: null, expiresAt: { gt: new Date() } },
      data: { usedAt: new Date() },
    });
    if (consumed.count !== 1) return false;
    await tx.user.update({
      where: { id: reset.userId },
      data: { passwordHash },
    });
    await tx.session.updateMany({
      where: { userId: reset.userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    await tx.auditLog.create({
      data: {
        actorUserId: reset.userId,
        action: 'PASSWORD_RESET',
        resourceType: 'USER',
        resourceId: reset.userId,
        requestId: res.locals.requestId,
      },
    });
    return true;
  });

  return changed
    ? res.json({ message: 'Password berhasil direset. Silakan masuk kembali.' })
    : res.status(400).json({ message: 'Token reset tidak valid atau kedaluwarsa' });
};

export const deleteAccount = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.userId;
    const password = readPassword(req.body.password);

    if (!userId) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    if (!password) {
      res.status(400).json({ message: 'Password wajib diisi' });
      return;
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !await bcrypt.compare(password, user.passwordHash)) {
      res.status(401).json({ message: 'Password tidak sesuai' });
      return;
    }

    await prisma.$transaction(async (tx) => {
      await tx.auditLog.create({
        data: {
          actorUserId: userId,
          action: 'ACCOUNT_DELETED',
          resourceType: 'USER',
          resourceId: userId,
          requestId: res.locals.requestId,
        },
      });
      await tx.transaction.deleteMany({ where: { userId } });
      await tx.recurringBill.deleteMany({ where: { userId } });
      await tx.budget.deleteMany({ where: { userId } });
      await tx.wallet.deleteMany({ where: { userId } });
      await tx.user.delete({ where: { id: userId } });
    });

    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    logError('account.delete_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
