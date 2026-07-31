# NALA Product & Engineering Plan

Dokumen ini adalah sumber acuan utama untuk menyelaraskan proposal GEMASTIK,
pengembangan produk, pengujian, dan validasi pengguna NALA.

Terakhir diperbarui: 31 Juli 2026
Status produk: Beta internal / belum siap untuk pengguna publik

## 1. Arah Produk

### Identitas

- Nama produk: **NALA**
- Deskripsi: **AI Financial Wellness Companion untuk mahasiswa**
- Tagline: **Atur uang nggak perlu ribet. Bareng Nala aja.**
- Platform prototipe utama: **Android**
- Arsitektur aplikasi: Flutter cross-platform dengan backend modular monolith

### Target pengguna utama

Mahasiswa aktif berusia 18–24 tahun yang menggunakan lebih dari satu media
keuangan—uang tunai, rekening bank, atau dompet digital—dan kesulitan mencatat,
memahami, serta mengendalikan pengeluaran bulanan.

### Masalah utama

1. Pencatatan transaksi terasa merepotkan dan mudah ditinggalkan.
2. Saldo dan transaksi tersebar di beberapa media keuangan.
3. Grafik keuangan tidak selalu menghasilkan tindakan yang mudah dipahami.
4. Saran keuangan umum tidak mempertimbangkan kondisi aktual pengguna.

### Tiga inovasi inti

1. **Frictionless Financial Capture**  
   Pencatatan melalui input cepat, scan struk, impor bukti transaksi, dan
   percakapan dengan Nala.

2. **Explainable Financial Habit Score**  
   Indikator kebiasaan finansial dengan komponen, alasan perubahan, dan tindakan
   perbaikan yang dapat dijelaskan.

3. **Context-Aware AI Coach**  
   Pendamping yang memakai ringkasan kondisi aktual pengguna, meminimalkan data
   sensitif, dan selalu meminta konfirmasi sebelum mengubah data keuangan.

Fitur lain seperti multi-wallet, budget, tagihan berulang, laporan, dan widget
merupakan fitur pendukung, bukan inovasi utama.

## 2. Prinsip Pengembangan

1. Bukti lebih penting daripada jumlah fitur.
2. Integritas nilai uang dan data pengguna tidak boleh dikompromikan.
3. AI hanya menghasilkan saran atau draft; pengguna memegang keputusan akhir.
4. Klaim proposal harus sesuai dengan implementasi dan hasil pengujian.
5. Modular monolith dipertahankan sampai skala nyata membuktikan kebutuhan lain.
6. Teknologi baru ditambahkan hanya jika menyelesaikan kebutuhan terukur.
7. Setiap fitur dianggap selesai setelah memiliki acceptance criteria dan bukti.

## 3. Kondisi Aktual

Legenda:

- ✅ Selesai dan sudah diverifikasi
- 🟡 Berfungsi sebagian atau perlu diperkuat
- ⬜ Belum tersedia
- ⛔ Tidak menjadi prioritas versi kompetisi

### Mobile

| Area | Status | Kondisi aktual | Bukti selesai berikutnya |
|---|---:|---|---|
| Welcome dan login | ✅ | UI diperbarui dan memiliki widget test | Pertahankan tanpa overflow |
| Secure token storage | ✅ | Token memakai `flutter_secure_storage` dan migrasi token lama | Tetap diuji di CI |
| Dashboard | ✅ | Saldo, aksi cepat, budget, transaksi terbaru, refresh, dan empty state tersedia | Pertahankan widget test |
| Multi-wallet | 🟡 | CRUD, loading, empty, error, retry, dan refresh tersedia | Integration test CRUD lengkap |
| Transaksi manual | 🟡 | CRUD, integer rupiah, idempotency, pagination, dan state UI tersedia | Uji konkurensi wallet |
| Budget planner | 🟡 | CRUD, progress, loading, empty, error, dan retry tersedia | Edge case dan integration test |
| Financial score | 🟡 | Skor serta tren tiga bulan tersedia | Formula baru, penjelasan, dan test |
| AI Coach | 🟡 | Chat kontekstual dan pembuatan transaksi tersedia | Wajib diubah menjadi draft + konfirmasi |
| Scan struk | 🟡 | Gemini mengekstrak gambar Base64 | Validasi file, schema output, review, evaluasi |
| Deteksi SMS | 🟡 | Hanya mendeteksi kata GoPay/BCA dan “berhasil” | Turunkan menjadi eksperimen Android |
| Home widget | 🟡 | Implementasi Android tersedia | Verifikasi pembaruan data dan pengujian perangkat |
| Tagihan berulang | 🟡 | CRUD tersedia | Edit/nonaktif, status eksekusi, idempotency |
| Profil | ✅ | Edit profil, password, loading, dan error state diperkuat | Test integrasi dengan backend |
| Biometrik | ✅ | App unlock opt-in memakai biometrik lokal perangkat | Uji pada perangkat target pilot |
| Verifikasi email | ✅ | Token sekali pakai, resend, email delivery, dan deep link | Uji delivery pada staging |
| Password reset | ✅ | Token sekali pakai, expiry, email delivery, dan deep link | Uji delivery pada staging |
| Mode offline | ⬜ | Belum ada local queue/database | Pending/synced/failed + retry aman |
| Laporan PDF | ⬜ | Belum tersedia | Laporan dapat dibuat dan dibagikan |
| Push notification | ⬜ | FCM belum terpasang | Device registration dan notifikasi relevan |

