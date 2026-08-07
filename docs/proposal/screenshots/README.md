# NALA Proposal Screenshot Manifest

Folder ini menampung screenshot aplikasi aktual untuk proposal GEMASTIK XIX
2026. Jangan menyimpan API key, token, password, email pribadi, atau data
finansial pengguna nyata.

## Persiapan

1. Jalankan stack development dan seed akun demo.
2. Gunakan satu commit, platform, dan viewport untuk semua screenshot.
3. Gunakan data dari `docs/demo/DEMO_DATASET.md`.
4. Crop area aplikasi tanpa browser toolbar atau desktop.
5. Simpan PNG lossless tanpa memanipulasi isi UI.

```bash
docker compose up --build
docker compose exec -T backend npm run seed

cd mobile
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://127.0.0.1:3001/api
```

## Nama file wajib

- `01-welcome.png`
- `02-auth-sheet.png`
- `03-home-summary.png`
- `04-activity.png`
- `05-receipt-review.png`
- `06-transaction-confirmation.png`
- `07-habit-score.png`
- `08-score-factors.png`
- `09-ai-coach.png`
- `10-ai-safe-draft.png`

File opsional memakai nomor 11–15 sebagaimana storyboard pada proposal.

## Record capture

Isi setelah screenshot dibuat:

- Commit:
- Tanggal dan zona waktu:
- Platform/perangkat:
- Logical viewport/resolusi file:
- Demo seed dijalankan pada:
- Model AI dan prompt untuk screenshot 09–10:
- Pemeriksa data sensitif:
- Catatan crop/composite:

Screenshot adalah bukti implementasi, bukan hasil usability atau pilot.
