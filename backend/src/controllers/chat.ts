import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { GoogleGenerativeAI } from '@google/generative-ai';
import prisma from '../utils/prisma';

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
      res.status(500).json({ error: 'Gemini API key is not configured di backend/.env' });
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
Jika pengguna memberitahu bahwa mereka baru saja melakukan transaksi (mengeluarkan atau mendapat uang), kamu WAJIB mengekstrak data transaksi tersebut ke dalam format JSON block di akhir jawabanmu seperti ini:
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
Pastikan walletId sesuai dengan ID dompet yang ada di daftar. Jika dompet tidak disebutkan jelas, pilih dompet pertama atau yang paling masuk akal. Jika belum ada dompet, kosongkan walletId.

Gunakan bahasa gaul Indonesia yang asik (tapi sopan), gunakan emoji, dan berikan jawaban utama yang singkat, padat, dan jelas (maksimal 3 paragraf pendek) sebelum block JSON. Jika kamu mencatat transaksi, beritahu pengguna bahwa transaksinya sudah berhasil dicatat.`;

    const result = await model.generateContent([
      systemPrompt,
      `User: ${message}`
    ]);

    let nalaResponse = result.response.text();
    let transactionCreated = false;

    // Parse the JSON block if it exists
    const jsonMatch = nalaResponse.match(/```json\n([\s\S]*?)\n```/);
    if (jsonMatch && jsonMatch[1]) {
      try {
        const txData = JSON.parse(jsonMatch[1]);
        if (txData.action === 'create_transaction' && txData.walletId) {
          // Verify wallet belongs to user
          const wallet = await prisma.wallet.findFirst({ where: { id: txData.walletId, userId } });
          if (wallet) {
            const balanceChange = txData.type === 'INCOME' ? Number(txData.amount) : -Number(txData.amount);
            
            await prisma.$transaction([
              prisma.transaction.create({
                data: {
                  userId,
                  walletId: txData.walletId,
                  type: txData.type,
                  amount: Number(txData.amount),
                  categoryId: txData.categoryId,
                  merchant: txData.merchant,
                  notes: txData.notes
                }
              }),
              prisma.wallet.update({
                where: { id: txData.walletId },
                data: { balance: { increment: balanceChange } }
              })
            ]);
            transactionCreated = true;
          }
        }
      } catch (e) {
        console.error("Failed to parse transaction JSON from Nala", e);
      }
      // Remove JSON block from the reply sent to user
      nalaResponse = nalaResponse.replace(/```json\n[\s\S]*?\n```/, '').trim();
    }

    res.json({ reply: nalaResponse, transactionCreated });
  } catch (error) {
    console.error('Nala Chat API Error:', error);
    res.status(500).json({ error: 'Gagal memproses chat dengan Nala. Mungkin API Key tidak valid atau limit.' });
  }
};