### Backend dan data

| Area | Status | Kondisi aktual | Bukti selesai berikutnya |
|---|---:|---|---|
| REST API | 🟡 | Validasi, error contract, request ID, dan pagination transaksi tersedia | API versioning dan audit log |
| PostgreSQL | ✅ | Database utama dan constraint dasar tersedia | Migration terkontrol dan backup |
| Nilai uang | ✅ | PostgreSQL `BIGINT`, Prisma `BigInt`, dan Flutter `int` | Pertahankan contract test |
| Authentication | ✅ | Access 15 menit, refresh rotation, revoke, rate limit, reset, dan verifikasi email | Pertahankan integration test |
| Authorization | ✅ | IDOR wallet, transaksi, budget, recurring, session, dan profil diuji lintas akun | Pertahankan test saat resource baru ditambah |
| Redis | ✅ | Menyimpan auth rate limit lintas instance | Tambahkan health/monitoring production |
| Recurring scheduler | 🟡 | Execution record, duplicate protection, dan bulan pendek tersedia | Perlu monitoring dan timezone production |
| AI safety | 🟡 | Mutasi AI berupa draft terkonfirmasi dan output transaksi/struk divalidasi | Privacy dan evaluasi prompt injection |
| Audit trail | ✅ | Auth, profil, session, akun, dan mutasi transaksi tercatat atomik | Tetapkan retensi dan akses admin sebelum production |
| Backend test | 🟡 | Unit test dan recurring integration test tersedia | Perluas ke auth dan seluruh perubahan saldo |
| Observability | 🟡 | Request ID dan access log JSON tersedia | Error tracking dan metrik production |
| Production deployment | ⬜ | Docker Compose development tersedia | Image production, TLS, secrets, migration |

### Proposal dan validasi

| Area | Status | Tindakan |
|---|---:|---|
| Identitas produk | 🟡 | Gunakan “NALA” secara konsisten |
| Target pengguna | 🟡 | Persempit ke mahasiswa 18–24 tahun |
| Riset primer | ⬜ | Survei, wawancara, dan kutipan pengguna asli |
| Usability testing | ⬜ | SUS, task success, time on task, error rate |
| Evaluasi receipt extraction | ⬜ | Dataset struk dan metrik per field |
| Performance testing | ⬜ | p50/p95, error rate, startup/load time |
| Security testing | ⬜ | Checklist OWASP API dan test authorization |
| Klaim dampak | 🟡 | Pisahkan target dari hasil aktual |
| Screenshot aktual | 🟡 | Perbarui setelah UI setiap alur stabil |
| Diagram arsitektur | 🟡 | Gambarkan implementasi modular monolith aktual |

## 4. Gap Proposal yang Harus Diselesaikan

| Klaim lama | Fakta saat ini | Keputusan |
|---|---|---|
| NALA Coach / NALA Dana Kelola | Identitas bercampur | Gunakan nama produk “NALA” |
| Android dan iOS setara | Fitur SMS/widget berorientasi Android | Android-first, iOS sebagai roadmap |
| SharedPreferences untuk token | Sudah memakai secure storage | Perbarui proposal |
| Provider + Flutter Hooks | Hooks tidak digunakan; Provider placeholder | Sebut layered architecture atau hapus dependency |
| Hive dan offline mode | Belum diimplementasikan | Jangan klaim implemented |
| Clean Architecture | Struktur belum mengikuti dependency rule | Sebut feature-oriented layered architecture |
| API Gateway | Tidak ada gateway terpisah | Sebut HTTPS REST API |
| Multer untuk struk | Gambar dikirim dalam Base64 JSON | Dokumentasikan fakta atau ubah implementasi |
| Email verification | Belum tersedia | Implementasikan sebelum menulis panduan final |
| Setup wallet wizard | Backend membuat dompet utama otomatis | Sesuaikan panduan atau implementasikan wizard |
| SMS mengisi transaksi otomatis | Baru deteksi kata sederhana | Jadikan eksperimen, bukan fitur inti |
| Laporan PDF | Belum tersedia | Pertahankan status “planned” |
| Push notification | Belum tersedia | Pertahankan status “planned” |
| AI mencatat transaksi aman | AI langsung menulis transaksi | Ubah menjadi draft + konfirmasi |
| Mode offline partial | Belum ada antrean lokal | Ubah status menjadi “planned” |

## 5. Roadmap Implementasi

Roadmap menggunakan milestone berbasis hasil, bukan tanggal buatan. Satu milestone
ditutup hanya setelah acceptance criteria dan verifikasinya lengkap.

### M0 — Baseline dan konsistensi

