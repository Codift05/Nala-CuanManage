type TransactionLike = {
  type: string;
  amount: bigint;
  date: Date;
};

export type HabitFactor = {
  key: 'savingRatio' | 'budgetCompliance' | 'consistency';
  label: string;
  score: number | null;
  weight: number;
  available: boolean;
  reason: string;
  action: string;
};

export type HabitScore = {
  score: number | null;
  totalIncome: number;
  totalExpense: number;
  totalBudget: number;
  transactionCount: number;
  factors: HabitFactor[];
  actions: string[];
};

const clampScore = (value: number) =>
  Math.min(100, Math.max(0, Math.round(value)));

export const calculateHabitScore = (
  transactions: TransactionLike[],
  totalBudget: number,
  rangeStart: Date,
  rangeEnd: Date,
  asOf: Date,
): HabitScore => {
  const totalIncome = transactions
    .filter((item) => item.type === 'INCOME')
    .reduce((sum, item) => sum + Number(item.amount), 0);
  const totalExpense = transactions
    .filter((item) => item.type === 'EXPENSE')
    .reduce((sum, item) => sum + Number(item.amount), 0);
  const savingRate = totalIncome > 0
    ? (totalIncome - totalExpense) / totalIncome
    : 0;
  const savingScore = totalIncome > 0
    ? clampScore((savingRate / 0.2) * 100)
    : null;

  const budgetAvailable = totalBudget > 0 && transactions.length > 0;
  const budgetUsage = budgetAvailable ? totalExpense / totalBudget : 0;
  const budgetScore = !budgetAvailable ? null
    : budgetUsage <= 0.8 ? 100
    : budgetUsage <= 1 ? clampScore(100 - ((budgetUsage - 0.8) / 0.2) * 30)
    : clampScore(70 - (budgetUsage - 1) * 100);

  const activeDates = new Set(
    transactions.map((item) => item.date.toISOString().slice(0, 10)),
  );
  const startDay = Date.UTC(
    rangeStart.getUTCFullYear(),
    rangeStart.getUTCMonth(),
    rangeStart.getUTCDate(),
  );
  const asOfDay = Date.UTC(
    asOf.getUTCFullYear(),
    asOf.getUTCMonth(),
    asOf.getUTCDate(),
  );
  const elapsedDays = rangeEnd <= asOf
    ? Math.ceil((rangeEnd.getTime() - rangeStart.getTime()) / 86400000)
    : Math.max(1, Math.floor((asOfDay - startDay) / 86400000) + 1);
  const targetRecordDays = Math.max(4, Math.min(12, Math.ceil(elapsedDays * 0.4)));
  const consistencyScore = transactions.length > 0
    ? clampScore((activeDates.size / targetRecordDays) * 100)
    : null;

  const factors: HabitFactor[] = [
    {
      key: 'savingRatio',
      label: 'Rasio simpan',
      score: savingScore,
      weight: 0.4,
      available: savingScore !== null,
      reason: savingScore === null
        ? 'Belum ada pemasukan yang tercatat bulan ini.'
        : `${Math.round(savingRate * 100)}% pemasukan tersisa setelah pengeluaran.`,
      action: savingScore === null
        ? 'Catat pemasukan agar rasio simpan dapat dihitung.'
        : savingScore < 70
          ? 'Sisihkan sebagian pemasukan sebelum berbelanja.'
          : 'Pertahankan porsi simpan bulan ini.',
    },
    {
      key: 'budgetCompliance',
      label: 'Kepatuhan budget',
      score: budgetScore,
      weight: 0.35,
      available: budgetScore !== null,
      reason: budgetScore === null
        ? totalBudget > 0
          ? 'Budget tersedia, tetapi belum ada transaksi bulan ini.'
          : 'Belum ada budget bulan ini.'
        : `${Math.round(budgetUsage * 100)}% budget sudah digunakan.`,
      action: budgetScore === null
        ? totalBudget > 0
          ? 'Catat transaksi agar penggunaan budget dapat dihitung.'
          : 'Buat budget sederhana untuk kategori utama.'
        : budgetScore < 70
          ? 'Tinjau kategori yang melewati budget.'
          : 'Pertahankan pengeluaran di dalam budget.',
    },
    {
      key: 'consistency',
      label: 'Konsistensi mencatat',
      score: consistencyScore,
      weight: 0.25,
      available: consistencyScore !== null,
      reason: consistencyScore === null
        ? 'Belum ada transaksi yang tercatat bulan ini.'
        : `Transaksi dicatat pada ${activeDates.size} dari target ${targetRecordDays} hari.`,
      action: consistencyScore === null || consistencyScore < 70
        ? 'Catat transaksi pada hari yang sama agar tidak terlewat.'
        : 'Pertahankan kebiasaan mencatat secara rutin.',
    },
  ];
  const available = factors.filter(
    (factor): factor is HabitFactor & { score: number } => factor.score !== null,
  );
  const totalWeight = available.reduce((sum, factor) => sum + factor.weight, 0);
  const score = totalWeight === 0 ? null : clampScore(
    available.reduce((sum, factor) => sum + factor.score * factor.weight, 0) /
      totalWeight,
  );
  const actions = [...factors]
    .sort((left, right) => (left.score ?? -1) - (right.score ?? -1))
    .slice(0, 3)
    .map((factor) => factor.action);

  return {
    score,
    totalIncome,
    totalExpense,
    totalBudget,
    transactionCount: transactions.length,
    factors,
    actions,
  };
};

export const describeHabitScore = (score: number | null) => {
  if (score === null) return {
    status: 'Belum cukup data',
    nudgeMessage: 'Mulai dengan mencatat transaksi atau membuat budget bulan ini.',
  };
  if (score < 40) return {
    status: 'Mulai dibangun',
    nudgeMessage: 'Pilih satu kebiasaan kecil untuk dirapikan minggu ini.',
  };
  if (score < 60) return {
    status: 'Perlu dirapikan',
    nudgeMessage: 'Beberapa kebiasaan belum konsisten. Fokus pada tindakan teratas.',
  };
  if (score < 80) return {
    status: 'Cukup konsisten',
    nudgeMessage: 'Kebiasaanmu mulai terbentuk dan masih bisa ditingkatkan.',
  };
  return {
    status: 'Konsisten',
    nudgeMessage: 'Pertahankan kebiasaan yang sudah berjalan baik.',
  };
};
