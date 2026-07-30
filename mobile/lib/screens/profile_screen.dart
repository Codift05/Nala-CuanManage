import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'login_screen.dart';
import 'wallet_management_screen.dart';
import 'recurring_bills_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _loadError;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    BiometricService().isEnabled().then((enabled) {
      if (mounted) setState(() => _biometricEnabled = enabled);
    });
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final result = await AuthService().getCurrentUserResult();
    if (!mounted) return;

    if (result.sessionExpired) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    setState(() {
      _user = result.user;
      _loadError = result.success ? null : result.message;
      _isLoading = false;
    });
  }

  void _navigateToEditProfile() async {
    if (_user == null) return;
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _user!),
      ),
    );
    if (updated == true) {
      _loadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null || _user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profil belum dapat dimuat',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadError ?? 'Silakan coba beberapa saat lagi.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: _loadUser,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Profil dan Pengaturan',
                style: GoogleFonts.interTight(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 26),
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildMenuGroup(
                children: [
                  _buildMenuTile(
                    icon: Icons.edit_outlined,
                    title: 'Profil & data',
                    onTap: _navigateToEditProfile,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMenuGroup(
                children: [
                  _buildMenuTile(
                    icon: Icons.shield_outlined,
                    title: 'Keamanan akun',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _buildDivider(),
                  _buildMenuTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Buka dengan biometrik',
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (_) => _toggleBiometric(),
                    ),
                    onTap: _toggleBiometric,
                  ),
                  _buildDivider(),
                  _buildMenuTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Bank & Dompet',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WalletManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildMenuTile(
                    icon: Icons.autorenew_rounded,
                    title: 'Tagihan Berulang',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecurringBillsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMenuGroup(
                children: [
                  _buildMenuTile(
                    icon: Icons.logout_rounded,
                    title: 'Keluar',
                    textColor: AppTheme.errorColor,
                    hideArrow: true,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final avatarImage = _decodeAvatar(_user?['avatar']);
    return Column(
      children: [
        GestureDetector(
          onTap: _navigateToEditProfile,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarImage == null
                        ? AppTheme.textPrimary
                        : Colors.white,
                    width: avatarImage == null ? 1.5 : 4,
                  ),
                  image: avatarImage != null
                      ? DecorationImage(
                          image: avatarImage,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              if (avatarImage == null)
                const Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 48,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 15,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _user?['name'] ?? 'Pengguna',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.interTight(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  MemoryImage? _decodeAvatar(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      return bytes.isEmpty ? null : MemoryImage(bytes);
    } on FormatException {
      return null;
    }
  }

  Widget _buildMenuGroup({required List<Widget> children}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    Color? textColor,
    bool hideArrow = false,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor ?? AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.interTight(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppTheme.textPrimary,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else if (!hideArrow)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB0B5BE),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBiometric() async {
    final biometrics = BiometricService();
    if (!_biometricEnabled && !await biometrics.isAvailable()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Biometrik belum tersedia di perangkat.')),
        );
      }
      return;
    }
    if (!await biometrics.authenticate()) return;
    final enabled = !_biometricEnabled;
    await biometrics.setEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.borderColor,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Nala?'),
        content: const Text(
          'Kamu perlu masuk kembali untuk mengakses akun ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Ubah password'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                    controller: oldPasswordController,
                    label: 'Password lama',
                    obscureText: obscureOld,
                    onToggle: () =>
                        setDialogState(() => obscureOld = !obscureOld),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password lama wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'Password baru',
                    obscureText: obscureNew,
                    onToggle: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password baru wajib diisi';
                      }
                      if (value.length < 8) {
                        return 'Minimal 8 karakter';
                      }
                      if (value == oldPasswordController.text) {
                        return 'Harus berbeda dari password lama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Konfirmasi password baru',
                    obscureText: obscureConfirm,
                    onToggle: () => setDialogState(
                      () => obscureConfirm = !obscureConfirm,
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Konfirmasi password tidak sama';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => isLoading = true);
                      final result = await AuthService().changePassword(
                        oldPasswordController.text,
                        newPasswordController.text,
                      );
                      if (!dialogContext.mounted) return;
                      setDialogState(() => isLoading = false);
                      if (result.success) {
                        Navigator.pop(dialogContext);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.message)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.message)),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Tampilkan password' : 'Sembunyikan password',
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}