Status: **In progress**

- [x] Redesign welcome, login, dashboard, dan profil
- [x] Pindahkan token ke secure storage
- [x] Tambahkan widget test dasar mobile
- [x] Perbaiki workflow CI yang menunjuk ke folder `frontend`
- [x] Tambahkan backend typecheck dan test command ke CI
- [x] Tambahkan migration baseline untuk deployment database kosong
- [ ] Tetapkan istilah produk serta arsitektur yang konsisten
- [ ] Sinkronkan status fitur proposal dengan codebase

Acceptance criteria:

- Working tree bersih dan perubahan terkelompok.
- CI berjalan otomatis pada push dan pull request.
- Tidak ada klaim `implemented` tanpa alur yang dapat didemonstrasikan.

### M1 — Integritas transaksi dan AI

Status: **Complete**

- [x] Migrasikan seluruh nominal dari `Float` ke integer rupiah
- [x] Tambahkan batas nominal dan validasi enum/tanggal
- [x] Tambahkan `idempotencyKey` unik pada pembuatan transaksi
- [x] Ubah AI transaction menjadi draft
- [x] Validasi output transaksi AI dengan schema yang ketat
- [x] Tampilkan form review sebelum transaksi AI disimpan
- [x] Pastikan AI tidak mengatakan “berhasil” sebelum konfirmasi
- [x] Tambahkan timeout dan fallback ketika Gemini gagal
- [x] Tambahkan test untuk perhitungan saldo dan transaksi duplikat

Acceptance criteria:

- Retry request tidak menghasilkan transaksi ganda. ✅
- AI tidak dapat langsung menulis transaksi. ✅
- Nilai uang tersimpan dan dihitung tanpa floating-point. ✅
- Semua jalur perubahan saldo memiliki integration test. ✅

### M2 — Authentication untuk pengguna nyata

Status: **Complete**

- [x] Access token berumur singkat
- [x] Refresh token rotation dan session per perangkat
- [x] Logout/revoke session
- [x] Rate limit login dan registrasi
- [x] Password reset dengan token sekali pakai
- [x] Verifikasi email
- [x] Reauthentication sebelum penghapusan akun
- [x] Biometric app unlock pada perangkat yang mendukung
- [x] CORS production allowlist dan secret tanpa fallback

Acceptance criteria:

- Session dapat dilihat dan dicabut. ✅
- Password berubah menyebabkan session lama tidak lagi dipercaya. ✅
- Endpoint auth memiliki test sukses, gagal, expiry, dan rate limit. ✅
- Secret production wajib berasal dari environment/secret manager. ✅

### M3 — Keandalan fitur inti

Status: **Complete**

- [x] Recurring execution record per tagihan dan periode
- [x] Duplicate protection untuk scheduler
- [x] Perilaku tanggal 29–31 didefinisikan
- [x] Schema validation seluruh endpoint
- [x] Global error response yang konsisten
- [x] Pagination transaksi
- [x] Audit log untuk auth, profil, dan perubahan transaksi
- [x] Loading, empty, error, retry, dan session-expired state

Acceptance criteria:

- Restart atau lebih dari satu instance tidak menggandakan tagihan. ✅
- Semua resource terlindungi ownership check yang diuji. ✅
- Error aman untuk pengguna dan memiliki request ID untuk diagnosis. ✅

### M4 — Tiga inovasi inti

Status: **Planned**

#### Frictionless Financial Capture

- [ ] Input manual selesai dalam alur singkat
- [ ] Receipt extraction menandai field yang tidak yakin
- [ ] Pengguna dapat mengoreksi hasil sebelum menyimpan
- [ ] Impor screenshot/share sebagai alternatif SMS
- [ ] Deteksi SMS diposisikan sebagai eksperimen Android

#### Explainable Financial Habit Score

- [ ] Hapus diversifikasi pengeluaran sebagai indikator kesehatan
- [ ] Tetapkan komponen dan bobot yang dapat dijelaskan
- [ ] Tangani pemasukan nol, tanpa budget, dan pengguna baru
- [ ] Jelaskan penyebab perubahan skor
- [ ] Beri satu hingga tiga tindakan yang relevan
- [ ] Simpan histori skor untuk evaluasi perubahan

#### Context-Aware AI Coach

- [ ] Kirim ringkasan minimum, bukan seluruh data mentah
- [ ] Redaksi data personal yang tidak diperlukan
- [ ] Batasi panjang input dan frekuensi request
- [ ] Validasi output terstruktur
- [ ] Sediakan fallback tanpa AI
- [ ] Konfirmasi eksplisit untuk semua mutasi data

Acceptance criteria:

- Ketiga alur dapat didemonstrasikan end-to-end.
- Pengguna selalu dapat memeriksa dan membatalkan perubahan.
- Kegagalan AI tidak menghalangi pencatatan manual.

### M5 — Pengujian dan validasi nasional

Status: **Planned**

