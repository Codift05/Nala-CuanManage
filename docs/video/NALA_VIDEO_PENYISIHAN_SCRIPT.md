# NALA — Naskah Video Penyisihan GEMASTIK XIX 2026

## 1. Konsep

**Format:** product story dan demonstrasi aplikasi aktual  
**Durasi target:** 2 menit 50 detik  
**Batas mutlak:** 3 menit  
**Rasio:** 16:9, 1920 × 1080, 30 fps  
**Nada:** profesional, hangat, ringkas, dan berbasis bukti  
**Pesan utama:** NALA membantu mahasiswa menangkap, memahami, dan memperbaiki
kebiasaan finansial melalui pencatatan minim friksi, Habit Score yang dapat
dijelaskan, dan AI yang tetap berada di bawah kontrol pengguna.

Video menggunakan rekaman aplikasi aktual. Mockup, dataset sintetis, dan hasil
pengujian harus diberi label. Jangan menampilkan fitur planned seolah sudah
tersedia atau menyebut demo sebagai bukti dampak pengguna.

## 2. Struktur Wajib

| Ketentuan | Bagian video |
|---|---|
| Proses perancangan perangkat lunak | 00:30–00:58 |
| Kemajuan minimal 50% | 00:58–01:13 |
| Mengapa aplikasi berguna | 00:08–00:30 dan 02:30–02:43 |
| Cara pengguna memakai aplikasi | 01:13–02:30 |
| Maksimal 3 menit | Target final 02:50, termasuk title dan credit |
| YouTube dan tautan proposal | Checklist publikasi pada akhir dokumen |

## 3. Storyboard dan Voice-Over

### 00:00–00:08 — Pembuka

**Visual**

- Latar putih dengan logo NALA kecil di tengah.
- Judul muncul halus: “NALA — Pendamping Kebiasaan Finansial Mahasiswa”.
- Subjudul: “GEMASTIK XIX 2026 · Pengembangan Perangkat Lunak”.
- Transisi menuju welcome screen aplikasi.

**Voice-over**

> Bagi mahasiswa, masalah keuangan sering bukan sekadar berapa uang yang
> dimiliki, tetapi bagaimana kebiasaan kecil dicatat, dipahami, dan diperbaiki.

### 00:08–00:30 — Masalah dan Kegunaan

**Visual**

- Tiga potongan situasi sederhana: transaksi kecil, struk, dan saldo beberapa
  sumber dana.
- Gunakan motion graphic minimal: “Lupa mencatat”, “Sulit memahami pola”, dan
  “Saran terlalu umum”.
- Tampilkan loop `Capture → Understand → Act`.

**Voice-over**

> Transaksi kecil mudah terlewat. Ketika pencatatan terasa merepotkan, laporan
> menjadi tidak lengkap dan saran keuangan kehilangan konteks. NALA dirancang
> untuk mahasiswa melalui satu siklus sederhana: menangkap aktivitas dengan
> minim friksi, memahami faktor kebiasaan secara transparan, lalu mengambil
> tindakan kecil yang relevan.

**Teks layar**

`Capture · Understand · Act`

### 00:30–00:58 — Proses Perancangan Perangkat Lunak

**Visual**

- Diagram Agile iteratif NALA dirender, bukan menampilkan source PlantUML.
- Sorot tahap: Discover, Prioritize, Design, Build, Verify, Review.
- Potongan cepat artefak aktual:
  - product engineering plan;
  - user journey dan use case;
  - arsitektur modular monolith;
  - ERD;
  - test dan CI.
- Setiap artefak ditampilkan maksimal 2–3 detik dengan zoom yang terbaca.

**Voice-over**

> NALA dikembangkan secara iteratif dan berbasis risiko. Kami memulai dari data
> dan kebutuhan mahasiswa, menyusun user journey serta acceptance criteria,
> merancang antarmuka, API, dan model data, kemudian membangun increment kecil.
> Setiap increment diverifikasi melalui static analysis, unit, widget,
> contract, security, dan integration test sebelum hasilnya direview dan masuk
> ke iterasi berikutnya.

**Teks layar**

`Discover → Prioritize → Design → Build → Verify → Review`

### 00:58–01:13 — Bukti Kemajuan

**Visual**

- Tampilkan satu angka utama: **“Implementasi inti 92,3%”**.
- Angka muncul di dalam lingkaran tipis dengan animasi progress yang lembut.
- Di sekelilingnya muncul empat bukti singkat: **Aplikasi berjalan**, **REST API
  terintegrasi**, **Automated testing**, dan **Deployment baseline**.
