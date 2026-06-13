import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildAccountSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
              const SizedBox(height: 24),
              _buildOthersSection(context),
              const SizedBox(height: 80), // Padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1954C2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'MI',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Haii, Mip',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'mip@example.com',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          child: Text(
            'Edit Profil',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSectionCard(
      title: 'Akun & Keamanan',
      children: [
        _buildMenuTile(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF1954C2),
          title: 'Informasi Pribadi',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuTile(
          icon: Icons.lock_outline,
          iconColor: const Color(0xFFB45309), // Dark Orange
          title: 'Keamanan & PIN',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuTile(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF388E3C), // Green
          title: 'Manajemen Bank & Dompet',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSectionCard(
      title: 'Preferensi',
      children: [
        _buildMenuTile(
          icon: Icons.notifications_none,
          iconColor: const Color(0xFF1954C2),
          title: 'Pengaturan Notifikasi',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuTile(
          icon: Icons.language,
          iconColor: const Color(0xFF673AB7), // Deep Purple
          title: 'Bahasa',
          subtitle: 'Bahasa Indonesia',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuTile(
          icon: Icons.dark_mode_outlined,
          iconColor: const Color(0xFF0F172A), // Slate
          title: 'Mode Tampilan',
          subtitle: 'Terang',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildOthersSection(BuildContext context) {
    return _buildSectionCard(
      title: 'Lainnya',
      children: [
        _buildMenuTile(
          icon: Icons.help_outline,
          iconColor: const Color(0xFF1954C2),
          title: 'Pusat Bantuan',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuTile(
          icon: Icons.description_outlined,
          iconColor: AppTheme.textSecondary,
          title: 'Syarat & Ketentuan',
          onTap: () {},
        ),
        _buildDivider(),
        _buildMenuTile(
          icon: Icons.logout,
          iconColor: AppTheme.errorColor,
          title: 'Keluar',
          textColor: AppTheme.errorColor,
          hideArrow: true,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Keluar Aplikasi', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                content: Text('Apakah kamu yakin ingin keluar?', style: GoogleFonts.inter()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Keluar', style: GoogleFonts.inter(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
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
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? textColor,
    bool hideArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (!hideArrow)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 64.0, right: 20.0),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.withValues(alpha: 0.1),
      ),
    );
  }
}
