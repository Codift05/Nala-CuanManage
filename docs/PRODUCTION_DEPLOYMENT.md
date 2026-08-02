# NALA Production Deployment

`docker-compose.prod.yml` adalah baseline satu-host untuk staging/pilot, bukan
arsitektur high-availability. TLS harus diterminasi oleh reverse proxy/cloud
load balancer di depan port backend yang hanya bind ke `127.0.0.1`.

## Persiapan

1. Salin `.env.production.example` ke file secret di host deployment; jangan
   commit hasilnya.
2. Buat password database dan `JWT_SECRET` acak. URL-encode password ketika
   dimasukkan ke `DATABASE_URL`.
3. Simpan secret pada secret manager platform atau file host berizin minimum.
4. Validasi konfigurasi tanpa memulai service:

```bash
docker compose --env-file /path/to/nala.production.env \
  -f docker-compose.prod.yml config --quiet
```

## Deploy

```bash
docker compose --env-file /path/to/nala.production.env \
  -f docker-compose.prod.yml build
docker compose --env-file /path/to/nala.production.env \
  -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml ps
```

Service `migrate` menjalankan `prisma migrate deploy` satu kali sebelum backend.
Production tidak menjalankan seed atau `prisma db push`. Runtime berjalan sebagai
user non-root, read-only, tanpa development dependency.

Log aplikasi tersedia sebagai JSON line pada `stdout`/`stderr`. Hubungkan output
container ke log service platform dan ikuti redaksi, alert, serta retensi pada
`docs/OBSERVABILITY.md`.

## Rollback

Gunakan tag image/commit sebelumnya lalu jalankan Compose kembali. Migration
database harus backward-compatible; rollback schema destruktif memerlukan runbook
dan backup terverifikasi, bukan `prisma db push` atau reset database.

## Backup dan verifikasi restore

Buat backup berformat PostgreSQL custom dari service database yang sedang aktif:

```bash
NALA_ENV_FILE=/path/to/nala.production.env \
NALA_BACKUP_DIR=/secure/off-host-backups \
scripts/backup-postgres.sh
```

Skrip menulis arsip dan checksum SHA-256 dengan izin file `600`. Simpan hasilnya
di penyimpanan off-host terenkripsi dengan akses dan retensi terbatas. Skrip
tidak menghapus backup lama secara otomatis agar kebijakan retensi tetap
eksplisit.

Verifikasi bahwa sebuah arsip benar-benar dapat dipulihkan:

```bash
scripts/verify-postgres-restore.sh \
  /secure/off-host-backups/nala_YYYYMMDDTHHMMSSZ.dump
```

Verifikasi membuat PostgreSQL 15 sementara di memori, memeriksa checksum,
memulihkan arsip dengan `--exit-on-error`, lalu memastikan tabel dan histori
migration tersedia. Database sumber maupun production tidak menjadi target
restore. Jalankan drill berkala dan sebelum migration berisiko tinggi.

## Belum dianggap selesai

- Domain dan TLS aktual.
- Secret manager aktual.
- Penjadwalan backup production, retensi, dan penyimpanan off-host aktual.
- Error tracking production.
- Staging smoke test dan signed Android build.
