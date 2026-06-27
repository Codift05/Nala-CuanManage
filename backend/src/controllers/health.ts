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

    const now = new Date();
    const monthRanges = [-2, -1, 0].map((offset) => getMonthRange(now, offset));
    const currentRange = monthRanges[2]!;
    const trend = [];

    const wallets = await prisma.wallet.findMany({
      where: { userId },
      select: { type: true, balance: true },
    });

    for (const range of monthRanges) {
      const [transactions, budgets] = await Promise.all([
        prisma.transaction.findMany({
          where: {
            userId,
            date: { gte: range.start, lt: range.end },
          },
          select: { type: true, amount: true, categoryId: true, date: true },
        }),
        prisma.budget.findMany({
          where: { userId, month: range.month, year: range.year },
          select: { amount: true },
        }),
      ]);

      const totalBudget = budgets.reduce((sum, budget) => sum + Number(budget.amount), 0);
      const score = calculateScore(transactions, wallets, totalBudget, range.start, range.end);

      trend.push({
        label: monthNames[range.start.getMonth()],
        month: range.month,
        year: range.year,
        score: score.score,
      });
    }

    const currentTransactions = await prisma.transaction.findMany({
      where: {
        userId,
        date: { gte: currentRange.start, lt: currentRange.end },
      },
      orderBy: { date: 'desc' },
      select: { type: true, amount: true, categoryId: true, date: true },
    });
    const currentBudgets = await prisma.budget.findMany({
      where: { userId, month: currentRange.month, year: currentRange.year },
      select: { amount: true },
    });

    const totalBudget = currentBudgets.reduce((sum, budget) => sum + Number(budget.amount), 0);
    const currentScore = calculateScore(
      currentTransactions,
      wallets,
      totalBudget,
      currentRange.start,
      currentRange.end
    );
    const { status, nudgeMessage } = getStatus(currentScore.score);

    const previousTrend = trend.length > 1 ? trend[trend.length - 2] : undefined;
    const previousScore = previousTrend?.score ?? currentScore.score;
    const delta = currentScore.score - previousScore;
    const trendMessage = delta === 0
      ? 'Stabil dari bulan lalu'
      : `${delta > 0 ? 'Naik' : 'Turun'} ${Math.abs(delta)} poin dari bulan lalu`;

    res.json({
      score: currentScore.score,
      status,
      nudgeMessage,
      totalIncome: currentScore.totalIncome,
      totalExpense: currentScore.totalExpense,
      totalBudget: currentScore.totalBudget,
      transactionCount: currentScore.transactionCount,
      updatedAt: new Date().toISOString(),
      details: [
        { key: 'savingRatio', label: 'Rasio Tabungan', score: currentScore.savingRatioScore },
        { key: 'budgetCompliance', label: 'Kepatuhan Budget', score: currentScore.budgetComplianceScore },
        { key: 'consistency', label: 'Konsistensi Catat', score: currentScore.consistencyScore },
        { key: 'diversification', label: 'Diversifikasi', score: currentScore.diversificationScore },
      ],
      trend: {
        labels: trend.map((item) => item.label),
        scores: trend.map((item) => item.score),
        normalized: trend.map((item) => item.score / 100),
        delta,
        message: trendMessage,
      },
    });
  } catch (error) {
    console.error('Error calculating health score:', error);
    res.status(500).json({ error: 'Failed to calculate health score' });
  }
};
