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
