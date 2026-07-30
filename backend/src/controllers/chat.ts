import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { GoogleGenerativeAI } from '@google/generative-ai';
import prisma from '../utils/prisma';
import { parseTransactionDraft } from '../utils/transactionDraft';
import { getGeminiTimeoutMs, withTimeout } from '../utils/ai';

const fallbackReply =
  'Maaf, layanan AI Nala sedang tidak tersedia. Kamu tetap bisa mencatat transaksi secara manual, lalu coba chat lagi nanti ya.';

export const chatWithNala = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { message } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    if (!message) {
      res.status(400).json({ error: 'Message is required' });
      return;
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      res.json({
        reply: fallbackReply,
        transactionDraft: null,
        fallback: true,
      });
      return;
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    // Fetch user context for better personalized AI response
    const user = await prisma.user.findUnique({ where: { id: userId } });
    
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    const transactions = await prisma.transaction.findMany({
      where: { wallet: { userId }, date: { gte: startOfMonth } }
    });
    
    const totalExpense = transactions.filter(t => t.type === 'EXPENSE').reduce((acc, t) => acc + Number(t.amount), 0);
    const totalIncome = transactions.filter(t => t.type === 'INCOME').reduce((acc, t) => acc + Number(t.amount), 0);

    // Fetch wallets to give context to Gemini
    const wallets = await prisma.wallet.findMany({ where: { userId } });
    const walletsInfo = wallets.map(w => `- ${w.name} (ID: ${w.id})`).join('\n');

    const systemPrompt = `Kamu adalah Nala, asisten pelatih keuangan AI (AI Financial Coach) yang ramah, asik, ceria, dan sangat mengerti anak muda Indonesia.
Penggunamu bernama ${user?.name || 'Teman'}.
Bulan ini pengguna memiliki total pemasukan Rp ${totalIncome} dan pengeluaran Rp ${totalExpense}.

Daftar dompet pengguna:
${walletsInfo || 'Belum ada dompet.'}

Tugasmu adalah menjawab pertanyaan pengguna seputar keuangannya, memberikan tips hemat, dan menyemangati mereka.
Jika pengguna memberitahu bahwa mereka baru saja melakukan transaksi (mengeluarkan atau mendapat uang), ekstrak transaksi sebagai DRAFT dalam format JSON block di akhir jawabanmu seperti ini:
\`\`\`json
{
  "action": "create_transaction",
  "type": "EXPENSE", // atau "INCOME"
  "amount": 25000,
  "categoryId": "Food", // misal: Food, Transport, Shopping, Bills, Income, Others
  "walletId": "ID_DOMPET_YANG_SESUAI_DARI_DAFTAR_DI_ATAS",
  "merchant": "Nama merchant jika ada",
  "notes": "Catatan singkat"
}
\`\`\`
Pastikan nominal berupa bilangan bulat rupiah dan walletId sesuai dengan ID dompet yang ada di daftar. Jika dompet tidak disebutkan jelas, pilih dompet pertama atau yang paling masuk akal. Jika belum ada dompet, kosongkan walletId.

Gunakan bahasa Indonesia yang ramah, singkat, dan jelas (maksimal 3 paragraf pendek) sebelum block JSON. Jangan pernah mengatakan transaksi sudah tersimpan. Jelaskan bahwa kamu menyiapkan draft yang harus diperiksa dan dikonfirmasi pengguna.`;

    let result;
    try {
      result = await withTimeout(
        model.generateContent([systemPrompt, `User: ${message}`]),
        getGeminiTimeoutMs(),
      );
    } catch (error) {
      console.error('Gemini request failed:', error);
      res.json({
        reply: fallbackReply,
        transactionDraft: null,
        fallback: true,
      });
      return;
    }

    let nalaResponse = result.response.text();
    let transactionDraft = null;

    const jsonMatch = nalaResponse.match(/```json\s*([\s\S]*?)```/);
    if (jsonMatch && jsonMatch[1]) {
      try {
        transactionDraft = parseTransactionDraft(
          JSON.parse(jsonMatch[1]),
          new Set(wallets.map((wallet) => wallet.id)),
        );
      } catch (e) {
        console.error('Failed to parse transaction draft from Nala', e);
      }
      nalaResponse = nalaResponse.replace(/```json\s*[\s\S]*?```/, '').trim();
    }

    res.json({ reply: nalaResponse, transactionDraft });
  } catch (error) {
    console.error('Nala Chat API Error:', error);
    res.status(500).json({ error: 'Gagal memproses chat dengan Nala. Mungkin API Key tidak valid atau limit.' });
  }
};
