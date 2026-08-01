import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_visuals.dart';
import '../widgets/main_shell.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    final result = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _forgotPassword() async {
    final email = TextEditingController(text: _emailController.text.trim());
    final submitted = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lupa password?'),
        content: TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Email akun'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, email.text.trim()),
            child: const Text('Kirim link'),
          ),
        ],
      ),
    );
    email.dispose();
    if (submitted == null || submitted.isEmpty || !mounted) return;

    final result = await _authService.requestPasswordReset(submitted);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    if (result.developmentToken != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            token: result.developmentToken!,
          ),
        ),
      );
    }
  }

  Future<void> _biometricLogin() async {
    final biometrics = BiometricService();
    if (!await biometrics.isEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktifkan login biometrik dari pengaturan akun.'),
          ),
        );
      }
      return;
    }
    final unlocked = await biometrics.unlockSavedSession();
    final sessionValid = unlocked && await _authService.isLoggedIn();
    if (!mounted) return;
    if (sessionValid) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Biometrik gagal atau sesi telah berakhir.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 38,
                    maxWidth: 390,
                  ),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(),
                          const SizedBox(height: 18),
                          _buildHeader(),
                          const SizedBox(height: 26),
                          _buildLoginForm(),
                          const SizedBox(height: 18),
                          _buildBiometricButton(),
                          const SizedBox(height: 12),
                          _buildRegisterLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        tooltip: 'Kembali',
        onPressed: () => Navigator.maybePop(context),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        icon: const Icon(CupertinoIcons.back, size: 17),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthBrandMark(size: 44),
        const SizedBox(height: 20),
        Text(
          'Selamat datang kembali.',
          style: appleStyle(
            color: AppTheme.textPrimary,
            fontSize: 23,
            height: 1.18,
            letterSpacing: -.3,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Masuk untuk melanjutkan perjalanan finansialmu.',
          style: appleStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email', style: _fieldLabelStyle),
        const SizedBox(height: 8),
        AuthTextField(
          controller: _emailController,
          label: 'nama@email.com',
          icon: CupertinoIcons.mail,
          fillColor: const Color(0xFFF7F8FA),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return 'Email wajib diisi';
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
              return 'Format email tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Password', style: _fieldLabelStyle)),
            Flexible(
              child: GestureDetector(
                onTap: _forgotPassword,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Lupa password?',
                    style: appleStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AuthTextField(
          controller: _passwordController,
          label: 'Masukkan password',
          icon: CupertinoIcons.lock,
          fillColor: const Color(0xFFF7F8FA),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) {
            if (!_isLoading) _login();
          },
          suffixIcon: IconButton(
            tooltip: _obscurePassword
                ? 'Tampilkan password'
                : 'Sembunyikan password',
            onPressed: () => setState(
              () => _obscurePassword = !_obscurePassword,
            ),
            icon: Icon(
              _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
              size: 19,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password wajib diisi';
            }
            if (value.length < 8) return 'Password minimal 8 karakter';
            return null;
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Masuk'),
                      SizedBox(width: 8),
                      Icon(CupertinoIcons.arrow_right, size: 17),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: TextButton.icon(
        onPressed: _biometricLogin,
        icon: const Icon(Icons.fingerprint_rounded, size: 22),
        label: const Text('Gunakan biometrik'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Belum punya akun?',
          style: appleStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text('Daftar'),
        ),
      ],
    );
  }

  TextStyle get _fieldLabelStyle => appleStyle(
        color: AppTheme.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );
}
