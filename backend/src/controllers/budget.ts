import { Request, Response } from 'express';
import prisma from '../utils/prisma';
import { parseRupiah } from '../utils/money';
import { parsePeriodPart, parseText } from '../utils/resourceInput';
import { logError } from '../utils/logger';

export const createBudget = async (req: Request, res: Response) => {
  try {
    const { categoryId, amount, month, year } = req.body;
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const category = parseText(categoryId, 50);
    const numericMonth = parsePeriodPart(month, 1, 12);
    const numericYear = parsePeriodPart(year, 2000, 2100);
    if (!category || amount === undefined || !numericMonth || !numericYear) {
      return res.status(400).json({ message: 'categoryId, amount, month, and year are required' });
    }

    const numericAmount = parseRupiah(amount, { allowZero: true });
    if (numericAmount === null) {
      return res.status(400).json({ message: 'amount must be a whole rupiah value' });
    }

    // Check if budget for this category, month, and year already exists
    const existingBudget = await prisma.budget.findUnique({
      where: {
        userId_categoryId_month_year: {
          userId,
          categoryId: category,
          month: numericMonth,
          year: numericYear
        }
      }
    });

    if (existingBudget) {
      return res.status(400).json({ message: 'Budget for this category and month already exists. Please update it instead.' });
    }

    const budget = await prisma.budget.create({
      data: {
        userId,
        categoryId: category,
        amount: numericAmount,
        month: numericMonth,
        year: numericYear
      }
    });

    res.status(201).json({ message: 'Budget created successfully', budget });
  } catch (error) {
    logError('budget.create_failed', error);
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

    const numericMonth = month === undefined ? undefined : parsePeriodPart(month, 1, 12);
    const numericYear = year === undefined ? undefined : parsePeriodPart(year, 2000, 2100);
    if (numericMonth === null || numericYear === null) {
      return res.status(400).json({ message: 'month or year is invalid' });
    }

    const whereClause: any = { userId };
    if (numericMonth) whereClause.month = numericMonth;
    if (numericYear) whereClause.year = numericYear;

    const budgets = await prisma.budget.findMany({
      where: whereClause,
      orderBy: [
        { year: 'desc' },
        { month: 'desc' }
      ]
    });

    res.json(budgets);
  } catch (error) {
    logError('budget.list_failed', error);
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

    const numericAmount = parseRupiah(amount, { allowZero: true });
    if (numericAmount === null) {
      return res.status(400).json({ message: 'amount must be a whole rupiah value' });
    }

    const updatedBudget = await prisma.budget.update({
      where: { id },
      data: { amount: numericAmount }
    });

    res.json({ message: 'Budget updated successfully', budget: updatedBudget });
  } catch (error) {
    logError('budget.update_failed', error);
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
    logError('budget.delete_failed', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
