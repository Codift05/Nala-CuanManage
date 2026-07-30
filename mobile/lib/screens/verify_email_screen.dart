import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
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
    final result = await AuthService().verifyEmail(widget.token);
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result == null)
                  const CircularProgressIndicator()
                else
                  Icon(
                    result.success
                        ? Icons.mark_email_read_rounded
                        : Icons.error_outline_rounded,
                    size: 64,
                    color: result.success
                        ? AppTheme.primaryColor
                        : AppTheme.errorColor,
                  ),
                const SizedBox(height: 20),
                Text(
                  result?.message ?? 'Memverifikasi email...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (result != null) ...[
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    ),
                    child: const Text('Kembali ke login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
