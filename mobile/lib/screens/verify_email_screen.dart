import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_visuals.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});

  final String token;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  AuthResult? _result;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    setState(() => _result = null);
    final result = await AuthService().verifyEmail(widget.token);
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAEDF2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (result == null)
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (result.success
                                ? AppTheme.primaryColor
                                : AppTheme.errorColor)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        result.success
                            ? Icons.mark_email_read_outlined
                            : Icons.error_outline_rounded,
                        color: result.success
                            ? AppTheme.primaryColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    result == null
                        ? 'Memverifikasi email...'
                        : result.success
                            ? 'Email berhasil diverifikasi'
                            : 'Verifikasi belum berhasil',
                    textAlign: TextAlign.center,
                    style: appleStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result?.message ?? 'Tunggu sebentar, ya.',
                    textAlign: TextAlign.center,
                    style: appleStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: result.success ? _openLogin : _verify,
                        child: Text(
                          result.success ? 'Kembali ke login' : 'Coba lagi',
                        ),
                      ),
                    ),
                    if (!result.success) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openLogin,
                        child: const Text('Kembali ke login'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openLogin() => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
}