- Potongan repository, migration, test, dan CI cukup menjadi montage latar;
  jangan menampilkan daftar pekerjaan yang belum selesai.
- Footer kecil: “48 dari 52 checklist implementasi inti · 3 Agustus 2026”.

**Voice-over**

> Saat ini, 92,3 persen ruang lingkup implementasi inti telah diselesaikan dan
> dapat ditelusuri melalui aplikasi, REST API, migration database, automated
> testing, serta deployment baseline. NALA telah melampaui kemajuan minimum
> penyisihan dan siap didemonstrasikan melalui alur utama yang terintegrasi.

### 01:13–01:28 — Masuk dan Ringkasan

**Visual**

- Rekam welcome screen.
- Tekan “Masuk ke NALA”; bottom sheet bergerak naik.
- Gunakan akun demo tanpa memperlihatkan password.
- Masuk ke Beranda dan tampilkan segmented navigation, wallet card, quick
  action, insight, dan transaksi terbaru.

**Voice-over**

> Pengguna memulai dari akses yang ringkas. Setelah masuk, Beranda menyatukan
> saldo internal, pilihan cepat, insight, dan transaksi terbaru dalam hierarki
> yang konsisten.

**Label footer**

`Dataset demonstrasi sintetis`

### 01:28–01:52 — Frictionless Capture

**Visual**

- Tekan Scan.
- Pilih satu struk sintetis dari galeri.
- Potong waktu tunggu secara wajar, beri label “dipersingkat”.
- Tampilkan hasil ekstraksi, confidence/warning, koreksi satu field, pilih
  wallet, lalu simpan.
- Munculkan callout: “AI menyiapkan draf — pengguna mengonfirmasi”.

**Voice-over**

> Pencatatan dapat dilakukan manual, melalui tagihan berulang, percakapan, atau
> pemindaian struk. Pada struk, AI hanya menyiapkan draf. Confidence dan warning
> membantu pengguna memeriksa nominal, merchant, serta kategori sebelum data
> disimpan. Tidak ada mutasi finansial tanpa konfirmasi.

### 01:52–02:10 — Explainable Financial Habit Score

**Visual**

- Buka halaman Financial Habit Score.
- Tampilkan skor demo 85, status, dan disclaimer non-kredit.
- Scroll perlahan melalui tiga faktor, alasan, tindakan, dan tren 60–85–85.
- Highlight bergantian: Rasio simpan, Kepatuhan budget, Konsistensi mencatat.

**Voice-over**

> NALA tidak berhenti pada grafik. Financial Habit Score menjelaskan tiga
> faktor: rasio simpan, kepatuhan budget, dan konsistensi mencatat. Faktor yang
> belum memiliki data tidak diberi nilai buatan. Pengguna dapat melihat alasan,
> tindakan berikutnya, serta perubahan antarbulan. Skor ini bukan credit score.

### 02:10–02:30 — AI Coach dengan Safe Draft

**Visual**

- Buka Nala AI Coach.
- Masukkan prompt standar:
  “Aku membayar makan siang Rp35.000 dari GoPay. Bantu catat dan jelaskan
  pengaruhnya pada budget makan.”
- Tampilkan jawaban dan transaction draft.
- Buka review, lalu demonstrasikan tombol batal atau konfirmasi.
- Callout: “Konteks minimum · schema validation · human confirmation”.

**Voice-over**

> AI Coach menggunakan konteks minimum untuk memberi penjelasan yang relevan.
> Jika percakapan mengandung transaksi, output wajib lolos kontrak terstruktur
> dan kembali sebagai safe draft. Pengguna tetap memeriksa dan menentukan
> apakah transaksi dibatalkan atau disimpan.

### 02:30–02:43 — Nilai dan Dampak yang Dituju

**Visual**

- Montage singkat: budget, laporan, privacy notice, ekspor data, dan profil.
- Tampilkan tiga kata: “Ringkas”, “Dapat dijelaskan”, “Terkendali”.

**Voice-over**

> Dengan menghubungkan pencatatan, pemahaman, dan tindakan, NALA ditujukan untuk
> membantu mahasiswa membangun kebiasaan finansial yang lebih sadar. Privasi,
> explainability, dan kontrol pengguna menjadi bagian dari desain, bukan fitur
> tambahan di akhir.

### 02:43–02:50 — Penutup

**Visual**

- Logo NALA.
- Teks:
  - `NALA · Dana Kelola`
  - `Universitas Sam Ratulangi`
  - `Fakultas Teknik · Teknik Informatika`
  - `GEMASTIK XIX 2026`
