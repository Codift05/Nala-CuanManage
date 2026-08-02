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

## Rollback

Gunakan tag image/commit sebelumnya lalu jalankan Compose kembali. Migration
database harus backward-compatible; rollback schema destruktif memerlukan runbook
dan backup terverifikasi, bukan `prisma db push` atau reset database.

## Belum dianggap selesai

- Domain dan TLS aktual.
- Secret manager aktual.
- Backup/restore drill.
- Error tracking production.
- Staging smoke test dan signed Android build.