- [ ] Survei kuantitatif dengan responden asli
- [ ] Wawancara mendalam dan kutipan anonim
- [ ] Usability test dengan tugas yang konsisten
- [ ] Pilot penggunaan 14–30 hari
- [ ] Evaluasi receipt extraction pada dataset representatif
- [ ] Functional test report
- [ ] Performance test report
- [ ] Security checklist dan hasil test
- [ ] Screenshot serta video aplikasi aktual

Acceptance criteria:

- Semua angka proposal dapat ditelusuri ke data mentah atau laporan.
- Target dan hasil aktual ditampilkan terpisah.
- Tidak ada persentase atau test result yang direkayasa.

### M6 — Release beta

Status: **Planned**

- [ ] Production Docker image
- [ ] Database migration terkontrol
- [ ] Staging dan production environment
- [ ] HTTPS/TLS
- [ ] Secret management
- [ ] Structured logging dan error tracking
- [ ] Backup serta restore test PostgreSQL
- [ ] Privacy notice, consent, export, dan delete data
- [ ] Signed Android build dan internal testing

Acceptance criteria:

- Deployment dapat diulang dan di-rollback.
- Backup pernah diuji untuk restore.
- Crash/error production dapat dilacak tanpa membocorkan data sensitif.
- Build beta dapat dipasang oleh peserta pilot.

## 6. Metrik Keberhasilan

Angka berikut adalah **target**, bukan hasil aktual.

### Produk dan usability

| Metrik | Target awal | Metode |
|---|---:|---|
| Task success pencatatan manual | ≥90% | Usability test |
| Task success scan dan koreksi struk | ≥85% | Usability test |
| SUS score | ≥75 | Kuesioner SUS |
| Waktu median input manual | ≤35 detik | Event timestamp |
| Waktu median scan sampai review | ≤15 detik | Event timestamp |
| Retensi pilot hari ke-14 | ≥50% | Cohort pilot |

### Receipt extraction

| Metrik | Target awal |
|---|---:|
| Akurasi nominal | ≥90% |
| Akurasi merchant | ≥85% |
| Akurasi tanggal | ≥80% |
| Akurasi kategori | ≥75% |
| Full-record exact match | Diukur, tanpa target palsu |
| Latensi p95 | ≤10 detik |

### Engineering

| Metrik | Target awal |
|---|---:|
| Test jalur transaksi kritis | 100% memiliki test |
| API error rate saat uji beban | <1% |
| Dashboard load p95 pada skenario uji | ≤2 detik |
| Duplicate transaction pada retry test | 0 |
| Critical security finding terbuka | 0 |
| CI pada branch utama | Selalu lulus sebelum demo |

### Dampak pilot

Hasil hanya ditulis setelah pilot. Kandidat metrik:

- Persentase pengguna yang lebih memahami pengeluaran terbesar.
- Perubahan konsistensi pencatatan.
- Perubahan kepatuhan terhadap budget.
- Perubahan indikator kebiasaan finansial.
- Persentase rekomendasi Nala yang dianggap dapat dilakukan.

## 7. Rencana Pengujian

### Functional

- Auth: register, login, expiry, refresh, logout, reset password.
- Wallet: ownership, saldo awal, edit, dan penghapusan.
- Transaction: create, update, reversal, duplicate, dan concurrency.
- Budget: batas, bulan/tahun, dan kategori.
- Recurring: eksekusi sekali per periode dan edge case tanggal.
- AI/OCR: valid, invalid, timeout, malformed JSON, dan fallback.

### Usability

Tugas minimum:

1. Membuat akun dan dompet pertama.
2. Mencatat pengeluaran manual.
3. Scan struk, mengoreksi hasil, lalu menyimpan.
4. Membuat budget makan.
5. Memahami alasan perubahan Financial Habit Score.
6. Meminta saran Nala dan mengonfirmasi draft transaksi.

### Performance

- Startup dan dashboard load.
- `GET /transactions`.
- `POST /transactions`.
- Financial score calculation.
- Receipt extraction latency.
- Request bersamaan pada wallet yang sama.

### Security

- Invalid/expired JWT.
- IDOR seluruh resource.
- Brute-force login.
- Payload dan upload berukuran ekstrem.
- Output AI berbahaya atau tidak sesuai schema.
- Prompt injection dari teks struk.
- Sensitive data pada log.
- Dependency audit.

## 8. Privasi dan Data

| Data | Penyimpanan/pemroses | Tujuan | Retensi target | Perlindungan |
|---|---|---|---|---|
| Email | PostgreSQL | Identitas dan autentikasi | Selama akun aktif | Access control |
| Password | PostgreSQL | Autentikasi | Selama akun aktif | Hash bcrypt/Argon2id |
| Token | Keystore/Keychain | Session | Sampai expiry/revoke | Secure storage |
| Transaksi | PostgreSQL | Fitur inti | Selama akun aktif | Ownership authorization |
| Foto struk | Backend/Gemini sementara | Ekstraksi | Hapus setelah proses/≤24 jam | HTTPS dan minimalisasi |
| Ringkasan keuangan | Backend/Gemini | Insight kontekstual | Minimum yang diperlukan | Redaksi PII |
| SMS/notifikasi | Perangkat | Eksperimen impor | Tidak dikirim mentah | Consent dan izin |
| Event usability | Analytics/pilot dataset | Evaluasi produk | Selama studi | Pseudonimisasi |

