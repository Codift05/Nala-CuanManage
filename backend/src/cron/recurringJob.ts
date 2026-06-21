import cron from 'node-cron';
import prisma from '../utils/prisma';

// Run every day at 00:00 (Midnight)
export const initRecurringJob = () => {
  cron.schedule('0 0 * * *', async () => {
    console.log('[CRON] Running recurring bills check...');
    try {
      const today = new Date().getDate(); // Gets the day of the month (1-31)

      const billsToProcess = await prisma.recurringBill.findMany({
        where: { dueDate: today }
      });

      if (billsToProcess.length === 0) {
        console.log('[CRON] No recurring bills due today.');
        return;
      }

      console.log(`[CRON] Found ${billsToProcess.length} bills to process.`);

      for (const bill of billsToProcess) {
        try {
          // Verify wallet still exists
          const wallet = await prisma.wallet.findUnique({ where: { id: bill.walletId } });

          if (!wallet) {
            console.warn(`[CRON] Wallet ${bill.walletId} for bill ${bill.id} not found. Skipping.`);
            continue;
          }

          // Create transaction and update wallet balance
          await prisma.$transaction([
            prisma.transaction.create({
              data: {
                userId: bill.userId,
                walletId: bill.walletId,
                type: 'EXPENSE',
                amount: bill.amount,
                categoryId: bill.categoryId,
                merchant: bill.title,
                notes: 'Auto-generated from Recurring Bill',
                date: new Date()
              }
            }),
            prisma.wallet.update({
              where: { id: bill.walletId },
              data: { balance: { decrement: bill.amount } }
            })
          ]);

          console.log(`[CRON] Successfully processed bill: ${bill.title} for user ${bill.userId}`);
        } catch (err) {
          console.error(`[CRON] Failed to process bill ${bill.id}:`, err);
        }
      }

      console.log('[CRON] Recurring bills processing completed.');
    } catch (error) {
      console.error('[CRON] Error running recurring bills job:', error);
    }
  });

  console.log('[CRON] Recurring job scheduler initialized.');
};
