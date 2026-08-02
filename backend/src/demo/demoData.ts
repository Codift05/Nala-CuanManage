export type DemoTransaction = {
  key: string;
  wallet: 'cash' | 'gopay' | 'bank';
  type: 'INCOME' | 'EXPENSE';
  amount: number;
  categoryId: string;
  merchant: string;
  notes: string;
  date: Date;
};

type DemoRow = [
  string,
  DemoTransaction['wallet'],
  DemoTransaction['type'],
  number,
  string,
  string,
  string,
  number,
  number,
];

const at = (now: Date, monthOffset: number, day: number, hour = 12) =>
  new Date(now.getFullYear(), now.getMonth() + monthOffset, day, hour);

export const buildDemoData = (now = new Date()) => ({
  recurringBills: [
    { wallet: 'bank' as const, title: 'Sewa Kost Teling', amount: 1_400_000, categoryId: 'Housing', dueDate: 1 },
    { wallet: 'gopay' as const, title: 'Internet bulanan', amount: 180_000, categoryId: 'Bills', dueDate: 3 },
    { wallet: 'gopay' as const, title: 'Cloud proyek tim', amount: 95_000, categoryId: 'Education', dueDate: 15 },
  ],
  budgets: [-2, -1, 0].flatMap((monthOffset) => [
    { monthOffset, categoryId: 'Food', amount: 900_000 },
    { monthOffset, categoryId: 'Transport', amount: 350_000 },
    { monthOffset, categoryId: 'Housing', amount: 1_500_000 },
    { monthOffset, categoryId: 'Bills', amount: 450_000 },
  ]),
  transactions: ([
    // Dua bulan lalu: kebiasaan masih belum konsisten.
    ['m2-income', 'bank', 'INCOME', 4_000_000, 'Salary', 'Kiriman keluarga', 'Dana bulanan', -2, 1],
    ['m2-rent', 'bank', 'EXPENSE', 1_400_000, 'Housing', 'Kost Teling', 'Sewa kost', -2, 1],
    ['m2-food-1', 'gopay', 'EXPENSE', 480_000, 'Food', 'Indomaret', 'Belanja kebutuhan', -2, 5],
    ['m2-campus', 'bank', 'EXPENSE', 780_000, 'Education', 'Kampus', 'Keperluan akademik', -2, 11],
    ['m2-food-2', 'cash', 'EXPENSE', 390_000, 'Food', 'RM Cakalang', 'Makan harian', -2, 20],
    ['m2-bills', 'gopay', 'EXPENSE', 260_000, 'Bills', 'Telkomsel', 'Internet dan pulsa', -2, 20],
    ['m2-transport', 'gopay', 'EXPENSE', 105_000, 'Transport', 'Maxim', 'Transport kampus', -2, 20],

    // Bulan lalu: pengeluaran turun dan hari pencatatan bertambah.
    ['m1-income', 'bank', 'INCOME', 4_200_000, 'Salary', 'Kiriman keluarga', 'Dana bulanan', -1, 1],
    ['m1-freelance', 'gopay', 'INCOME', 450_000, 'Freelance', 'Studio Kawanua', 'Freelance desain', -1, 8],
    ['m1-rent', 'bank', 'EXPENSE', 1_400_000, 'Housing', 'Kost Teling', 'Sewa kost', -1, 1],
    ['m1-food-1', 'gopay', 'EXPENSE', 340_000, 'Food', 'Indomaret', 'Belanja kebutuhan', -1, 4],
    ['m1-food-2', 'cash', 'EXPENSE', 420_000, 'Food', 'RM Cakalang', 'Makan harian', -1, 12],
    ['m1-bills', 'gopay', 'EXPENSE', 235_000, 'Bills', 'Telkomsel', 'Internet dan pulsa', -1, 17],
    ['m1-transport', 'gopay', 'EXPENSE', 120_000, 'Transport', 'Maxim', 'Transport kampus', -1, 23],
    ['m1-project', 'bank', 'EXPENSE', 320_000, 'Education', 'Percetakan Manado', 'Kebutuhan proyek', -1, 27],

    // Bulan berjalan: cukup kaya untuk Home, Aktivitas, Laporan, dan Habit Score.
    ['m0-income', 'bank', 'INCOME', 3_000_000, 'Salary', 'Kiriman keluarga', 'Dana bulanan', 0, 1],
    ['m0-freelance', 'gopay', 'INCOME', 1_000_000, 'Freelance', 'Studio Kawanua', 'Freelance aplikasi', 0, 2],
    ['m0-rent', 'bank', 'EXPENSE', 1_400_000, 'Housing', 'Kost Teling', 'Sewa kost', 0, 1],
    ['m0-campus', 'bank', 'EXPENSE', 750_000, 'Education', 'Kampus', 'Kebutuhan semester', 0, 1],
    ['m0-food-1', 'gopay', 'EXPENSE', 325_000, 'Food', 'Indomaret', 'Belanja mingguan', 0, 2],
    ['m0-transport', 'gopay', 'EXPENSE', 85_000, 'Transport', 'Maxim', 'Transport kampus', 0, 2],
    ['m0-bills', 'gopay', 'EXPENSE', 180_000, 'Bills', 'Telkomsel', 'Internet bulanan', 0, 3],
    ['m0-food-2', 'cash', 'EXPENSE', 235_000, 'Food', 'RM Cakalang', 'Makan bersama tim', 0, 3],
    ['m0-other', 'cash', 'EXPENSE', 110_000, 'Others', 'Fotokopi Bahu', 'Cetak dokumen', 0, 3],
  ] satisfies DemoRow[]).map(([key, wallet, type, amount, categoryId, merchant, notes, offset, day]) => ({
    key: `demo:${key}`,
    wallet,
    type,
    amount,
    categoryId,
    merchant,
    notes,
    date: at(now, offset, day),
  })),
});
