# NALA Security Test Plan

## Cakupan minimum

- JWT hilang, rusak, kedaluwarsa, dicabut, dan refresh replay.
- IDOR untuk wallet, transaksi, budget, recurring, session, dan profil.
- Rate limit register, login, reset, verification, OCR, dan AI Coach.
- Mass assignment serta payload, gambar, dan teks berukuran ekstrem.
- SQL/JSON/header injection dan malformed body.
- Prompt injection pada chat dan teks struk.
- PII, token, password, foto struk, dan data finansial tidak masuk log.
- Dependency audit dan konfigurasi production fail-fast.

## Severity gate

- Critical/High terbuka: release ditolak.
- Medium: wajib memiliki mitigasi, owner, dan tenggat.
- Low: dicatat dan diprioritaskan berdasarkan risiko.

Hasil harus memuat environment, commit, langkah reproduksi, dampak, bukti,
mitigasi, status retest, dan tidak boleh menyimpan secret nyata.

## Suite otomatis aktual

Jalankan dari folder `backend`:

```bash
npm run test:security
```

Corpus `test/fixtures/aiCoachAdversarial.json` mencakup redaksi PII, delimiter
escape, dan instruksi pengambilalihan konteks. Suite juga memastikan output AI
tidak dapat memilih wallet pengguna lain atau melewati schema draft transaksi.
Test ini deterministik dan tidak memanggil Gemini; evaluasi model live dicatat
terpisah agar biaya, model, prompt, dan hasilnya dapat direproduksi.
