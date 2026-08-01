export type ReceiptFields = {
  amount: number;
  merchant: string;
  categoryId: string;
};

export type ReceiptCase = {
  id: string;
  groundTruth: ReceiptFields;
};

export type ReceiptResult = {
  id: string;
  prediction: ReceiptFields | null;
  reviewRequired: (keyof ReceiptFields)[];
  correctedFields: (keyof ReceiptFields)[];
  latencyMs: number;
};

const normalizeMerchant = (value: string) =>
  value.trim().toLocaleLowerCase('id-ID').replace(/\s+/g, ' ');

const percentile = (values: number[], fraction: number) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.ceil(sorted.length * fraction) - 1] ?? 0;
};

export const evaluateReceipts = (
  cases: ReceiptCase[],
  results: ReceiptResult[],
) => {
  if (cases.length === 0) throw new Error('Dataset receipt kosong');
  const resultById = new Map(results.map((result) => [result.id, result]));
  const completed = cases.map((item) => {
    const result = resultById.get(item.id);
    if (!result) throw new Error(`Hasil untuk ${item.id} tidak ditemukan`);
    return { item, result };
  });

  let extracted = 0;
  let amountCorrect = 0;
  let merchantCorrect = 0;
  let categoryCorrect = 0;
  let incorrectFields = 0;
  let flaggedIncorrectFields = 0;
  let correctedCases = 0;

  for (const { item, result } of completed) {
    if (!result.prediction) continue;
    extracted++;
    const correctness = {
      amount: result.prediction.amount === item.groundTruth.amount,
      merchant: normalizeMerchant(result.prediction.merchant) ===
        normalizeMerchant(item.groundTruth.merchant),
      categoryId: result.prediction.categoryId === item.groundTruth.categoryId,
    };
    if (correctness.amount) amountCorrect++;
    if (correctness.merchant) merchantCorrect++;
    if (correctness.categoryId) categoryCorrect++;
    for (const field of Object.keys(correctness) as (keyof ReceiptFields)[]) {
      if (correctness[field]) continue;
      incorrectFields++;
      if (result.reviewRequired.includes(field)) flaggedIncorrectFields++;
    }
    if (result.correctedFields.length > 0) correctedCases++;
  }

  const total = cases.length;
  const ratio = (value: number, denominator = total) =>
    denominator === 0 ? 0 : value / denominator;
  const latencies = completed.map(({ result }) => result.latencyMs);
  return {
    sampleSize: total,
    extractionSuccessRate: ratio(extracted),
    amountExactMatch: ratio(amountCorrect),
    merchantExactMatch: ratio(merchantCorrect),
    categoryAccuracy: ratio(categoryCorrect),
    reviewFlagRecall: ratio(flaggedIncorrectFields, incorrectFields),
    correctionRate: ratio(correctedCases),
    latencyMs: {
      p50: percentile(latencies, 0.5),
      p95: percentile(latencies, 0.95),
    },
  };
};
