import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_visuals.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import '../widgets/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward().then((_) {
      _checkAuthStatus();
    });
  }

  void _checkAuthStatus() async {
    final biometrics = BiometricService();
    if (await biometrics.isEnabled() &&
        !await biometrics.unlockSavedSession()) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }
    final isLoggedIn = await AuthService().isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: Image.asset(
                    'img/Nala baru.png',
                    width: 88,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'Logo Nala',
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NALA · DANA KELOLA',
                        textAlign: TextAlign.center,
                        style: appleStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Karya mahasiswa Teknik Informatika angkatan 2023\n'
                        'Fakultas Teknik · Universitas Sam Ratulangi, Manado\n'
                        'untuk GEMASTIK 2026',
                        textAlign: TextAlign.center,
                        style: appleStyle(
                          fontSize: 10,
                          height: 1.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
