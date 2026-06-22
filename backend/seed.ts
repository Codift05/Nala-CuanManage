import { PrismaClient } from './generated/prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import bcrypt from 'bcrypt';
import "dotenv/config";

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({ adapter } as any);

  const email = 'admin@nala.com';
  const password = 'password123';
  const passwordHash = await bcrypt.hash(password, 10);

  const user = await prisma.user.upsert({
    where: { email },
    update: {},
    create: {
      name: 'Nala Admin',
      email,
      passwordHash,
    },
  });

  console.log('Development user ready:', user.email);

  // 2. Create Wallets
  const cashWallet = await prisma.wallet.findFirst({
    where: { userId: user.id, name: 'Cash', type: 'CASH' }
  }) ?? await prisma.wallet.create({
      data: {
        userId: user.id,
        name: 'Cash',
        type: 'CASH',
        balance: 1500000,
      }
    });

  const gopayWallet = await prisma.wallet.findFirst({
    where: { userId: user.id, name: 'GoPay', type: 'EWALLET' }
  }) ?? await prisma.wallet.create({
      data: {
        userId: user.id,
        name: 'GoPay',
        type: 'EWALLET',
        balance: 500000,
      }
    });
  console.log('Development wallets ready');

  // 3. Create Budget
  const month = new Date().getMonth() + 1;
  const year = new Date().getFullYear();
  await prisma.budget.upsert({
    where: {
      userId_categoryId_month_year: {
        userId: user.id,
        categoryId: 'Food',
        month,
        year,
      }
    },
    update: {},
    create: {
      userId: user.id,
      categoryId: 'Food',
      amount: 1000000,
      month,
      year,
    },
  });
  console.log('Development budget ready');

  // 4. Create Transactions
  const lunchTransaction = await prisma.transaction.findFirst({
    where: { userId: user.id, merchant: 'Warung Nasi', notes: 'Makan siang' }
  });
  if (!lunchTransaction) {
    await prisma.$transaction([
      prisma.transaction.create({
        data: {
          userId: user.id,
          walletId: cashWallet.id,
          type: 'EXPENSE',
          amount: 50000,
          categoryId: 'Food',
          merchant: 'Warung Nasi',
          notes: 'Makan siang',
        }
      }),
      prisma.wallet.update({
        where: { id: cashWallet.id },
        data: { balance: { decrement: 50000 } }
      })
    ]);
  }

  const salaryTransaction = await prisma.transaction.findFirst({
    where: { userId: user.id, merchant: 'Company', notes: 'Gaji bulanan' }
  });
  if (!salaryTransaction) {
    await prisma.$transaction([
      prisma.transaction.create({
        data: {
          userId: user.id,
          walletId: gopayWallet.id,
          type: 'INCOME',
          amount: 2000000,
          categoryId: 'Salary',
          merchant: 'Company',
          notes: 'Gaji bulanan',
        }
      }),
      prisma.wallet.update({
        where: { id: gopayWallet.id },
        data: { balance: { increment: 2000000 } }
      })
    ]);
  }
  console.log('Development transactions ready');

  await prisma.$disconnect();
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
