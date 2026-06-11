import { Request, Response } from 'express';
import prisma from '../utils/prisma';

export const createBudget = async (req: Request, res: Response) => {
  try {
    const { categoryId, amount, month, year } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    if (!categoryId || amount === undefined || !month || !year) {
      return res.status(400).json({ message: 'categoryId, amount, month, and year are required' });
    }

    const numericAmount = Number(amount);
    if (isNaN(numericAmount) || numericAmount < 0) {
      return res.status(400).json({ message: 'amount must be a positive number' });
    }

    // Check if budget for this category, month, and year already exists
    const existingBudget = await prisma.budget.findUnique({
      where: {
        userId_categoryId_month_year: {
          userId,
          categoryId,
          month: Number(month),
          year: Number(year)
        }
      }
    });

    if (existingBudget) {
      return res.status(400).json({ message: 'Budget for this category and month already exists. Please update it instead.' });
    }

    const budget = await prisma.budget.create({
      data: {
        userId,
        categoryId,
        amount: numericAmount,
        month: Number(month),
        year: Number(year)
      }
    });

    res.status(201).json({ message: 'Budget created successfully', budget });
  } catch (error) {
    console.error('Create budget error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const getBudgets = async (req: Request, res: Response) => {
  try {
    const userId = req.userId;
    const { month, year } = req.query;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const whereClause: any = { userId };

    if (month) whereClause.month = Number(month);
    if (year) whereClause.year = Number(year);

    const budgets = await prisma.budget.findMany({
      where: whereClause,
      orderBy: [
        { year: 'desc' },
        { month: 'desc' }
      ]
    });

    res.json(budgets);
  } catch (error) {
    console.error('Get budgets error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const updateBudget = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { amount } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const budget = await prisma.budget.findFirst({
      where: { id, userId }
    });

    if (!budget) {
      return res.status(404).json({ message: 'Budget not found' });
    }

    const numericAmount = Number(amount);
    if (isNaN(numericAmount) || numericAmount < 0) {
      return res.status(400).json({ message: 'amount must be a positive number' });
    }

    const updatedBudget = await prisma.budget.update({
      where: { id },
      data: { amount: numericAmount }
    });

    res.json({ message: 'Budget updated successfully', budget: updatedBudget });
  } catch (error) {
    console.error('Update budget error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

export const deleteBudget = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const budget = await prisma.budget.findFirst({
      where: { id, userId }
    });

    if (!budget) {
      return res.status(404).json({ message: 'Budget not found' });
    }

    await prisma.budget.delete({
      where: { id }
    });

    res.json({ message: 'Budget deleted successfully' });
  } catch (error) {
    console.error('Delete budget error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
