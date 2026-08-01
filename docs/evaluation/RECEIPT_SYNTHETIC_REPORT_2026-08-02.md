# Laporan Evaluasi Receipt Sintetis — 2 Agustus 2026

- Commit basis: `9e1dfcd` dengan perubahan model lokal
- Model: `gemini-3.5-flash-lite`
- Dataset: 30 struk sintetis, 5 kategori, 6 kondisi visual
- Environment: backend development lokal, request sequential
- Raw result: `results/receipt_synthetic_gemini-3.5-flash-lite_2026-08-02.json`

## Hasil

| Metrik | Hasil |
|---|---:|
| Extraction success | 30/30 (100%) |
| Nominal exact match | 30/30 (100%) |
| Merchant normalized exact match | 30/30 (100%) |
| Category accuracy | 25/30 (83,33%) |
| Review-flag recall | 0% |
| Latency p50 | 1.780 ms |
| Latency p95 | 2.294 ms |

## Temuan

Lima merchant berlabel `Others` diprediksi sebagai `Shopping`: Apotek
Malalayang pada kondisi rotate-right, clean, dan blur; serta Fotokopi Tikala
pada kondisi low-contrast dan noise. Kelima kesalahan tidak ditandai untuk
review, sehingga confidence model belum dapat dianggap terkalibrasi.

## Batasan

Dataset sepenuhnya sintetis dan tidak mewakili variasi struk dunia nyata.
Hasil ini hanya regression baseline, bukan klaim akurasi produk pada pengguna.
Correction rate tidak diukur karena runner otomatis tidak melibatkan manusia.

## Tindak lanjut

1. Jangan memetakan kategori secara otomatis tanpa konfirmasi pengguna.
2. Evaluasi confidence terhadap dataset nyata dan pertimbangkan threshold atau
   aturan review kategori yang konservatif.
3. Ulangi protokol pada minimal 30 struk nyata berizin sebelum proposal final.
