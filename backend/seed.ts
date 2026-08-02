import { PrismaClient } from './generated/prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';
import 'dotenv/config';
import { buildDemoData } from './src/demo/demoData';

const openingBalances = { cash: 1_200_000, gopay: 850_000, bank: 200_000 };

async function main() {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Demo seed is disabled in production');
  }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({ adapter } as any);
  const passwordHash = await bcrypt.hash('password123', 10);
  const now = new Date();
  const demo = buildDemoData(now);

  const user = await prisma.user.upsert({
    where: { email: 'admin@nala.com' },
    update: {
      name: 'Miftah',
      passwordHash,
      emailVerifiedAt: now,
    },
    create: {
      name: 'Miftah',
      email: 'admin@nala.com',
      passwordHash,
      emailVerifiedAt: now,
    },
  });

  const ensureWallet = async (name: string, type: string) =>
    await prisma.wallet.findFirst({ where: { userId: user.id, name, type } }) ??
    prisma.wallet.create({ data: { userId: user.id, name, type, balance: 0 } });

  const wallets = {
    cash: await ensureWallet('Tunai', 'CASH'),
    gopay: await ensureWallet('GoPay', 'EWALLET'),
    bank: await ensureWallet('Bank Jago', 'BANK'),
  };

  // admin@nala.com khusus demo: reset data finansialnya agar screenshot selalu
  // konsisten. Akun pengguna lain tidak pernah disentuh oleh seed ini.
  await prisma.recurringBill.deleteMany({ where: { userId: user.id } });
  await prisma.transaction.deleteMany({ where: { userId: user.id } });
  await prisma.habitScoreSnapshot.deleteMany({ where: { userId: user.id } });
  await prisma.wallet.deleteMany({
    where: {
      userId: user.id,
      name: { in: ['Cash', 'Dompet Utama'] },
      transactions: { none: {} },
      recurringBills: { none: {} },
    },
  });

  for (const budget of demo.budgets) {
    const date = new Date(now.getFullYear(), now.getMonth() + budget.monthOffset, 1);
    await prisma.budget.upsert({
      where: {
        userId_categoryId_month_year: {
          userId: user.id,
          categoryId: budget.categoryId,
          month: date.getMonth() + 1,
          year: date.getFullYear(),
        },
      },
      update: { amount: budget.amount },
      create: {
        userId: user.id,
        categoryId: budget.categoryId,
        amount: budget.amount,
        month: date.getMonth() + 1,
        year: date.getFullYear(),
      },
    });
  }

  for (const bill of demo.recurringBills) {
    await prisma.recurringBill.create({
      data: {
        userId: user.id,
        walletId: wallets[bill.wallet].id,
        title: bill.title,
        amount: bill.amount,
        categoryId: bill.categoryId,
        dueDate: bill.dueDate,
      },
    });
  }

  for (const transaction of demo.transactions) {
    await prisma.transaction.upsert({
      where: {
        userId_idempotencyKey: {
          userId: user.id,
          idempotencyKey: transaction.key,
        },
      },
      update: {
        walletId: wallets[transaction.wallet].id,
        type: transaction.type,
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        merchant: transaction.merchant,
        notes: transaction.notes,
        date: transaction.date,
      },
      create: {
        userId: user.id,
        walletId: wallets[transaction.wallet].id,
        idempotencyKey: transaction.key,
        type: transaction.type,
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        merchant: transaction.merchant,
        notes: transaction.notes,
        date: transaction.date,
      },
    });
  }

  for (const [key, wallet] of Object.entries(wallets)) {
    const transactions = await prisma.transaction.findMany({
      where: { userId: user.id, walletId: wallet.id },
      select: { type: true, amount: true },
    });
    const movement = transactions.reduce(
      (sum, item) => sum + (item.type === 'INCOME' ? item.amount : -item.amount),
      0n,
    );
    await prisma.wallet.update({
      where: { id: wallet.id },
      data: { balance: BigInt(openingBalances[key as keyof typeof openingBalances]) + movement },
    });
  }

  console.log(`Demo ready: ${user.email}, ${demo.transactions.length} transactions`);
  await prisma.$disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
