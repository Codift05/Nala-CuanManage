import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../widgets/auth_visuals.dart';
import '../widgets/main_shell.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  Size? _welcomeLayoutSize;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (media.viewInsets.bottom == 0 && _motionController.isAnimating) {
      _welcomeLayoutSize = media.size;
    }
  }

  Future<void> _showAuthSheet(Widget screen) async {
    HapticFeedback.lightImpact();
    _motionController.stop();
    final maxSheetHeight = MediaQuery.sizeOf(context).height * .88;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: .42),
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(end: MediaQuery.viewInsetsOf(context).bottom),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: RepaintBoundary(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: screen,
            ),
          ),
        ),
        builder: (context, keyboardInset, child) => Transform.translate(
          offset: Offset(0, -keyboardInset),
          child: child,
        ),
      ),
    );
    if (mounted) _motionController.repeat(reverse: true);
  }

  Future<void> _biometricLogin() async {
    HapticFeedback.lightImpact();
    final biometrics = BiometricService();
    if (!await biometrics.isEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktifkan biometrik dari pengaturan akun.'),
          ),
        );
      }
      return;
    }
    final unlocked = await biometrics.unlockSavedSession();
    final sessionValid = unlocked && await AuthService().isLoggedIn();
    if (!mounted) return;
    if (sessionValid) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometrik gagal atau sesi berakhir.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final welcomeSize = _welcomeLayoutSize ?? MediaQuery.sizeOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF7F8FA),
      body: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: welcomeSize.width,
        maxWidth: welcomeSize.width,
        minHeight: welcomeSize.height,
        maxHeight: welcomeSize.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final panelHeight = compact ? 298.0 : 292.0;
            return Stack(
              children: [
                Positioned.fill(
                  bottom: panelHeight - 28,
                  child: RepaintBoundary(
                    child: _WelcomeHero(
                      compact: compact,
                      animation: _motionController,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: panelHeight,
                  child: _WelcomePanel(
                    compact: compact,
                    onLogin: () => _showAuthSheet(
                      const LoginScreen(sheet: true),
                    ),
                    onRegister: () => _showAuthSheet(
                      const RegisterScreen(sheet: true),
                    ),
                    onBiometric: _biometricLogin,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({required this.compact, required this.animation});

  final bool compact;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.primaryColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            children: [
              Image.asset(
                'img/Logo Nala 4.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'Logo Nala',
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                'Uang lebih tertata,\nhidup terasa ringan.',
                textAlign: TextAlign.center,
                style: appleStyle(
                  color: Colors.white,
                  fontSize: compact ? 22 : 25,
                  height: 1.13,
                  letterSpacing: -.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Catat, atur, dan pahami keuanganmu bersama NALA.',
                textAlign: TextAlign.center,
                style: appleStyle(
                  color: Colors.white.withValues(alpha: .88),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final cityY = lerpDouble(3, -3, animation.value)!;
                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: compact ? 2 : 6,
                          child: Container(
                            height: compact ? 145 : 170,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE8C5),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(160),
                              ),
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, cityY),
                          child: Image.asset(
                            'assets/illustrations/nala-city.png',
                            height: compact ? 170 : 198,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            semanticLabel:
                                'Ilustrasi kota pesisir dan pengelolaan uang',
                          ),
                        ),
                        _FloatingCoin(
                          alignment: const Alignment(-.84, -.58),
                          offset: lerpDouble(-5, 5, animation.value)!,
                          size: 29,
                        ),
                        _FloatingCoin(
                          alignment: const Alignment(.82, -.36),
                          offset: lerpDouble(5, -5, animation.value)!,
                          size: 24,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCoin extends StatelessWidget {
  const _FloatingCoin({
    required this.alignment,
    required this.offset,
    required this.size,
  });

  final Alignment alignment;
  final double offset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(0, offset),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD48C),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            CupertinoIcons.money_dollar,
            size: size * .5,
            color: const Color(0xFFB95608),
          ),
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.compact,
    required this.onLogin,
    required this.onRegister,
    required this.onBiometric,
  });

  final bool compact;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, compact ? 18 : 22, 24, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Text(
              'Mulai dari yang penting',
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
                  icon: CupertinoIcons.pencil,
                  label: 'Catat cepat',
                  color: Color(0xFF5ED3C7),
                ),
                _FeatureItem(
                  icon: CupertinoIcons.chart_pie,
                  label: 'Atur budget',
                  color: Color(0xFF90AAF4),
                ),
                _FeatureItem(
                  icon: CupertinoIcons.sparkles,
                  label: 'Insight NALA',
                  color: Color(0xFFB69BEA),
                ),
              ],
            ),
            SizedBox(height: compact ? 16 : 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Masuk ke NALA'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: onBiometric,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.fingerprint_rounded, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Belum punya akun?',
                  style: appleStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: onRegister,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Daftar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF171A1F), size: 21),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: appleStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
