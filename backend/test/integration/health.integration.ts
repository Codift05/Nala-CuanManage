import assert from 'node:assert/strict';
import { getHealthScore } from '../../src/controllers/health';
import prisma from '../../src/utils/prisma';

const run = async () => {
  const now = new Date();
  const period = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const user = await prisma.user.create({
    data: {
      email: `habit-score-${Date.now()}@nala.test`,
      name: 'Habit Score Integration',
      passwordHash: 'not-used-by-this-test',
    },
  });
  const wallet = await prisma.wallet.create({
    data: { userId: user.id, name: 'Test wallet', type: 'CASH' },
  });

  try {
    await prisma.$transaction([
      prisma.transaction.create({
        data: {
          userId: user.id,
          walletId: wallet.id,
          type: 'INCOME',
          amount: 5_000_000n,
          categoryId: 'Salary',
          date: now,
        },
      }),
      prisma.transaction.create({
        data: {
          userId: user.id,
          walletId: wallet.id,
          type: 'EXPENSE',
          amount: 1_000_000n,
          categoryId: 'Food',
          date: now,
        },
      }),
      prisma.budget.create({
        data: {
          userId: user.id,
          categoryId: 'Food',
          amount: 1_500_000n,
          month: now.getMonth() + 1,
          year: now.getFullYear(),
        },
      }),
      prisma.habitScoreSnapshot.create({
        data: {
          userId: user.id,
          period: '2020-01',
          methodology: 'habit-score-v1',
          score: 50,
          factors: [],
          actions: [],
          calculatedAt: new Date('2020-02-01T00:00:00.000Z'),
        },
      }),
    ]);

    let body: any;
    const response = {
      statusCode: 200,
      status(code: number) {
        this.statusCode = code;
        return this;
      },
      json(payload: unknown) {
        body = payload;
        return this;
      },
    };
    const request = { user: { userId: user.id, sessionId: 'integration-test' } };

    await getHealthScore(request as any, response as any);
    await getHealthScore(request as any, response as any);

    const snapshots = await prisma.habitScoreSnapshot.findMany({
      where: { userId: user.id },
    });
    assert.equal(response.statusCode, 200);
    assert.equal(body.methodology, 'habit-score-v2');
    assert.equal(typeof body.score, 'number');
    assert.equal(body.history.length, 1);
    assert.equal(body.history[0].period, period);
    assert.equal(snapshots.length, 1, 'recalculation must update, not duplicate');
    assert.equal(snapshots[0]?.period, period);
    assert.equal(snapshots[0]?.methodology, 'habit-score-v2');
    console.log('Health score snapshot integration test passed');
  } finally {
    await prisma.$transaction([
      prisma.habitScoreSnapshot.deleteMany({ where: { userId: user.id } }),
      prisma.transaction.deleteMany({ where: { userId: user.id } }),
      prisma.budget.deleteMany({ where: { userId: user.id } }),
      prisma.wallet.deleteMany({ where: { userId: user.id } }),
      prisma.user.delete({ where: { id: user.id } }),
    ]);
    await prisma.$disconnect();
  }
};

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
