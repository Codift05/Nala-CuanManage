import { Request, Response } from 'express';
import prisma from '../utils/prisma';

export const createTransaction = async (req: Request, res: Response) => {
  try {
    const { walletId, type, amount, categoryId, merchant, notes, date } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!walletId || !type || amount === undefined) {
      return res.status(400).json({ message: 'walletId, type, and amount are required' });
    }

    if (type !== 'INCOME' && type !== 'EXPENSE') {
      return res.status(400).json({ message: 'type must be INCOME or EXPENSE' });
    }

    // Verify wallet belongs to user
    const wallet = await prisma.wallet.findFirst({
      where: { id: walletId, userId }
    });

    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    // Determine the balance change
    const numericAmount = Number(amount);
    if (isNaN(numericAmount) || numericAmount <= 0) {
      return res.status(400).json({ message: 'amount must be a positive number' });
    }

    const balanceChange = type === 'INCOME' ? numericAmount : -numericAmount;

    // Use a transaction to ensure both operations succeed or fail together
    const [transaction, updatedWallet] = await prisma.$transaction([
      prisma.transaction.create({
        data: {
          userId,
          walletId,
          type,
          amount: numericAmount,
          categoryId,
          merchant,
          notes,
          date: date ? new Date(date) : undefined
        }
      }),
      prisma.wallet.update({
        where: { id: walletId },
        data: {
          balance: {
            increment: balanceChange
          }
        }
      })
    ]);

    res.status(201).json({ message: 'Transaction created successfully', transaction, wallet: updatedWallet });
  } catch (error) {
    console.error('Create transaction error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getTransactions = async (req: Request, res: Response) => {
  try {
    const userId = req.userId;
    const { walletId, type, categoryId, limit } = req.query;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const whereClause: any = { userId };

    if (walletId) whereClause.walletId = String(walletId);
    if (type) whereClause.type = String(type);
    if (categoryId) whereClause.categoryId = String(categoryId);

    const transactions = await prisma.transaction.findMany({
      where: whereClause,
      orderBy: { date: 'desc' },
      take: limit ? Number(limit) : undefined,
      include: {
        wallet: {
          select: { name: true, type: true }
        }
      }
    });

    res.json(transactions);
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getTransactionById = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const transaction = await prisma.transaction.findFirst({
      where: { id, userId },
      include: {
        wallet: {
          select: { name: true, type: true }
        }
      }
    });

    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    res.json(transaction);
  } catch (error) {
    console.error('Get transaction error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteTransaction = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const transaction = await prisma.transaction.findFirst({
      where: { id, userId }
    });

    if (!transaction) {
      return res.status(404).json({ message: 'Transaction not found' });
    }

    // Revert the balance change
    const balanceChange = transaction.type === 'INCOME' ? -transaction.amount : transaction.amount;

    await prisma.$transaction([
      prisma.transaction.delete({
        where: { id }
      }),
      prisma.wallet.update({
        where: { id: transaction.walletId },
        data: {
          balance: {
            increment: balanceChange
          }
        }
      })
    ]);

    res.json({ message: 'Transaction deleted successfully' });
  } catch (error) {
    console.error('Delete transaction error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
