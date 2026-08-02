import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const privacyVersion = '2026-08-02';

Future<void> showPrivacyNotice(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const FractionallySizedBox(
        heightFactor: .82,
        child: _PrivacyNotice(),
      ),
    );

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          children: const [
            Text(
              'Privasi di NALA',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Versi $privacyVersion',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 22),
            _Section(
              title: 'Data yang diproses',
              body: 'Identitas akun, dompet, transaksi, budget, tagihan '
                  'berulang, skor kebiasaan, dan aktivitas keamanan. Foto '
                  'struk diproses untuk ekstraksi dan tidak disimpan sebagai '
                  'foto oleh backend NALA.',
            ),
            _Section(
              title: 'Tujuan',
              body: 'Menjalankan fitur pencatatan dan analisis keuangan, '
                  'menjaga keamanan akun, serta meningkatkan keandalan layanan.',
            ),
            _Section(
              title: 'Layanan pihak ketiga',
              body:
                  'Fitur scan dan Nala Coach dapat memakai layanan AI Gemini. '
                  'NALA membatasi konteks yang dikirim dan tidak mengizinkan AI '
                  'mengubah data keuangan tanpa konfirmasi pengguna.',
            ),
            _Section(
              title: 'Pilihan dan hakmu',
              body:
                  'Kamu dapat melihat dan memperbarui profil, menyalin ekspor '
                  'data berformat JSON, berhenti memakai fitur AI, atau menghapus '
                  'akun beserta data terkait dari menu Profil.',
            ),
            _Section(
              title: 'Penyimpanan dan keamanan',
              body: 'Data disimpan selama akun aktif atau sesuai kebutuhan '
                  'keamanan dan evaluasi yang dijelaskan. Token dan password '
                  'tidak dimasukkan ke ekspor. Jangan gunakan data finansial '
                  'nyata selama tahap prototipe/pilot tanpa persetujuan.',
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
}
