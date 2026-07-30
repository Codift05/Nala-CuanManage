import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';

const JWT_SECRET = process.env.JWT_SECRET || 'nala_super_secret_key_2026';
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

    if (name.length < 2) {
      return res.status(400).json({ message: 'Nama minimal 2 karakter' });
    }

    if (!EMAIL_PATTERN.test(email)) {
      return res.status(400).json({ message: 'Format email tidak valid' });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: 'Password minimal 8 karakter' });
    }

    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(409).json({ message: 'Email sudah terdaftar' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

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

      return createdUser;
    });

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, {
      expiresIn: '7d'
    });

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
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

    const token = jwt.sign({ userId: user.id }, JWT_SECRET, {
      expiresIn: '7d'
    });

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
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
    console.error('Get current user error:', error);
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

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        name,
        email,
        ...(avatar !== undefined ? { avatar } : {})
      }
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
    console.error('Update profile error:', error);
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
    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash }
    });

    return res.json({ message: 'Password berhasil diubah' });
  } catch (error) {
    console.error('Change password error:', error);
    return res.status(500).json({ message: 'Gagal mengubah password' });
  }
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
      await tx.transaction.deleteMany({ where: { userId } });
      await tx.recurringBill.deleteMany({ where: { userId } });
      await tx.budget.deleteMany({ where: { userId } });
      await tx.wallet.deleteMany({ where: { userId } });
      await tx.user.delete({ where: { id: userId } });
    });

    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
