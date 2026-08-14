# Checklist Deliverable NALA — GEMASTIK XIX 2026

Folder final wajib dinamai:

`GEMASTIK XIX Perangkat Lunak - <ID-Tim> - RoboAjaDulu - <Judul Karya>`

## Berkas wajib

- [x] Dokumen teknis PDF maksimal 30 halaman.
- [ ] APK Android release dengan signing key tim dan backend HTTPS publik.
- [x] URL aplikasi web yang dapat diakses juri.
- [x] URL repositori GitHub dicantumkan pada dokumen URL aplikasi.
- [x] URL video demo YouTube dalam TXT.
- [x] Daftar komponen dan lisensi.
- [ ] Surat pernyataan keaslian bermaterai dan ditandatangani ketua tim.
- [x] Dokumen adopsi lisensi proprietary NALA.
- [ ] Arsip ZIP/RAR dengan nama yang sama seperti folder.

## Verifikasi final

- [ ] APK dapat dipasang pada perangkat Android fisik yang bersih.
- [ ] Register, login, transaksi, budget, laporan, Habit Score, dan Nala Coach diuji melalui jaringan seluler.
- [x] APK public-demo mengarah ke API publik Vercel, bukan `localhost`, `127.0.0.1`, atau `10.0.2.2`.
- [ ] API menggunakan HTTPS dan tidak mengekspos secret di aplikasi.
- [ ] Akun demo serta langkah instalasi tercantum tanpa memuat secret produksi.
- [ ] URL dibuka pada browser tanpa sesi pengembang.
- [ ] PDF dapat dibuka, maksimal 30 halaman, dan seluruh caption terbaca.
- [ ] Checksum APK sudah diperbarui setelah build terakhir.

## Perintah build final

```bash
cd mobile
flutter analyze
flutter test
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<domain-backend>/api
```

Jangan menyerahkan APK yang masih menggunakan sertifikat debug. Konfigurasi keystore release tim harus diselesaikan sebelum build final.
