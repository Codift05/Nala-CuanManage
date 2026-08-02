import { Request, Response } from 'express';
import prisma from '../utils/prisma';
import { parseRupiah } from '../utils/money';
import { parseText, parseWalletType } from '../utils/resourceInput';
import { logError } from '../utils/logger';

export const createWallet = async (req: Request, res: Response) => {
  try {
    const { name, type, balance } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const walletName = parseText(name, 80);
    const walletType = parseWalletType(type);
    if (!walletName || !walletType) {
      return res.status(400).json({ message: 'Name and type are required' });
    }

    const initialBalance = parseRupiah(balance ?? 0, { allowZero: true });
    if (initialBalance === null) {
      return res.status(400).json({ message: 'Saldo harus berupa rupiah bulat yang valid' });
    }

    const wallet = await prisma.wallet.create({
      data: {
        userId,
        name: walletName,
        type: walletType,
        balance: initialBalance
      }
    });

    res.status(201).json({ message: 'Wallet created successfully', wallet });
  } catch (error) {
    logError('wallet.create_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getWallets = async (req: Request, res: Response) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const wallets = await prisma.wallet.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' }
    });

    res.json(wallets);
  } catch (error) {
    logError('wallet.list_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getWalletById = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const wallet = await prisma.wallet.findFirst({
      where: { id, userId }
    });

    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    res.json(wallet);
  } catch (error) {
    logError('wallet.get_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateWallet = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { name, type, balance } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (balance !== undefined) {
      return res.status(400).json({
        message: 'Saldo tidak dapat diubah langsung; gunakan transaksi'
      });
    }

    const wallet = await prisma.wallet.findFirst({
      where: { id, userId }
    });

    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    const walletName = name === undefined ? wallet.name : parseText(name, 80);
    const walletType = type === undefined ? wallet.type : parseWalletType(type);
    if (!walletName || !walletType) {
      return res.status(400).json({ message: 'Name or type is invalid' });
    }

    const updatedWallet = await prisma.wallet.update({
      where: { id },
      data: {
        name: walletName,
        type: walletType
      }
    });

    res.json({ message: 'Wallet updated successfully', wallet: updatedWallet });
  } catch (error) {
    logError('wallet.update_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteWallet = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const wallet = await prisma.wallet.findFirst({
      where: { id, userId }
    });

    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    await prisma.wallet.delete({
      where: { id }
    });

    res.json({ message: 'Wallet deleted successfully' });
  } catch (error) {
    logError('wallet.delete_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
