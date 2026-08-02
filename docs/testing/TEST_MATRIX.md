# NALA Test Matrix

Status: `planned`, `partial`, `covered`, atau `validated`.

| Domain | Unit | Widget | Integration | Contract | Security | E2E | Status |
|---|---|---|---|---|---|---|---|
| Authentication | token/config | login/register/reset | session, rotation, rate limit | auth envelope | JWT, revoke, brute force | daftar-login-logout | partial |
| Wallet | money mapping | state CRUD | ownership dan saldo | wallet schema | IDOR | buat/edit/hapus | partial |
| Transaction | validator/idempotency | form dan state | CRUD, saldo, replay, concurrency, UI-to-HTTP create | integer rupiah/pagination | IDOR/mass assignment | catat sampai dashboard | partial |
| Budget | validator/progress | list/form/state | CRUD dan ownership | budget schema | IDOR | buat dan pantau | partial |
| Recurring | period/date logic | list/form/state | scheduler dan duplicate | recurring schema | ownership | buat-eksekusi-nonaktif | partial |
| Receipt/OCR | parser dan review flag | picker/review/error | AI timeout, draft, review-koreksi-simpan | confidence per field | payload/prompt injection | scan pada perangkat nyata | partial |
| Habit Score | formula dan edge case | reason/action/nullable | histori dan data sumber | score schema | data leakage | pahami perubahan | partial |
| AI Coach | redaction, delimiter, schema | chat/draft/fallback | saran-draft-batal-konfirmasi dengan HTTP server deterministik | envelope sukses/fallback dan safe draft backend/Flutter | corpus PII/delimiter/hostile draft di CI; rate limit | saran-konfirmasi | partial |
| Profile | validator/avatar | form/error | backend update/delete | profile schema | reauth/mass assignment | edit/hapus akun | partial |

Matriks diperbarui hanya setelah bukti suite dapat dijalankan.
