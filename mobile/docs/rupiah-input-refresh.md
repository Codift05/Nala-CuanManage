# Rupiah Input Refresh

## Summary

- Added a persistent `Rp` prefix to the transaction amount field.
- Added Indonesian thousands separators while the user types.
- Kept the amount field neutral and white to match the application form style.
- Increased placeholder readability without changing submitted numeric values.

## Verification

- Added a formatter unit test for converting `10000` to `10.000`.
- The application smoke test continues to pass.
