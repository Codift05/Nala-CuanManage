# NALA Privacy and Data Rights Baseline

Baseline ini berlaku untuk prototipe/pilot NALA dan versi privacy notice
`2026-08-02`. Dokumen ini adalah catatan implementasi produk, bukan pernyataan
sertifikasi kepatuhan hukum.

## Persetujuan

Registrasi hanya diterima bila `privacyAccepted` bernilai `true` dan
`privacyVersion` sama dengan versi aktif. Backend menyimpan event
`PRIVACY_ACCEPTED` beserta versi dan waktu pada audit trail. Checkbox tidak
dipilih secara otomatis dan notice dapat dibaca sebelum pengguna menyetujui.

## Hak akses dan ekspor

Pengguna terautentikasi dapat meminta `GET /api/auth/me/export`. Hasil JSON
hanya mengambil data dengan `userId` miliknya: profil, wallet, transaksi,
budget, tagihan berulang, histori Habit Score, dan aktivitas akun. Password
hash, token verifikasi/reset, serta session token tidak ikut diekspor.

Permintaan dibatasi lima kali per jam dan dicatat sebagai `DATA_EXPORTED`.
Mobile menyediakan aksi **Salin ekspor data JSON** agar hasil dapat disimpan
sendiri oleh pengguna.

## Penghapusan

Penghapusan akun memerlukan password aktif. Transaksi, tagihan berulang,
budget, wallet, session, token, dan histori Habit Score dihapus dalam transaksi
database yang sama. Audit penghapusan dipertahankan tanpa relasi identitas
(`actorUserId = null`) untuk bukti operasional minimum.

Integration test membuktikan penolakan consent kosong, isolasi export,
pengecualian credential, serta penghapusan seluruh relasi pengguna.

## Batas sebelum production

- Validasi notice bersama pembimbing/legal reviewer yang relevan.
- Tetapkan alamat kontak pengendali data dan jadwal retensi audit.
- Dokumentasikan region serta retensi provider email/AI yang benar-benar dipakai.
- Uji export dan delete pada staging serta perangkat pilot.
