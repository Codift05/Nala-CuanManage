import assert from 'node:assert/strict';
import prisma from '../src/utils/prisma';
import { processRecurringBills } from '../src/cron/recurringJob';
import {
  recurringIdempotencyKey,
  recurringPeriod,
} from '../src/utils/idempotency';

const run = async () => {
  const user = await prisma.user.findUnique({
    where: { email: 'admin@nala.com' },
    include: { wallets: { take: 1 } },
  });
  const wallet = user?.wallets[0];
  if (!user || !wallet) throw new Error('Development user/wallet not found');

  const usedDays = new Set(
    (await prisma.recurringBill.findMany({ select: { dueDate: true } }))
      .map((bill) => bill.dueDate),
  );
  const dueDate = Array.from({ length: 28 }, (_, index) => index + 1)
    .find((day) => !usedDays.has(day));
  if (!dueDate) throw new Error('No unused recurring due date for test');

  const runAt = new Date(2026, 6, dueDate, 12);
  const bill = await prisma.recurringBill.create({
    data: {
      userId: user.id,
      walletId: wallet.id,
      title: 'Recurring idempotency test',
      amount: 321n,
      categoryId: 'Others',
      dueDate,
    },
  });
  const key = recurringIdempotencyKey(bill.id, runAt);

  try {
    const first = await processRecurringBills(runAt);
    const second = await processRecurringBills(runAt);
    const transactions = await prisma.transaction.findMany({
      where: { userId: user.id, idempotencyKey: key },
    });
    const execution = await prisma.recurringExecution.findUnique({
      where: {
        recurringBillId_period: {
          recurringBillId: bill.id,
          period: recurringPeriod(runAt),
        },
      },
    });
    const updatedWallet = await prisma.wallet.findUniqueOrThrow({
      where: { id: wallet.id },
    });

    assert.equal(first.processed, 1);
    assert.equal(second.skipped, 1);
    assert.equal(transactions.length, 1);
    assert.equal(execution?.transactionId, transactions[0]?.id);
    assert.equal(updatedWallet.balance, wallet.balance - 321n);

    await prisma.$transaction([
      prisma.transaction.delete({ where: { id: transactions[0]!.id } }),
      prisma.wallet.update({
        where: { id: wallet.id },
        data: { balance: { increment: 321n } },
      }),
    ]);
    const third = await processRecurringBills(runAt);
    const retainedExecution = await prisma.recurringExecution.findUnique({
      where: {
        recurringBillId_period: {
          recurringBillId: bill.id,
          period: recurringPeriod(runAt),
        },
      },
    });
    const finalWallet = await prisma.wallet.findUniqueOrThrow({
      where: { id: wallet.id },
    });

    assert.equal(third.skipped, 1);
    assert.equal(retainedExecution?.transactionId, null);
    assert.equal(finalWallet.balance, wallet.balance);
    console.log('Recurring integration test passed');
  } finally {
    const transaction = await prisma.transaction.findFirst({
      where: { userId: user.id, idempotencyKey: key },
    });
    await prisma.$transaction(async (tx) => {
      await tx.recurringExecution.deleteMany({
        where: { recurringBillId: bill.id },
      });
      if (transaction) {
        await tx.transaction.delete({ where: { id: transaction.id } });
        await tx.wallet.update({
          where: { id: wallet.id },
          data: { balance: { increment: transaction.amount } },
        });
      }
      await tx.recurringBill.delete({ where: { id: bill.id } });
    });
    await prisma.$disconnect();
  }
};

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
