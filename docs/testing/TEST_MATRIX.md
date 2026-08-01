# NALA Test Matrix

Status: `planned`, `partial`, `covered`, atau `validated`.

| Domain | Unit | Widget | Integration | Contract | Security | E2E | Status |
|---|---|---|---|---|---|---|---|
| Authentication | token/config | login/register/reset | session, rotation, rate limit | auth envelope | JWT, revoke, brute force | daftar-login-logout | partial |
| Wallet | money mapping | state CRUD | ownership dan saldo | wallet schema | IDOR | buat/edit/hapus | partial |
| Transaction | validator/idempotency | form dan state | CRUD, saldo, replay, concurrency, UI-to-HTTP create | integer rupiah/pagination | IDOR/mass assignment | catat sampai dashboard | partial |
| Budget | validator/progress | list/form/state | CRUD dan ownership | budget schema | IDOR | buat dan pantau | partial |
| Recurring | period/date logic | list/form/state | scheduler dan duplicate | recurring schema | ownership | buat-eksekusi-nonaktif | partial |
| Receipt/OCR | parser dan review flag | picker/review/error | AI timeout dan draft | confidence per field | payload/prompt injection | scan-koreksi-simpan | partial |
| Habit Score | formula/edge case | reason/action/history | histori dan data sumber | score schema | data leakage | pahami perubahan | planned |
| AI Coach | redaction/schema | chat/draft/fallback | timeout dan konfirmasi | structured output | injection/PII/rate limit | saran-konfirmasi | partial |
| Profile | validator/avatar | form/error | backend update/delete | profile schema | reauth/mass assignment | edit/hapus akun | partial |

Matriks diperbarui hanya setelah bukti suite dapat dijalankan.
