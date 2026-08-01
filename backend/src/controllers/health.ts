import { Response } from 'express';
import prisma from '../utils/prisma';
import { AuthRequest } from '../middleware/auth';
import { calculateHabitScore, describeHabitScore } from '../utils/habitScore';

const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

const getMonthRange = (baseDate: Date, offset = 0) => {
  const start = new Date(baseDate.getFullYear(), baseDate.getMonth() + offset, 1);
  const end = new Date(baseDate.getFullYear(), baseDate.getMonth() + offset + 1, 1);
  return { start, end, month: start.getMonth() + 1, year: start.getFullYear() };
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
    const trend = [];

    for (const range of monthRanges) {
      const [transactions, budgets] = await Promise.all([
        prisma.transaction.findMany({
          where: {
            userId,
            date: { gte: range.start, lt: range.end },
          },
          select: { type: true, amount: true, date: true },
        }),
        prisma.budget.findMany({
          where: { userId, month: range.month, year: range.year },
          select: { amount: true },
        }),
      ]);

      const totalBudget = budgets.reduce((sum, budget) => sum + Number(budget.amount), 0);
      const breakdown = calculateHabitScore(
        transactions,
        totalBudget,
        range.start,
        range.end,
        now,
      );

      trend.push({
        label: monthNames[range.start.getMonth()],
        month: range.month,
        year: range.year,
        score: breakdown.score,
        breakdown,
      });
    }

    const currentScore = trend[2]!.breakdown;
    const { status, nudgeMessage } = describeHabitScore(currentScore.score);

    const previousTrend = trend.length > 1 ? trend[trend.length - 2] : undefined;
    const previousScore = previousTrend?.score;
    const delta = currentScore.score !== null && previousScore != null
      ? currentScore.score - previousScore
      : null;
    const trendMessage = currentScore.score === null
      ? 'Belum cukup data bulan ini'
      : delta === null
        ? 'Belum ada pembanding bulan lalu'
        : delta === 0
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
      methodology: 'habit-score-v2',
      updatedAt: new Date().toISOString(),
      details: currentScore.factors,
      actions: currentScore.actions,
      trend: {
        labels: trend.map((item) => item.label),
        scores: trend.map((item) => item.score),
        normalized: trend.map((item) => item.score === null ? null : item.score / 100),
        delta,
        message: trendMessage,
      },
    });
  } catch (error) {
    console.error('Error calculating health score:', error);
    res.status(500).json({ error: 'Failed to calculate health score' });
  }
};
