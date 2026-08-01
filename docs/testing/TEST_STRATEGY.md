# NALA Test Strategy

Dokumen ini menerjemahkan bagian pengujian pada
`docs/NALA_PRODUCT_ENGINEERING_PLAN.md` menjadi aturan eksekusi.

## Prinsip

- Risiko finansial, keamanan, dan privasi diuji lebih dalam daripada UI biasa.
- Unit, integration, contract, security, performance, dan E2E membuktikan hal
  berbeda; satu lapisan tidak menggantikan lapisan lain.
- Test harus deterministik, terisolasi, dapat diulang, dan tidak memakai data
  pengguna nyata.
- Bug produksi atau demo wajib meninggalkan regression test.
- Angka proposal hanya berasal dari output dan laporan aktual.

## Gate

| Gate | Suite wajib |
|---|---|
| Pull request | analyze/typecheck, unit, widget, contract, integration kritis |
| Main | seluruh PR gate dan artefak hasil |
| Nightly | mobile integration, security, dependency audit |
| Release | E2E staging, performance, accessibility, backup/restore |

Mobile integration dijalankan di Linux headless melalui CI. Untuk flow
transaksi, endpoint test ditetapkan secara eksplisit agar server lokal
deterministik tidak pernah tercampur dengan backend development atau production:

```bash
xvfb-run -a flutter test integration_test/transaction_flow_test.dart -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:39091/api
xvfb-run -a flutter test integration_test/receipt_flow_test.dart -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:39092/api
```

## Ownership

Setiap fitur membawa acceptance criteria, test pada lapisan yang sesuai,
fixture minimal, dan pembaruan matriks. Test flaky harus diperbaiki atau
dikarantina dengan issue dan batas waktu; tidak boleh diabaikan diam-diam.
