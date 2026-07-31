import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_visuals.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _openLogin(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF9816),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          final panelHeight = compact ? 260.0 : 270.0;

          return Stack(
            children: [
              Positioned.fill(
                bottom: panelHeight - 32,
                child: _WelcomeHero(compact: compact),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: panelHeight,
                child: _WelcomePanel(
                  compact: compact,
                  onLogin: () => _openLogin(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Column(
          children: [
            Center(
              child: Image.asset(
                'img/Logo Nala 4.png',
                width: compact ? 76 : 86,
                height: compact ? 40 : 45,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'Logo Nala',
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Text(
              'Halo, selamat datang!',
              style: appleStyle(
                color: Colors.white,
                fontSize: compact ? 19 : 21,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Kelola uangmu tanpa terasa rumit.',
              style: appleStyle(
                color: Colors.white.withValues(alpha: .88),
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            Expanded(
              child: Image.asset(
                'assets/illustrations/nala-welcome.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'Dua anak muda mengelola keuangan bersama Nala',
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    CupertinoIcons.person_2_fill,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.compact,
    required this.onLogin,
  });

  final bool compact;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, compact ? 17 : 20, 24, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Text(
              'Semua yang kamu butuhkan',
              style: appleStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _FeatureItem(
                  icon: CupertinoIcons.doc_text,
                  label: 'Catat\ntransaksi',
                ),
                _FeatureItem(
                  icon: CupertinoIcons.chart_pie,
                  label: 'Atur\nbudget',
                ),
                _FeatureItem(
                  icon: CupertinoIcons.sparkles,
                  label: 'Insight\nNala',
                ),
              ],
            ),
            SizedBox(height: compact ? 17 : 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Masuk ke Nala'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFFD8A1)),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: appleStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
