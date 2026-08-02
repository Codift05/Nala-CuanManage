# NALA Observability Baseline

Backend menulis satu event JSON per baris ke `stdout`/`stderr`. Container platform
dapat mengumpulkannya tanpa agent atau SDK khusus di aplikasi.

## Field inti

- `timestamp`, `level`, dan `event` untuk pencarian serta alert.
- `requestId`, `method`, `path`, `status`, dan `durationMs` untuk request HTTP.
- `errorName` dan `errorMessage` untuk kegagalan; stack trace dan request body
  sengaja tidak dicatat pada baseline ini.

Nama event memakai pola domain dan kejadian, misalnya `http.request`,
`transaction.create_failed`, dan `recurring.run_completed`. Header
`X-Request-ID` menghubungkan respons pengguna dengan access/error log.

## Perlindungan data

Logger bersama menyamarkan field credential/PII (`authorization`, cookie, email,
password, secret, token, API key), alamat email di pesan error, bearer token,
dan rangkaian 12–19 digit. Controller tidak boleh mencatat request body, gambar
struk, isi percakapan AI, atau data transaksi mentah.

Redaksi adalah lapisan pencegahan, bukan izin untuk memasukkan data sensitif ke
log. Unit test `backend/test/unit/logger.test.ts` menjadi gate minimum.

## Aktivasi production

1. Arahkan `stdout`/`stderr` container ke log service milik platform.
2. Batasi akses berdasarkan peran dan tetapkan retensi.
3. Buat alert awal untuk lonjakan event level `error`, HTTP 5xx, dan latency.
4. Uji alert di staging dengan error sintetis tanpa data pengguna.
5. Catat provider, retensi, penerima alert, dan hasil drill sebelum checklist
   error tracking production ditutup.

Baseline ini tidak menambah Prometheus, Grafana, atau SDK error tracking. Tambah
komponen tersebut hanya setelah kebutuhan staging dan target metrik terukur.
