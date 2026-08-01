# NALA Performance Test Plan

## Skenario

| Area | Metrik utama |
|---|---|
| Android startup | time to first frame dan time to interactive |
| Dashboard | p50/p95 load dan frame rendering |
| Histori transaksi | p50/p95, pagination, error rate |
| Mutasi transaksi | p50/p95, throughput, duplicate count |
| Wallet concurrency | saldo akhir dan conflict/error rate |
| Receipt extraction | upload size, p50/p95, timeout rate |
| Habit Score | waktu kalkulasi dan query count |

## Aturan laporan

Catat commit, build mode, perangkat/CPU, environment, ukuran dataset, jumlah
virtual user, warm-up, durasi, p50, p95, p99, error rate, dan raw output.
Debug build tidak digunakan sebagai hasil proposal. Target pada roadmap tidak
boleh ditulis sebagai hasil aktual.
