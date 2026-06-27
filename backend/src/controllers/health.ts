import { Response } from 'express';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';

const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

type TransactionLike = {
  type: string;
  amount: number;
  categoryId: string | null;
  date: Date;
};

type WalletLike = {
  type: string;
  balance: number;
};

type ScoreBreakdown = {
  score: number;
  savingRatioScore: number;
  budgetComplianceScore: number;
  consistencyScore: number;
  diversificationScore: number;
  totalIncome: number;
  totalExpense: number;
  totalBudget: number;
  transactionCount: number;
};

const clampScore = (value: number): number => Math.min(100, Math.max(0, Math.round(value)));

const getMonthRange = (baseDate: Date, offset = 0) => {
  const start = new Date(baseDate.getFullYear(), baseDate.getMonth() + offset, 1);
  const end = new Date(baseDate.getFullYear(), baseDate.getMonth() + offset + 1, 1);
  return { start, end, month: start.getMonth() + 1, year: start.getFullYear() };
};

const calculateScore = (
  transactions: TransactionLike[],
  wallets: WalletLike[],
  totalBudget: number,
  rangeStart: Date,
  rangeEnd: Date
): ScoreBreakdown => {
  const incomeTransactions = transactions.filter((tx) => tx.type === 'INCOME');
  const expenseTransactions = transactions.filter((tx) => tx.type === 'EXPENSE');
  const totalIncome = incomeTransactions.reduce((sum, tx) => sum + Number(tx.amount), 0);
  const totalExpense = expenseTransactions.reduce((sum, tx) => sum + Number(tx.amount), 0);

  const savingRate = totalIncome > 0 ? Math.max(0, (totalIncome - totalExpense) / totalIncome) : 0;
  const savingRatioScore = totalIncome > 0
    ? clampScore((savingRate / 0.2) * 100)
    : totalExpense > 0
      ? 20
      : 70;

  let budgetComplianceScore = 60;
  if (totalBudget > 0) {
    const budgetUsage = totalExpense / totalBudget;
    budgetComplianceScore = budgetUsage <= 1
      ? clampScore(100 - (budgetUsage * 20))
      : clampScore(100 - ((budgetUsage - 1) * 100));
  }

  const activeDates = new Set(
    transactions.map((tx) => tx.date.toISOString().slice(0, 10))
  );
  const now = new Date();
  const elapsedDays = rangeEnd <= now
    ? Math.ceil((rangeEnd.getTime() - rangeStart.getTime()) / 86400000)
    : Math.max(1, now.getDate());
  const targetRecordDays = Math.max(4, Math.min(12, Math.ceil(elapsedDays * 0.45)));
  const consistencyScore = clampScore((activeDates.size / targetRecordDays) * 100);

  const categoryCount = new Set(
    expenseTransactions.map((tx) => tx.categoryId).filter(Boolean)
  ).size;
  const walletTypeCount = new Set(
    wallets.filter((wallet) => Number(wallet.balance) > 0).map((wallet) => wallet.type)
  ).size;
  const categoryScore = clampScore((categoryCount / 5) * 100);
  const walletScore = clampScore((walletTypeCount / 3) * 100);
  const diversificationScore = clampScore((categoryScore * 0.7) + (walletScore * 0.3));

  const score = clampScore(
    (savingRatioScore * 0.3) +
    (budgetComplianceScore * 0.3) +
    (consistencyScore * 0.2) +
    (diversificationScore * 0.2)
  );

  return {
    score,
    savingRatioScore,
    budgetComplianceScore,
    consistencyScore,
    diversificationScore,
    totalIncome,
    totalExpense,
    totalBudget,
    transactionCount: transactions.length,
  };
};

const getStatus = (score: number) => {
  if (score < 40) {
    return {
      status: 'Kritis',
      nudgeMessage: 'Pengeluaranmu lagi berat. Coba tahan transaksi non-prioritas dan cek ulang budget minggu ini.',
    };
  }
  if (score < 60) {
    return {
      status: 'Perlu Perhatian',
      nudgeMessage: 'Beberapa indikator mulai turun. Fokus jaga budget dan catat transaksi lebih rutin.',
    };
  }
  if (score < 80) {
    return {
      status: 'Cukup Sehat',
      nudgeMessage: 'Masih aman, tapi rasio tabungan dan kepatuhan budget masih bisa dinaikkan.',
    };
  }
  return {
    status: 'Sangat Sehat',
    nudgeMessage: 'Keuanganmu aman terkendali. Lanjutkan kebiasaan baik ini.',
  };
};

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
