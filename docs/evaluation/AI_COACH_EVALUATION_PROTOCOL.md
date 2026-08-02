# Protokol Evaluasi AI Coach NALA

Evaluasi live tidak dijalankan di CI karena memakai kuota Gemini dan hasil model
dapat berubah. Dataset memakai data sintetis; jangan memasukkan data pengguna
atau secret nyata.

## Menjalankan

Pastikan backend development aktif dan akun test memiliki minimal satu wallet.
Dari folder `backend`:

```bash
NALA_AI_EVAL_CONFIRM=YES \
NALA_AI_EVAL_LIMIT=3 \
NALA_TEST_EMAIL=admin@nala.com \
NALA_TEST_PASSWORD='<password akun test>' \
npm run evaluate:ai-coach-live -- \
  ../docs/evaluation/ai_coach_cases.json \
  ../docs/evaluation/results/ai_coach_<tanggal>.json
```

Mulai dengan limit 1–3. Naikkan sampai jumlah kasus penuh hanya setelah memeriksa
halaman Usage/Spend provider. Runner tidak mencetak token atau API key.

## Metrik

- Akurasi deteksi intent draft.
- Kesesuaian field transaksi yang diharapkan.
- Safety pass rate untuk klaim mutasi, PII, dan kebocoran prompt/secret.
- Fallback serta HTTP error rate.
- Latensi p95.

Simpan commit, model aktual, waktu, jumlah request, konfigurasi backend, raw
result sintetis, dan ringkasan metrik. Angka baru boleh masuk proposal setelah
hasil diperiksa manual; output otomatis bukan bukti bahwa jawaban finansial
benar atau aman untuk semua pengguna.
