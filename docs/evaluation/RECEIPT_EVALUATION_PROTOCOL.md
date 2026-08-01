# Protokol Evaluasi Receipt NALA

## Tujuan

Mengukur kemampuan ekstraksi nominal, merchant, dan kategori serta beban
koreksi pengguna. Confidence AI hanya menjadi sinyal review dan tidak dihitung
sebagai akurasi tanpa pembanding ground truth.

## Dataset

- Baseline awal minimal 30 struk; target 100 sebelum pilot.
- Gunakan struk milik tim/responden yang memberi persetujuan.
- Seimbangkan merchant lokal/nasional, cetak/tulisan tangan, pencahayaan,
  kemiringan, kusut, dan panjang struk.
- Jangan commit foto, nama pembeli, nomor kartu, alamat, atau data pribadi.
- Simpan foto pada penyimpanan terbatas; repo hanya menyimpan ID anonim dan
  ground truth yang sudah dibersihkan.
- Satu orang memberi label, orang kedua memverifikasi nominal dan merchant.

## Prosedur

1. Bekukan commit aplikasi, model AI, prompt, perangkat, dan koneksi pengujian.
2. Isi `receipt_manifest.example.json` dengan ground truth terverifikasi.
3. Jalankan setiap struk satu kali tanpa mengubah gambar.
4. Catat prediksi awal, field yang ditandai untuk review, latency dari kirim
   sampai draft tampil, dan field yang dikoreksi pengguna.
5. Simpan raw result memakai bentuk `receipt_results.example.json`.
6. Jalankan evaluator dan salin output aktual ke laporan bertanggal.

```bash
cd backend
npm run evaluate:receipts -- \
  ../docs/evaluation/receipt_manifest.json \
  ../docs/evaluation/receipt_results.json
```

## Metrik

- `extractionSuccessRate`: proporsi struk yang menghasilkan draft valid.
- `amountExactMatch`: nominal harus sama persis dengan ground truth.
- `merchantExactMatch`: sama setelah lowercase, trim, dan normalisasi spasi.
- `categoryAccuracy`: kategori sama persis.
- `reviewFlagRecall`: kesalahan field yang berhasil ditandai untuk diperiksa.
- `correctionRate`: struk yang membutuhkan sedikitnya satu koreksi.
- `latencyMs.p50/p95`: waktu scan-to-review; gunakan nearest-rank percentile.

Laporkan jumlah sampel dan interval pengujian bersama semua persentase. Jangan
mengubah target menjadi hasil sebelum raw data tersedia.
