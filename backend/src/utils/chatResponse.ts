import { TransactionDraft } from './transactionDraft';

export const buildChatResponse = (
  reply: string,
  transactionDraft: TransactionDraft | null = null,
  fallback = false,
) => ({
  reply: reply.trim() || 'Respons Nala belum tersedia.',
  transactionDraft,
  fallback,
});
