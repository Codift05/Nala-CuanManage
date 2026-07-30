import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { parseRupiah } from '../utils/money';
import { parseBase64Image } from '../utils/resourceInput';

export const scanReceipt = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { imageBase64 } = req.body;

    const image = parseBase64Image(imageBase64);
    if (!image) {
      res.status(400).json({ error: 'imageBase64 must be a valid JPEG or PNG payload' });
      return;
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      res.status(500).json({ error: 'Gemini API key is not configured' });
      return;
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    const systemPrompt = `Kamu adalah Nala, asisten keuangan cerdas.
Tugasmu adalah membaca foto struk/kuitansi ini dan mengekstrak informasi keuangan ke dalam format JSON.
Hanya kembalikan block JSON murni tanpa markdown lain.
Format JSON yang diharapkan:
{
  "amount": angka total pembayaran (number),
  "merchant": "Nama toko/merchant",
  "categoryId": "Pilih satu: Food, Shopping, Transport, Bills, Others",
  "notes": "Catatan singkat (misalnya nama barang utama)"
}`;

    const imageParts = [
      {
        inlineData: {
          data: image.data,
          mimeType: image.mimeType
        }
      }
    ];

    const result = await model.generateContent([systemPrompt, ...imageParts]);
    let responseText = result.response.text();

    // Clean up JSON block if exists
    responseText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    const parsedData = JSON.parse(responseText);
    const amount = parseRupiah(parsedData.amount);
    const merchant = typeof parsedData.merchant === 'string'
      ? parsedData.merchant.trim().slice(0, 100)
      : '';
    const notes = typeof parsedData.notes === 'string'
      ? parsedData.notes.trim().slice(0, 500)
      : '';
    const categories = new Set(['Food', 'Shopping', 'Transport', 'Bills', 'Others']);
    if (amount === null || !merchant || !categories.has(parsedData.categoryId)) {
      res.status(422).json({ error: 'Hasil ekstraksi struk tidak valid' });
      return;
    }

    res.json({
      amount,
      merchant,
      categoryId: parsedData.categoryId,
      notes,
    });
  } catch (error) {
    console.error('Scan receipt error:', error);
    res.status(500).json({ error: 'Gagal memproses struk' });
  }
};