- Credit kecil: “Ketua dan Software Developer Utama: Miftahuddin S. Arsyad”.

**Voice-over**

> NALA. Kelola kebiasaan finansial dengan lebih sadar, satu tindakan kecil pada
> satu waktu.

## 4. Daftar Rekaman yang Diperlukan

| ID | Rekaman | Durasi mentah yang disarankan |
|---|---|---:|
| V01 | Logo dan welcome | 10 detik |
| V02 | Authentication sheet dan login | 15 detik |
| V03 | Beranda dan segmented navigation | 20 detik |
| V04 | Scan struk sampai receipt review | 40 detik |
| V05 | Koreksi dan konfirmasi transaksi | 20 detik |
| V06 | Habit Score, faktor, tindakan, tren | 35 detik |
| V07 | AI Coach dan safe draft | 45 detik |
| V08 | Aktivitas dan Laporan | 20 detik |
| V09 | Profil, privacy notice, dan ekspor | 20 detik |
| V10 | Artefak perancangan, test, CI, repository | 35 detik |

Rekam durasi mentah lebih panjang daripada shot final agar editor dapat memilih
gerakan yang stabil. Gunakan satu commit dan jalankan ulang demo seed sebelum
merekam V03–V09.

## 5. Pedoman Visual dan Editing

- Gunakan warna NALA: oranye sebagai aksen, lime untuk state terpilih, putih
  dan abu muda sebagai bidang utama.
- Gunakan font Inter atau keluarga sans-serif yang sama dengan aplikasi.
- Bangun suasana visual yang hangat dan optimistis: latar putih susu, gradient
  oranye lembut, bentuk lingkaran transparan, serta detail lime secukupnya.
- Gunakan ilustrasi kota dan elemen koin NALA sebagai motif penghubung antarbab,
  tetapi pertahankan opacity rendah agar tidak mengganggu rekaman aplikasi.
- Letakkan rekaman aplikasi di dalam bidang putih dengan radius sudut besar dan
  bayangan sangat tipis; hindari bingkai ponsel 3D yang berat.
- Untuk judul bab, gunakan komposisi sederhana: nomor kecil, judul dua sampai
  empat kata, dan satu garis aksen oranye.
- Progress 92,3% dianimasikan satu kali dengan easing lembut, kemudian berubah
  menjadi empat kartu bukti implementasi.
- Hindari template teknologi dengan neon, partikel, mockup 3D, dan transisi
  berlebihan.
- Gunakan cut, dissolve pendek, serta slide horizontal yang konsisten dengan
  gerak aplikasi.
- Kecepatan animasi teks sekitar 200–350 ms; jangan membuat teks memantul.
- Maksimal satu kalimat pendek pada satu overlay.
- Gunakan zoom 105–115% hanya untuk memperjelas field penting.
- Gunakan musik instrumental ringan tanpa vokal dan dengan lisensi yang dapat
  dibuktikan; volume sekitar 15–20% di bawah voice-over.
- Voice-over harus dominan, bebas noise, dan menggunakan subtitle Bahasa
  Indonesia.
- Jangan mempercepat interaksi hingga tidak realistis. Jika waktu tunggu
  dipotong, tampilkan label “proses dipersingkat”.

### Arah visual per segmen

| Segmen | Gaya visual |
|---|---|
| Pembuka | Logo muncul melalui fade dan scale 96–100%, diikuti garis gradient oranye |
| Masalah | Tiga kartu kecil dengan ikon struk, transaksi, dan insight; tidak memakai footage sedih atau dramatis |
| Proses desain | Diagram berbentuk lintasan melingkar dengan satu tahap aktif bergantian |
| Progres | Angka 92,3% sebagai hero, lalu empat kartu bukti masuk berurutan |
| Demo aplikasi | Screen recording menjadi fokus; callout hanya untuk tindakan penting |
| Habit Score | Faktor muncul sebagai tiga label ringan yang mengikuti scroll aplikasi |
| AI Coach | Gunakan garis alur “Pesan → Safe draft → Konfirmasi”, bukan efek robot/AI generik |
| Penutup | Logo, identitas institusi, dan tagline dengan ruang kosong yang lega |

Hasil yang dituju adalah visual seperti produk finansial modern: tenang, bersih,
terpercaya, dan manusiawi. Video tidak perlu terlihat futuristik untuk
menunjukkan bahwa NALA menggunakan AI.

## 6. Data dan Keamanan Saat Perekaman

1. Gunakan akun serta dataset demo development.
2. Jangan merekam file `.env`, developer console, API key, password, token,
   browser password manager, atau notification tray.
