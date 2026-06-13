import { Response } from 'express';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';

export const getHealthScore = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    // Get all budgets for the user
    const budgets = await prisma.budget.findMany({
      where: { userId }
    });

    const totalBudget = budgets.reduce((sum, b) => sum + Number(b.amount), 0);

    // Get current month's transactions
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    const transactions = await prisma.transaction.findMany({
      where: {
        wallet: { userId },
        type: 'EXPENSE',
        date: { gte: startOfMonth }
      }
    });

    const totalExpense = transactions.reduce((sum, tx) => sum + Number(tx.amount), 0);

    let score = 100;
    
    if (totalBudget > 0) {
      const expenseRatio = totalExpense / totalBudget;
      
      if (expenseRatio > 1) {
        score = Math.max(0, 100 - ((expenseRatio - 1) * 100)); // Drops if over budget
      } else {
        score = 100 - (expenseRatio * 20); // 80-100 range if under budget
      }
    } else {
      // If no budget, simple fallback: score depends on whether they have income vs expense
      const incomeTx = await prisma.transaction.findMany({
        where: { wallet: { userId }, type: 'INCOME', date: { gte: startOfMonth } }
      });
      const totalIncome = incomeTx.reduce((sum, tx) => sum + Number(tx.amount), 0);
      
      if (totalIncome > 0) {
        const ratio = totalExpense / totalIncome;
        score = ratio > 1 ? 40 : 100 - (ratio * 50);
      } else {
        score = totalExpense > 0 ? 30 : 85; // No income, but expenses = bad. Nothing = neutral 85
      }
    }

    // Ensure score is between 0 and 100
    score = Math.min(100, Math.max(0, Math.round(score)));

    let status = 'Sangat Sehat';
    let nudgeMessage = 'Keuanganmu aman terkendali! Lanjutkan kebiasaan baik ini. 🚀';
    
    if (score < 40) {
      status = 'Kritis';
      nudgeMessage = 'Waduh, pengeluaranmu udah over limit banget nih! Stop jajan dulu ya minggu ini! 🛑';
    } else if (score < 60) {
      status = 'Perlu Perhatian';
      nudgeMessage = 'Hati-hati, pengeluaranmu mulai mendekati batas budget! Ngerem dikit ya. ⚠️';
    } else if (score < 80) {
      status = 'Cukup Sehat';
      nudgeMessage = 'Masih aman, tapi jangan mentang-mentang ada sisa langsung dihabisin ya! 👀';
    }

    res.json({ score, status, totalExpense, totalBudget, nudgeMessage });
  } catch (error) {
    console.error('Error calculating health score:', error);
    res.status(500).json({ error: 'Failed to calculate health score' });
  }
};
