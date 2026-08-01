# Synthetic Receipt Dataset

Dataset ini dibuat secara deterministik untuk regression test OCR NALA. Semua
merchant, nominal, waktu, dan struk bersifat fiktif; gambar tidak boleh dipakai
sebagai bukti akurasi pada struk dunia nyata.

Regenerasi membutuhkan ImageMagick:

```bash
cd backend
npm run generate:receipt-dataset
```

`manifest.json` adalah ground truth. Kondisi visual mencakup clean, rotasi,
low contrast, blur ringan, dan noise. Dataset nyata berizin tetap diperlukan
sebelum klaim akurasi proposal dipublikasikan.

Pengujian live membutuhkan backend berjalan, akun test, dan `GEMINI_API_KEY`
pada backend. Token hanya diteruskan lewat environment dan tidak disimpan:

```bash
cd backend
NALA_TEST_TOKEN='<access-token-test>' npm run test:receipt-dataset -- \
  ../docs/evaluation/synthetic_receipts/manifest.json \
  /tmp/nala-synthetic-receipt-results.json
npm run evaluate:receipts -- \
  ../docs/evaluation/synthetic_receipts/manifest.json \
  /tmp/nala-synthetic-receipt-results.json
```