Sebelum pilot, pengguna harus mengetahui data apa yang diproses, tujuannya,
cara mencabut izin, dan cara menghapus akun.

## 9. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi | Prioritas |
|---|---|---|---:|
| AI membuat transaksi salah | Saldo dan kepercayaan rusak | Draft, schema validation, konfirmasi | P0 |
| Float menghasilkan nominal tidak presisi | Data finansial salah | Integer rupiah dan migration test | P0 |
| Request ganda | Transaksi duplikat | Idempotency key dan unique constraint | P0 |
| Cron berjalan pada beberapa instance | Tagihan ganda | Execution record dan unique period | P0 |
| Token dicuri/tidak dapat dicabut | Account takeover | Refresh rotation dan revoke session | P0 |
| Izin SMS ditolak Play Store | Distribusi gagal | Screenshot/share; SMS eksperimen | P1 |
| Gemini timeout/hallucination | Alur gagal atau data salah | Timeout, fallback, review | P1 |
| Klaim proposal tidak terbukti | Kredibilitas turun | Traceability dan laporan aktual | P0 |
| Tidak ada riset primer | Relevansi produk diragukan | Survei, wawancara, pilot | P0 |
| Scope terlalu besar | Fitur inti tidak stabil | Bekukan fitur di luar tiga inovasi | P0 |

## 10. Definition of Done

Sebuah fitur hanya boleh ditandai **Implemented** apabila:

- [ ] Alur utama bekerja end-to-end.
- [ ] Input dan error pada trust boundary ditangani.
- [ ] Loading, empty, error, dan retry state tersedia jika relevan.
- [ ] Data pengguna lain tidak dapat diakses.
- [ ] Jalur kritis memiliki minimal satu automated test.
- [ ] Tidak ada analyzer/typecheck error.
- [ ] Acceptance criteria diverifikasi.
- [ ] Screenshot/video aktual tersedia untuk fitur proposal.
- [ ] Dokumentasi dan status proposal diperbarui.

Selain itu:

- **Partial** berarti sebagian alur bekerja tetapi belum memenuhi Definition of Done.
- **Planned** berarti belum dapat didemonstrasikan.
- **Validated** hanya digunakan setelah ada hasil pengguna atau pengujian aktual.

## 11. Prioritas Backlog

### P0 — kerjakan sebelum fitur baru

1. AI draft + konfirmasi.
2. Integer rupiah.
3. Idempotency transaksi.
4. Recurring execution safety.
5. CI yang benar-benar berjalan.
6. Backend integration test.
7. Sinkronisasi klaim proposal.
8. Rencana dan pelaksanaan riset pengguna.

### P1 — sebelum pilot

1. Schema validation dan global error handler.
2. Session/refresh token.
3. Password reset dan email verification.
4. Formula Financial Habit Score baru.
5. Receipt review dan evaluasi.
6. Audit log dasar.
7. Structured logging dan error tracking.
8. Privacy notice dan consent.

### P2 — setelah alur inti stabil

1. Offline queue.
2. Laporan PDF.
3. Push notification.
4. Biometric app unlock.
5. Screenshot/share import.
6. Production deployment.

### Tidak dikerjakan untuk versi kompetisi

- Microservices
- Kafka
- Kubernetes
- gRPC
- Shared budget
- Investasi
- Pembayaran/QRIS
- Core banking adapter
- Gamifikasi besar
- Native Android dan iOS terpisah

## 12. Traceability Proposal

Setiap klaim penting pada proposal final harus memiliki bukti:

| Klaim | Bukti yang diterima | Lokasi bukti |
|---|---|---|
| Fitur implemented | Test + screenshot/video aktual | Repo dan deliverable |
| Akurasi receipt extraction | Dataset + hasil evaluasi per field | Laporan evaluasi |
| Usability | Raw response + kalkulasi SUS | Laporan usability |
| Performance | Script + hasil p50/p95 | Laporan performance |
| Security | Checklist + test output | Laporan security |
| Dampak | Baseline dan hasil pilot | Laporan pilot |
| Arsitektur | Diagram sesuai deployment aktual | Proposal |
| Privasi | Data flow dan consent | Proposal/aplikasi |

## 13. Cara Memperbarui Dokumen

Pada akhir setiap sesi pengembangan:

1. Perbarui checkbox milestone yang benar-benar selesai.
2. Tambahkan atau ubah bukti pada tabel kondisi aktual.
3. Jangan mengubah target menjadi hasil tanpa data.
4. Catat keputusan yang mengubah scope pada bagian berikut.
5. Sinkronkan status proposal setelah fitur memenuhi Definition of Done.

### Log verifikasi

