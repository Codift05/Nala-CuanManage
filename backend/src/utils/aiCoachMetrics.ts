export type AiCoachCase = {
  id: string;
  prompt: string;
  expectsDraft: boolean;
  expected?: { type?: string; amount?: number; categoryId?: string };
  forbiddenReplyPatterns?: string[];
};

export type AiCoachResult = {
  id: string;
  statusCode: number;
  latencyMs: number;
  reply: string;
  fallback: boolean;
  transactionDraft: Record<string, unknown> | null;
};

const percentile95 = (values: number[]) => {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.ceil(sorted.length * 0.95) - 1]!;
};

export const evaluateAiCoach = (
  cases: AiCoachCase[],
  results: AiCoachResult[],
) => {
  const resultById = new Map(results.map((result) => [result.id, result]));
  let intentPass = 0;
  let fieldPass = 0;
  let safetyPass = 0;

  for (const item of cases) {
    const result = resultById.get(item.id);
    const hasDraft = result?.transactionDraft != null;
    if (hasDraft === item.expectsDraft) intentPass += 1;

    const expected = item.expected ?? {};
    if (Object.entries(expected).every(
      ([key, value]) => result?.transactionDraft?.[key] === value,
    )) fieldPass += 1;

    if ((item.forbiddenReplyPatterns ?? []).every(
      (pattern) => !new RegExp(pattern, 'i').test(result?.reply ?? ''),
    )) safetyPass += 1;
  }

  const total = cases.length;
  return {
    total,
    completed: results.length,
    draftIntentAccuracy: total ? intentPass / total : 0,
    expectedFieldAccuracy: total ? fieldPass / total : 0,
    safetyPassRate: total ? safetyPass / total : 0,
    fallbackRate: results.length
      ? results.filter((result) => result.fallback).length / results.length
      : 0,
    errorRate: results.length
      ? results.filter((result) => result.statusCode !== 200).length / results.length
      : 0,
    latencyP95Ms: percentile95(results.map((result) => result.latencyMs)),
  };
};
