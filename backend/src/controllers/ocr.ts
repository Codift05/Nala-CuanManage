import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { GoogleGenerativeAI } from '@google/generative-ai';

export const scanReceipt = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { imageBase64 } = req.body;

    if (!imageBase64) {
      res.status(400).json({ error: 'imageBase64 is required' });
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
          data: imageBase64,
          mimeType: "image/jpeg"
        }
      }
    ];

    const result = await model.generateContent([systemPrompt, ...imageParts]);
    let responseText = result.response.text();

    // Clean up JSON block if exists
    responseText = responseText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    const parsedData = JSON.parse(responseText);

    res.json(parsedData);
  } catch (error) {
    console.error('Scan receipt error:', error);
    res.status(500).json({ error: 'Gagal memproses struk' });
  }
};