| Tanggal | Perubahan | Bukti |
|---|---|---|
| 30 Juli 2026 | AI Coach diubah menjadi draft + konfirmasi | Backend typecheck, 1 backend test, Flutter analyzer, 7 Flutter test |
| 30 Juli 2026 | Nominal dimigrasikan dari floating-point ke integer rupiah | 4 kolom PostgreSQL bertipe `bigint`, 2 backend test, 8 Flutter test |
| 30 Juli 2026 | Pembuatan transaksi dilindungi idempotency key | Unique constraint database, backend test, Flutter key test, dan API replay smoke test |
| 30 Juli 2026 | Scheduler tagihan dilindungi marker eksekusi per periode | Unique constraint, backend test, dan pemanggilan scheduler dua kali |
| 30 Juli 2026 | Tagihan tanggal 29–31 diproses pada hari terakhir bulan pendek | Unit test bulan biasa, kabisat, dan bulan 30 hari |
| 30 Juli 2026 | Input transaksi dibatasi dan divalidasi konsisten | Typecheck dan unit test nominal, tipe, tanggal kalender, serta limit list |
| 30 Juli 2026 | Jalur HTTP transaksi diuji end-to-end | Login, validasi input, create, replay, conflict, perubahan saldo sekali, delete, dan pemulihan saldo |
| 30 Juli 2026 | Gemini dan klien chat diberi batas waktu serta fallback aman | Unit test timeout; kegagalan AI menghasilkan respons tanpa transaction draft |
| 30 Juli 2026 | Workflow CI diselaraskan dengan codebase aktual | Job backend menjalankan PostgreSQL, typecheck, unit dan integration test; job mobile menjalankan analyze dan test |
| 30 Juli 2026 | Rantai migration dapat membangun PostgreSQL kosong | Baseline schema diikuti migrasi integer, idempotency, dan recurring execution |
| 30 Juli 2026 | Ownership wallet tagihan berulang dipaksa di backend | Integration test lintas akun menolak wallet milik user lain dengan 404 |
| 30 Juli 2026 | Seluruh jalur saldo runtime diaudit | HTTP test saldo awal wallet, transaksi create/update/delete, recurring, dan penolakan edit langsung |
| 30 Juli 2026 | Penghapusan akun memerlukan password aktif | HTTP test menolak password kosong/salah dan menerima password benar; UI meminta password |
| 30 Juli 2026 | Login dan registrasi dilindungi rate limit | Redis multi-instance limiter dengan fallback memory; integration test login menghasilkan 429 |
| 30 Juli 2026 | Authentication memakai session dan refresh rotation | Access 15 menit, refresh hash 30 hari, rotasi, daftar perangkat, logout/revoke, dan invalidasi setelah ganti password diuji |
| 30 Juli 2026 | Konfigurasi production dibuat fail-fast | JWT secret minimal 32 karakter dan CORS allowlist wajib; native request tanpa Origin tetap didukung |
| 30 Juli 2026 | Inti password reset sekali pakai tersedia | Token acak disimpan sebagai hash, berlaku 15 menit, sekali pakai, anti-enumerasi, dan revoke session; delivery email masih pending |
| 30 Juli 2026 | Delivery email reset password tersedia | Resend HTTP API, timeout 8 detik, idempotency key, fail-fast config production, dan token dihapus jika delivery gagal |
| 30 Juli 2026 | Reset password tersambung ke mobile | Tombol lupa password, form password baru, route web, dan Android deep link `nala://reset-password` |
| 30 Juli 2026 | Verifikasi email diwajibkan sebelum login | Token hash sekali pakai 24 jam, resend anti-enumerasi, delivery email, dan migration akun lama |
| 30 Juli 2026 | Biometric app unlock tersedia | Plugin resmi local_auth, opt-in dari profil, secure session unlock, dan native Android configuration |
| 30 Juli 2026 | Schema validation endpoint fitur inti diselesaikan | Typecheck, 11 unit test, dan HTTP integration test menolak payload invalid pada wallet, budget, recurring, chat, OCR, serta transaksi |
| 31 Juli 2026 | Error API dan request tracing diseragamkan | Unit test kontrak error; HTTP test validasi, malformed JSON, 404, header `X-Request-ID`, dan integration suite lulus |
| 31 Juli 2026 | Histori transaksi memakai cursor pagination | Unit test cursor, HTTP test dua halaman tanpa duplikat, dashboard limit 20, 15 Flutter test, dan integration suite lulus |
| 31 Juli 2026 | Audit trail keamanan dan finansial tersedia | Migration terkontrol; integration test request ID untuk profil/transaksi, create-update-delete transaksi, scheduler, dan audit akun terhapus |
| 31 Juli 2026 | State kegagalan mobile dan session recovery disatukan | Shared authenticated client, refresh rotation lock, global session-expired redirect, retry UI, empty state transaksi, analyzer, dan 17 Flutter test |
| 31 Juli 2026 | M3 ditutup dengan pengujian IDOR lintas akun | HTTP test read/update/delete wallet dan transaksi, budget, recurring, session, mass-assignment profil, serta verifikasi resource pemilik tetap utuh |
| 31 Juli 2026 | Startup Flutter Web diverifikasi | Plugin home widget dibatasi ke platform native; Chrome debug aktif dan 17 Flutter test lulus |
| 31 Juli 2026 | Home dan navigation shell dimodernisasi | Segmented shortcut, kartu fitur berwarna, icon Material modern, radius kartu konsisten, serta bottom navigation kapsul mengambang tanpa dependency baru |
| 31 Juli 2026 | Bottom navigation diselaraskan dengan segmented control | Tab aktif memakai kapsul lime, elevasi diperhalus, dan tombol catat tetap menjadi aksi utama di tengah |
| 31 Juli 2026 | Segmented control home menjadi navigasi konten | Kapsul aktif bergeser tanpa fade; Ringkasan, Aktivitas, dan Perkembangan menampilkan kelompok data NALA yang berbeda |
| 31 Juli 2026 | Transisi tab home dipindahkan ke PageView | Konten tidak lagi bertumpuk; tab dapat ditekan atau di-swipe dan indikator mengikuti posisi halaman secara kontinu |
| 31 Juli 2026 | Header home disederhanakan | Placeholder logo diganti icon profil outline dan sapaan personal satu baris agar lebih jelas serta hemat ruang |
| 31 Juli 2026 | Tipografi sapaan home diperhalus | Ukuran dan bobot sapaan diturunkan agar header tidak terlalu dominan |
| 31 Juli 2026 | Kartu saldo diubah menjadi kartu dana NALA | Badge icon dihapus; identitas wallet, status utama, saldo privat, dan pola geometris menggantikan kartu gradient generik |
| 31 Juli 2026 | Halaman Transaksi diselaraskan dengan Home | Request saldo duplikat dihapus; header, ringkasan arus kas, filter segmented, empty state, dan kartu aktivitas memakai bahasa visual NALA |
| 31 Juli 2026 | Density layout Transaksi diperhalus | Heading dan angka diringkas, action button diperkecil, summary dipadatkan, serta empty state dipindahkan dekat filter |
| 31 Juli 2026 | Halaman Laporan diselaraskan dengan Home | Metrik dan grafik dipadatkan, font Inter diterapkan, error/empty state ditambahkan, serta badge palsu dan tombol ekspor nonfungsional dihapus |
| 31 Juli 2026 | Halaman Profil diselaraskan dengan Home | Identitas pengguna menjadi card horizontal; menu duplikat dihapus dan pengaturan dikelompokkan menjadi Keuangan, Keamanan, serta aksi logout terpisah |
| 31 Juli 2026 | Form Tambah/Edit Transaksi diselaraskan dengan Home | Nominal menjadi fokus, detail dikelompokkan dalam card, segmented control dan tipografi dipadatkan, serta loading/error wallet diperbaiki |
| 31 Juli 2026 | Alur Scan Struk diselaraskan dengan Home | Scanner menjadi workspace terang, review OCR dikelompokkan dalam card, validasi nominal ditambahkan, serta loading/error wallet dan pesan gagal diamankan |
| 31 Juli 2026 | Halaman Budget diselaraskan dengan Home | Ringkasan total dan jumlah kategori ditambahkan, card batas kategori dipadatkan tanpa progress palsu, empty state dan form dibuat konsisten, serta nominal positif divalidasi |
| 31 Juli 2026 | Halaman Bank & Dompet diselaraskan dengan Home | Total dana dan jumlah akun diringkas, card wallet tanpa icon memakai penanda jenis, label enum dinormalisasi, serta form dan saldo awal opsional dirapikan |
| 31 Juli 2026 | Halaman Tagihan Berulang diselaraskan dengan Home | Total bulanan dan jadwal tanggal diringkas, card dibuat mudah dipindai, hapus wajib konfirmasi, kategori form diaktifkan, serta loading wallet dan validasi dibenahi |
| 31 Juli 2026 | Financial Habit Score diselaraskan dengan Home | Skor dan chart dipadatkan, simbol kelulusan dihapus, faktor menjadi daftar progress, disclaimer non-kredit ditambahkan, serta CTA Nala Chat diperhalus |
| 31 Juli 2026 | Nala Chat diselaraskan dengan Home | Bubble, avatar AI, loader, quick prompts, input, dan CTA dipadatkan; aksi kosong dihapus, pengiriman ganda dicegah, dan jalur draft-konfirmasi dipertahankan |
| 31 Juli 2026 | Edit Profil diselaraskan dengan Home | Avatar dan form dikelompokkan dalam card, tipografi dipadatkan, error gambar diamankan, serta hapus akun dipindahkan ke zona berbahaya dengan reauthentication tetap wajib |
| 31 Juli 2026 | Register dan Verifikasi Email diselaraskan dengan Login | Register memakai logo, card, field, dan tipografi auth yang sama; hasil verifikasi menjadi card dan kegagalan dapat dicoba ulang |
| 31 Juli 2026 | Reset Password diselaraskan dengan Login | Form memakai logo dan card auth yang sama, kedua password dapat diperiksa, autofill didukung, dan submit dari keyboard tetap aman |
| 31 Juli 2026 | Onboarding dan Splash menutup konsistensi auth | Splash memakai aset dan tipografi auth yang sama; onboarding diperhalus dan tombol biometrik semu dihapus karena aktivasi biometrik hanya tersedia setelah login |
| 31 Juli 2026 | Audit navigasi dan responsive layout | Tombol tengah navbar kini membuka Tambah Transaksi sesuai simbol plus, Back dari tab sekunder kembali ke Beranda, dan callback navigasi Laporan yang mati dihapus |
| 31 Juli 2026 | Hover Pilihan Cepat diperhalus | Overlay abu-abu pada Chrome dihilangkan agar icon tetap flat tanpa bayangan saat pointer berada di atas tombol |
| 31 Juli 2026 | Identitas Splash diperbarui | Logo utama memakai `Nala baru.png`; identitas NALA, GEMASTIK 2026, Teknik Informatika 2023, Fakultas Teknik, dan Universitas Sam Ratulangi ditempatkan kecil di bagian bawah |
| 31 Juli 2026 | Komposisi Splash dipusatkan | Logo diperkecil dan seluruh identitas disatukan menjadi satu kelompok center agar hierarki serta jarak antar-elemen lebih rapi |
| 1 Agustus 2026 | Alignment Splash dikunci ke viewport | Logo memakai center absolut berukuran 88 px, sedangkan blok identitas dikunci simetris di bagian bawah agar keduanya tidak saling menggeser |
| 1 Agustus 2026 | Spacing dan scroll Home disempurnakan | Mengetuk tab aktif mengembalikan konten ke atas, kartu memakai radius/border konsisten tanpa shadow, ruang bawah ditambah, dan nominal panjang diamankan |
| 1 Agustus 2026 | Bottom navigation dinaikkan | Jarak bawah SafeArea ditambah 6 px agar navbar tidak terlalu dekat dengan home indicator iOS |
| 1 Agustus 2026 | Indikator bottom navigation dibuat sliding | Kapsul lime kini bergeser 320 ms dengan kurva yang sama seperti segmented control Home tanpa mengganti state halaman |
| 1 Agustus 2026 | Halaman utama memakai PageView | Konten bergeser bersama indikator navbar, halaman dibangun bertahap untuk mengurangi beban awal, dan state halaman yang sudah dibuka dipertahankan |
| 1 Agustus 2026 | Katalog wallet diberi cache per sesi | Tambah Transaksi dapat tampil tanpa request ulang setelah Dashboard dimuat; request bersamaan dideduplikasi dan cache dibersihkan pada pergantian sesi |
| 1 Agustus 2026 | Loading wallet tidak lagi memblokir flow | Scanner dan form Tagihan Berulang langsung tampil; status loading/error dibatasi pada field sumber dana dengan retry lokal |
| 1 Agustus 2026 | Lompatan tab utama dipangkas menjadi satu halaman | Navigasi non-berurutan tidak lagi menganimasikan dan membangun seluruh halaman perantara; efek geser satu langkah tetap dipertahankan |
| 1 Agustus 2026 | Query histori dibatasi rentang waktu | Aktivitas hanya mengambil bulan terpilih dan Laporan hanya mengambil tiga bulan yang divisualisasikan; endpoint memvalidasi batas `from`/`to` sebelum query database |

