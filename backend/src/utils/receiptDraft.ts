import { parseRupiah, rupiahToJson } from './money';

const categories = new Set(['Food', 'Shopping', 'Transport', 'Bills', 'Others']);
const confidenceFields = ['amount', 'merchant', 'categoryId'] as const;

type ConfidenceField = typeof confidenceFields[number];

export type ReceiptDraft = {
  amount: number;
  merchant: string;
  categoryId: string;
  notes: string;
  confidence: Record<ConfidenceField, number>;
  reviewRequired: ConfidenceField[];
};

export const parseReceiptDraft = (value: unknown): ReceiptDraft | null => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const draft = value as Record<string, unknown>;
  const amount = parseRupiah(draft.amount);
  const merchant = typeof draft.merchant === 'string'
    ? draft.merchant.trim().slice(0, 100)
    : '';
  const notes = typeof draft.notes === 'string'
    ? draft.notes.trim().slice(0, 500)
    : '';
  const categoryId = typeof draft.categoryId === 'string'
    ? draft.categoryId
    : '';
  if (amount === null || !merchant || !categories.has(categoryId)) {
    return null;
  }

  const rawConfidence = draft.confidence && typeof draft.confidence === 'object'
    ? draft.confidence as Record<string, unknown>
    : {};
  const confidence = Object.fromEntries(
    confidenceFields.map((field) => {
      const score = rawConfidence[field];
      return [field, typeof score === 'number' && Number.isFinite(score) &&
        score >= 0 && score <= 1 ? score : 0];
    }),
  ) as Record<ConfidenceField, number>;

  return {
    amount: rupiahToJson(amount),
    merchant,
    categoryId,
    notes,
    confidence,
    reviewRequired: confidenceFields.filter((field) => confidence[field] < 0.8),
  };
};

export const parseReceiptDraftResponse = (text: string): ReceiptDraft | null => {
  try {
    const json = text.replace(/```json\s?/g, '').replace(/```\s?/g, '').trim();
    return parseReceiptDraft(JSON.parse(json));
  } catch {
    return null;
  }
};
