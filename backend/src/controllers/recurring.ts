import { Request, Response } from 'express';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';
import { parseRupiah } from '../utils/money';
import { parsePeriodPart, parseText } from '../utils/resourceInput';
import { logError } from '../utils/logger';

export const createRecurringBill = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { title, amount, categoryId, walletId, dueDate } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const billTitle = parseText(title, 100);
    const category = parseText(categoryId, 50);
    const wallet = parseText(walletId, 100);
    const numericDueDate = parsePeriodPart(dueDate, 1, 31);
    if (!billTitle || amount === undefined || !category || !wallet || !numericDueDate) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    const numericAmount = parseRupiah(amount);
    if (numericAmount === null) {
      res.status(400).json({ error: 'Nominal harus berupa rupiah bulat yang valid' });
      return;
    }
    const ownedWallet = await prisma.wallet.findFirst({
      where: { id: wallet, userId },
      select: { id: true },
    });
    if (!ownedWallet) {
      res.status(404).json({ error: 'Wallet not found' });
      return;
    }

    const bill = await prisma.recurringBill.create({
      data: {
        userId,
        title: billTitle,
        amount: numericAmount,
        categoryId: category,
        walletId: wallet,
        dueDate: numericDueDate
      }
    });

    res.status(201).json({ message: 'Recurring bill created successfully', bill });
  } catch (error) {
    logError('recurring.create_failed', error);
    res.status(500).json({ error: 'Failed to create recurring bill' });
  }
};

export const getRecurringBills = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const bills = await prisma.recurringBill.findMany({
      where: { userId },
      include: {
        wallet: { select: { name: true } }
      },
      orderBy: { dueDate: 'asc' }
    });

    res.json(bills);
  } catch (error) {
    logError('recurring.list_failed', error);
    res.status(500).json({ error: 'Failed to get recurring bills' });
  }
};

export const deleteRecurringBill = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const deleted = await prisma.recurringBill.deleteMany({
      where: { id, userId }
    });
    if (!deleted.count) {
      res.status(404).json({ error: 'Recurring bill not found' });
      return;
    }

    res.json({ message: 'Recurring bill deleted successfully' });
  } catch (error) {
    logError('recurring.delete_failed', error);
    res.status(500).json({ error: 'Failed to delete recurring bill' });
  }
};
