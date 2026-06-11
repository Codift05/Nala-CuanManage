import { Request, Response } from 'express';
import prisma from '../utils/prisma';

export const createWallet = async (req: Request, res: Response) => {
  try {
    const { name, type, balance } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!name || !type) {
      return res.status(400).json({ message: 'Name and type are required' });
    }

    const wallet = await prisma.wallet.create({
      data: {
        userId,
        name,
        type,
        balance: balance || 0
      }
    });

    res.status(201).json({ message: 'Wallet created successfully', wallet });
  } catch (error) {
    console.error('Create wallet error:', error);
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
    console.error('Get wallets error:', error);
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
    console.error('Get wallet error:', error);
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

    const wallet = await prisma.wallet.findFirst({
      where: { id, userId }
    });

    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    const updatedWallet = await prisma.wallet.update({
      where: { id },
      data: {
        name: name !== undefined ? name : wallet.name,
        type: type !== undefined ? type : wallet.type,
        balance: balance !== undefined ? balance : wallet.balance
      }
    });

    res.json({ message: 'Wallet updated successfully', wallet: updatedWallet });
  } catch (error) {
    console.error('Update wallet error:', error);
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
    console.error('Delete wallet error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
