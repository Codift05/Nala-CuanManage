# Daftar Komponen dan Lisensi NALA

Dokumen ini mencatat komponen langsung yang digunakan NALA. Versi diambil dari lockfile dan instalasi yang diverifikasi pada 14 Agustus 2026. Pemberitahuan lisensi lengkap yang ikut dalam distribusi Flutter dapat diperoleh melalui halaman lisensi aplikasi.

Kode dan aset orisinal NALA menggunakan lisensi proprietary sebagaimana
dijelaskan dalam `LICENSE` dan `ADOPSI_LISENSI.md`.

## Mobile

| Komponen | Versi | Fungsi | Lisensi |
|---|---:|---|---|
| Flutter SDK | versi build terpasang | Kerangka aplikasi lintas platform | BSD-3-Clause |
| Dart SDK | versi bawaan Flutter | Bahasa dan runtime | BSD-3-Clause |
| cupertino_icons | 1.0.9 | Ikon antarmuka | MIT |
| provider | 6.1.5+1 | Pengelolaan state ringan | MIT |
| http | 1.6.0 | Klien HTTP | BSD-3-Clause |
| shared_preferences | 2.5.5 | Preferensi lokal non-sensitif | BSD-3-Clause |
| intl | 0.20.2 | Format tanggal dan nominal | BSD-3-Clause |
| home_widget | 0.9.3 | Widget layar utama Android | BSD-3-Clause |
| image_picker | 1.2.2 | Pemilihan/pengambilan gambar struk | BSD-3-Clause |
| fl_chart | 1.2.0 | Visualisasi laporan | MIT |
| flutter_secure_storage | 10.3.1 | Penyimpanan token pada perangkat | BSD-3-Clause |
| local_auth | 3.0.2 | Verifikasi biometrik lokal | BSD-3-Clause |

## Backend

| Komponen | Versi | Fungsi | Lisensi |
|---|---:|---|---|
| Node.js | 20 | Runtime backend | MIT |
| TypeScript | 6.0.3 | Bahasa backend bertipe | Apache-2.0 |
| Express | 5.2.1 | REST API | MIT |
| Prisma Client/Adapter | 7.8.0 | Akses dan pemodelan database | Apache-2.0 |
| pg | 8.21.0 | Driver PostgreSQL | MIT |
| redis (npm) | 6.0.0 | Klien Redis | MIT |
| bcrypt | 6.0.0 | Hash password | MIT |
| jsonwebtoken | 9.0.3 | Token autentikasi | MIT |
| cors | 2.8.6 | Kebijakan origin API | MIT |
| dotenv | 17.4.2 | Pembacaan konfigurasi environment | BSD-2-Clause |
| node-cron | 4.2.1 | Penjadwalan tagihan berulang | ISC |
| Google Cloud Vision SDK | 5.3.7 | Integrasi OCR | Apache-2.0 |
| Google Generative AI SDK | 0.24.1 | Integrasi Nala Coach | Apache-2.0 |

## Infrastruktur dan aset

| Komponen | Fungsi | Lisensi/ketentuan |
|---|---|---|
| PostgreSQL | Database relasional | PostgreSQL License |
| Redis Server | Rate limiting | Mengikuti lisensi versi image yang dipakai saat deployment; versi wajib dipin sebelum rilis |
| Docker/Compose | Container dan orkestrasi lokal | Apache-2.0 |
| Inter Variable Font | Tipografi aplikasi | SIL Open Font License 1.1 |
| Gemini API | Layanan AI eksternal | Google APIs Terms dan ketentuan layanan terkait |

## Catatan kepatuhan

1. Daftar ini tidak mengubah ketentuan lisensi masing-masing pemilik komponen.
2. Dependensi transitif tetap mengikuti pemberitahuan lisensi yang dibawa oleh package manager dan binary Flutter.
3. Secret, kredensial, dataset responden mentah, dan data pengguna tidak termasuk dalam distribusi.
4. Versi container produksi harus dipin sebelum pengarsipan final agar lisensinya dapat diverifikasi secara deterministik.
