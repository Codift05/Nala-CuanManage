import cron from 'node-cron';
import prisma from '../utils/prisma';
import {
  recurringDueDays,
  recurringIdempotencyKey,
  recurringPeriod,
} from '../utils/idempotency';

export const processRecurringBills = async (runAt = new Date()) => {
  const bills = await prisma.recurringBill.findMany({
    where: { dueDate: { in: recurringDueDays(runAt) } },
  });
  const period = recurringPeriod(runAt);
  let processed = 0;
  let skipped = 0;
  let failed = 0;

  for (const bill of bills) {
    try {
      await prisma.$transaction(async (tx) => {
        const execution = await tx.recurringExecution.create({
          data: { recurringBillId: bill.id, period },
        });

        const transaction = await tx.transaction.create({
          data: {
            userId: bill.userId,
            walletId: bill.walletId,
            type: 'EXPENSE',
            amount: bill.amount,
            categoryId: bill.categoryId,
            merchant: bill.title,
            notes: 'Dibuat otomatis dari tagihan berulang',
            idempotencyKey: recurringIdempotencyKey(bill.id, runAt),
            date: runAt,
          },
        });

        await tx.wallet.update({
          where: { id: bill.walletId },
          data: { balance: { decrement: bill.amount } },
        });

        await tx.recurringExecution.update({
          where: { id: execution.id },
          data: { transactionId: transaction.id },
        });
      });
      processed++;
    } catch (error) {
      if ((error as { code?: string }).code === 'P2002') {
        skipped++;
        continue;
      }
      failed++;
      console.error(`[CRON] Failed to process bill ${bill.id}:`, error);
    }
  }

  return { found: bills.length, processed, skipped, failed };
};

// Run every day at 00:00 (Midnight)
export const initRecurringJob = () => {
  cron.schedule('0 0 * * *', async () => {
    console.log('[CRON] Running recurring bills check...');
    try {
      const result = await processRecurringBills();
      console.log('[CRON] Recurring bills check completed:', result);
    } catch (error) {
      console.error('[CRON] Error running recurring bills job:', error);
    }
  });

  console.log('[CRON] Recurring job scheduler initialized.');
};
