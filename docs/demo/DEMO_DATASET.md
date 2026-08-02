# NALA Demo Dataset

Dataset ini hanya untuk demonstrasi UI, video, dan screenshot proposal. Seluruh
nama merchant, nominal, serta pola transaksi bersifat sintetis dan **bukan**
hasil riset, pilot, atau data finansial pengguna nyata.

## Akun development

- Email: `admin@nala.com`
- Password: `password123`
- Nama tampilan: `Miftah`

Akun tersebut hanya boleh dipakai pada environment lokal/development. Seed
tidak boleh dijalankan pada staging/production.

## Isi

- Tiga wallet: Bank Jago, GoPay, dan Tunai.
- 24 transaksi sintetis sepanjang tiga bulan terakhir.
- Empat kategori budget per bulan selama tiga bulan.
- Tiga tagihan berulang.
- Pemasukan, pengeluaran, merchant, kategori, dan tanggal yang saling konsisten.
- Data cukup untuk Home, Aktivitas, Laporan, Budget, Tagihan Berulang, dan
  Financial Habit Score.

Seed bersifat repeatable untuk akun demo. Setiap eksekusi mereset data finansial
`admin@nala.com`, kemudian membangunnya kembali dari
`backend/src/demo/demoData.ts`; akun lain tidak disentuh.

```bash
docker compose exec -T backend npm run seed
```

## Hasil verifikasi 3 Agustus 2026

| Pemeriksaan | Hasil aktual |
|---|---:|
| Wallet | 3 |
| Transaksi | 24 |
| Budget | 12 |
| Tagihan berulang | 3 |
| Pemasukan bulan berjalan | Rp4.000.000 |
| Pengeluaran bulan berjalan | Rp3.085.000 |
| Habit Score | 85 — Konsisten |
| Tren tiga bulan | 60 → 85 → 85 |

Angka di atas adalah fixture demonstrasi, bukan metrik keberhasilan produk.
Untuk klaim proposal, gunakan hasil dari protokol usability/pilot yang terpisah.

## Urutan screenshot yang disarankan

1. Home — ringkasan saldo dan transaksi terbaru.
2. Aktivitas — arus kas serta filter transaksi.
3. Laporan — tren pemasukan/pengeluaran tiga bulan.
4. Budget — empat kategori bulan berjalan.
5. Financial Habit Score — skor, tiga faktor, dan tren.
6. Tagihan Berulang — tiga jadwal contoh.
7. Nala Coach/Scan — gunakan prompt atau struk sintetis, jangan data nyata.
