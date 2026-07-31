import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_visuals.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final result = await AuthService().resetPassword(
      widget.token,
      _password.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 86,
                        height: 62,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset('img/Logo Nala 4.png'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Buat password baru',
                      style: appleStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gunakan minimal 8 karakter yang mudah kamu ingat.',
                      style: appleStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEAEDF2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password baru', style: _fieldLabelStyle),
                          const SizedBox(height: 8),
                          AuthTextField(
                            controller: _password,
                            label: 'Minimal 8 karakter',
                            icon: CupertinoIcons.lock,
                            fillColor: const Color(0xFFF7F8FA),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                size: 19,
                              ),
                            ),
                            validator: (value) => (value?.length ?? 0) < 8
                                ? 'Password minimal 8 karakter'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text('Konfirmasi password', style: _fieldLabelStyle),
                          const SizedBox(height: 8),
                          AuthTextField(
                            controller: _confirmation,
                            label: 'Ulangi password baru',
                            icon: CupertinoIcons.lock,
                            fillColor: const Color(0xFFF7F8FA),
                            obscureText: _obscureConfirmation,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) {
                              if (!_loading) _submit();
                            },
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Tampilkan konfirmasi password'
                                  : 'Sembunyikan konfirmasi password',
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                size: 19,
                              ),
                            ),
                            validator: (value) => value != _password.text
                                ? 'Konfirmasi password tidak sama'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Simpan password baru'),
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
        ),
      ),
    );
  }

  TextStyle get _fieldLabelStyle => appleStyle(
        color: AppTheme.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );
}
