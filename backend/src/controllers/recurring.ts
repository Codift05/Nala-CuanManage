import { Request, Response } from 'express';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';

export const createRecurringBill = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { title, amount, categoryId, walletId, dueDate } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    if (!title || !amount || !categoryId || !walletId || !dueDate) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    const bill = await prisma.recurringBill.create({
      data: {
        userId,
        title,
        amount: Number(amount),
        categoryId,
        walletId,
        dueDate: Number(dueDate)
      }
    });

    res.status(201).json({ message: 'Recurring bill created successfully', bill });
  } catch (error) {
    console.error('Create recurring bill error:', error);
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
    console.error('Get recurring bills error:', error);
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

    await prisma.recurringBill.deleteMany({
      where: { id, userId }
    });

    res.json({ message: 'Recurring bill deleted successfully' });
  } catch (error) {
    console.error('Delete recurring bill error:', error);
    res.status(500).json({ error: 'Failed to delete recurring bill' });
  }
};
