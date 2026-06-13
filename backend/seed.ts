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

  console.log('User created:', user.email);

  // 2. Create Wallets
  const cashWallet = await prisma.wallet.create({
    data: {
      userId: user.id,
      name: 'Cash',
      type: 'CASH',
      balance: 1500000,
    }
  });

  const gopayWallet = await prisma.wallet.create({
    data: {
      userId: user.id,
      name: 'GoPay',
      type: 'EWALLET',
      balance: 500000,
    }
  });
  console.log('Wallets created');

  // 3. Create Budget
  await prisma.budget.create({
    data: {
      userId: user.id,
      categoryId: 'Food',
      amount: 1000000,
      month: new Date().getMonth() + 1,
      year: new Date().getFullYear()
    }
  });
  console.log('Budget created');

  // 4. Create Transactions
  await prisma.transaction.create({
    data: {
      userId: user.id,
      walletId: cashWallet.id,
      type: 'EXPENSE',
      amount: 50000,
      categoryId: 'Food',
      merchant: 'Warung Nasi',
      notes: 'Makan siang',
    }
  });

  await prisma.transaction.create({
    data: {
      userId: user.id,
      walletId: gopayWallet.id,
      type: 'INCOME',
      amount: 2000000,
      categoryId: 'Salary',
      merchant: 'Company',
      notes: 'Gaji bulanan',
    }
  });
  console.log('Transactions created');
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
