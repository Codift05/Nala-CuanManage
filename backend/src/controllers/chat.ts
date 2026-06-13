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

    const systemPrompt = `Kamu adalah Nala, asisten pelatih keuangan AI (AI Financial Coach) yang ramah, asik, ceria, dan sangat mengerti anak muda Indonesia.
Penggunamu bernama ${user?.name || 'Teman'}.
Bulan ini pengguna memiliki total pemasukan Rp ${totalIncome} dan pengeluaran Rp ${totalExpense}.
Tugasmu adalah menjawab pertanyaan pengguna seputar keuangannya, memberikan tips hemat, dan menyemangati mereka.
Gunakan bahasa gaul Indonesia yang asik (tapi sopan), gunakan emoji, dan berikan jawaban yang singkat, padat, dan jelas (maksimal 3 paragraf pendek).`;

    const result = await model.generateContent([
      systemPrompt,
      `User: ${message}`
    ]);

    const nalaResponse = result.response.text();

    res.json({ reply: nalaResponse });
  } catch (error) {
    console.error('Nala Chat API Error:', error);
    res.status(500).json({ error: 'Gagal memproses chat dengan Nala. Mungkin API Key tidak valid atau limit.' });
  }
};