3. Blur bukan pengganti persiapan data yang aman; tutup informasi sensitif
   sebelum recording.
4. Gunakan satu struk dari `docs/evaluation/synthetic_receipts/images`.
5. Beri label “Dataset demonstrasi sintetis” pada seluruh montage data.
6. Catat model, prompt, tanggal, dan output untuk segmen AI.
7. Jangan menyebut skor demo 85 sebagai hasil keberhasilan pengguna.

## 7. Pembagian Peran Produksi

| Peran | Tanggung jawab |
|---|---|
| Presenter/voice-over | Membaca naskah dengan tempo sekitar 130–145 kata/menit |
| Operator aplikasi | Menyiapkan seed dan merekam alur tanpa error |
| Editor | Menyusun visual, audio, subtitle, label bukti, dan durasi |
| Quality reviewer | Memeriksa klaim, keamanan data, keterbacaan, dan ketentuan |

Satu orang boleh memegang beberapa peran. Nama anggota tim selain ketua diisi
setelah susunan resmi dikonfirmasi.

## 8. Judul dan Deskripsi YouTube

### Judul

`NALA — Aplikasi Pendamping Kebiasaan Finansial Mahasiswa | GEMASTIK XIX 2026`

### Deskripsi

```text
NALA adalah aplikasi pendamping kebiasaan finansial mahasiswa yang
mengintegrasikan frictionless financial capture, Explainable Financial Habit
Score, dan kecerdasan artifisial kontekstual dengan safe draft serta konfirmasi
pengguna.

Video ini menampilkan proses perancangan, kemajuan implementasi, kegunaan, dan
cara penggunaan NALA untuk penyisihan GEMASTIK XIX 2026 cabang Pengembangan
Perangkat Lunak.

Dikembangkan oleh mahasiswa Program Studi Teknik Informatika angkatan 2023,
Fakultas Teknik, Universitas Sam Ratulangi, Manado.

Ketua dan Software Developer Utama:
Miftahuddin S. Arsyad

Catatan: data finansial yang tampil merupakan dataset demonstrasi sintetis dan
bukan data pengguna nyata atau hasil pilot.
```

Gunakan visibilitas sesuai ketentuan panitia. Jika video dibuat unlisted,
pastikan tautan dapat dibuka tanpa login dan tidak dibatasi akun institusi.

## 9. Checklist Final

### Isi

- [ ] Masalah dan manfaat NALA dijelaskan.
- [ ] Proses perancangan aktual ditampilkan.
- [ ] Progres di atas 50% disertai definisi dan tanggal snapshot.
- [ ] Penggunaan aplikasi ditampilkan dari login sampai tiga inovasi inti.
- [ ] Dataset sintetis diberi label.
- [ ] Fitur planned tidak disebut selesai.
- [ ] Habit Score disebut sebagai indikator kebiasaan, bukan credit score.
- [ ] AI ditampilkan sebagai safe draft dengan konfirmasi.

### Teknis

- [ ] Durasi final tidak melebihi 03:00; target 02:50.
- [ ] Resolusi 1920 × 1080 dan frame rate konsisten.
- [ ] Voice-over jelas dan musik tidak menutupi suara.
- [ ] Subtitle telah diperiksa ejaan dan sinkronisasinya.
- [ ] Tidak ada password, token, API key, atau data pribadi.
- [ ] UI terbaca pada layar ponsel dan desktop.
- [ ] Lisensi musik, font, ilustrasi, dan aset tersimpan.

### Publikasi

- [ ] Thumbnail sederhana dan sesuai identitas NALA.
- [ ] Video diunggah ke YouTube.
- [ ] Video dapat dibuka melalui mode incognito tanpa meminta izin.
- [ ] Kualitas 1080p selesai diproses sebelum submission.
- [ ] Judul dan deskripsi tidak memuat klaim yang belum tervalidasi.
- [ ] Tautan final disalin ke proposal dan form pengumpulan.
- [ ] Salinan master, subtitle, thumbnail, dan file export disimpan tim.

## 10. File Produksi yang Disarankan

```text
docs/video/
├── NALA_VIDEO_PENYISIHAN_SCRIPT.md
├── recordings/       # tidak wajib dikomit jika berukuran besar
├── audio/
├── subtitles/
├── graphics/
├── thumbnail/
└── exports/
```

File video besar sebaiknya disimpan di penyimpanan tim, bukan Git biasa. Commit
hanya naskah, subtitle, grafik ringan, dan manifest aset; gunakan Git LFS hanya
jika memang disepakati tim.