### Log keputusan

| Tanggal | Keputusan | Alasan |
|---|---|---|
| 30 Juli 2026 | Android menjadi platform prototipe utama | Fitur SMS dan widget bersifat platform-specific |
| 30 Juli 2026 | Modular monolith dipertahankan | Lebih sederhana dan cukup untuk beta/pilot |
| 30 Juli 2026 | Fokus dibatasi pada tiga inovasi inti | Menghindari feature dump dan memperkuat bukti |
| 30 Juli 2026 | Financial Health Score diarahkan menjadi Financial Habit Score | Tidak diklaim sebagai diagnosis atau skor tervalidasi ilmiah |
| 30 Juli 2026 | AI wajib memakai draft dan konfirmasi | Melindungi integritas data finansial |
| 30 Juli 2026 | Nominal disimpan sebagai BIGINT dan dikirim sebagai integer JSON | Rupiah tidak membutuhkan pecahan dan batasnya melampaui PostgreSQL INT |
| 30 Juli 2026 | Idempotency transaksi dijamin unique constraint PostgreSQL | Perlindungan tetap berlaku pada restart dan banyak instance backend |
| 30 Juli 2026 | RecurringExecution dipisahkan dari Transaction | Marker periode tetap ada walaupun transaksi hasil scheduler dihapus |

## 14. Langkah Berikutnya

Pekerjaan coding berikutnya berada di **M4 — Tiga inovasi inti**:

1. Mulai frictionless capture dari receipt review dan koreksi sebelum simpan.
2. Tambahkan confidence/field warning pada hasil ekstraksi struk.
3. Revisi formula Explainable Financial Habit Score dan test edge case.
4. Minimalkan konteks sensitif yang dikirim ke AI Coach.
