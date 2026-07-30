import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
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

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature segera hadir di NALA.')),
    );
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 38,
                    maxWidth: 440,
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
                          const SizedBox(height: 30),
                          _buildLoginCard(),
                          const SizedBox(height: 20),
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
      width: 42,
      height: 42,
      child: IconButton(
        tooltip: 'Kembali',
        onPressed: () => Navigator.maybePop(context),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        icon: const Icon(CupertinoIcons.back, size: 18),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 96,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              'img/Logo Nala 4.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Logo Nala',
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Selamat datang kembali.',
          style: appleStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            height: 1.12,
            letterSpacing: -.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Masuk untuk melanjutkan perjalanan finansialmu.',
          style: appleStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E9ED)),
      ),
      child: Column(
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
          const SizedBox(height: 17),
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
                _obscurePassword
                    ? CupertinoIcons.eye
                    : CupertinoIcons.eye_slash,
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
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
      ),
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton.icon(
        onPressed: () => _comingSoon('Login biometrik'),
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
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );
}
