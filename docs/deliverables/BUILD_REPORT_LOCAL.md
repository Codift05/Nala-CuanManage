# Laporan Build APK Lokal NALA

**Tanggal:** 14 Agustus 2026

**Versi aplikasi:** 1.0.0+1

**Flutter:** 3.44.2 stable

**Dart:** 3.12.2

**Nama berkas:** `NALA-v1.0.0-local-demo.apk`

**SHA-256:** `7938f94a1178a5c1dc4284057acb176762c8911ed049075309296acfb23a0c63`

## Hasil verifikasi

- `flutter analyze`: lulus tanpa issue.
- `flutter test`: 23 test lulus.
- `flutter build apk --release`: berhasil, ukuran sekitar 57,8 MB.
- Verifikasi APK Signature Scheme v2: lulus.
- Izin internet tersedia pada manifest utama.

## Batas penggunaan

APK ini hanya untuk verifikasi lokal karena:

1. API diarahkan ke `http://10.0.2.2:3001/api`, yaitu backend host dari Android Emulator.
2. APK masih ditandatangani menggunakan sertifikat debug Android.

APK ini **bukan build final untuk juri**. Build final harus memakai backend HTTPS publik dan keystore release milik tim.
