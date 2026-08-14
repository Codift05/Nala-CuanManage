# Laporan Build APK Public Demo NALA

**Tanggal:** 14 Agustus 2026

**Versi:** 1.0.0+1

**API:** `https://nala-api-gemastik-unsrat.vercel.app/api`

**SHA-256:** `5de53bd4c135cda218d6ebd66bc12855c4ed96cc393390c0edb8a736ba60cffb`

## Verifikasi

- Flutter analyze bersih dan 23 test mobile lulus pada pemeriksaan sebelum build.
- Backend typecheck dan 27 unit test lulus.
- Web, API health, CORS, dan login akun demo lulus smoke test.
- APK Signature Scheme v2 valid.

## Batas penggunaan

APK terhubung ke layanan demo publik, tetapi masih memakai Android Debug certificate. Gunakan untuk uji perangkat dan demonstrasi internal. Build final kompetisi harus memakai keystore release tim.
