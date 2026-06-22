import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/report_screen.dart';
import '../screens/transaction_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/scan_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionScreen(),
    const SizedBox(), // Placeholder for Scan
    ReportScreen(onBack: () => _onItemTapped(0)),
    const ProfileScreen(),
  ];

  void _refreshScreen(int index) {
    if (index == 0) {
      _screens[0] = DashboardScreen(key: UniqueKey());
    } else if (index == 1) {
      _screens[1] = TransactionScreen(key: UniqueKey());
    } else if (index == 3) {
      _screens[3] = ReportScreen(
        key: UniqueKey(),
        onBack: () => _onItemTapped(0),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) return; // Ignore scan button area
    setState(() {
      // IndexedStack keeps each tab alive. Recreate data-driven tabs when they
      // are opened so wallet balances and newly saved transactions stay in sync.
      _refreshScreen(index);
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: SizedBox(
        height: 56,
        width: 56,
        child: Transform.translate(
          offset: const Offset(0, 16), // Lowered the FAB slightly more
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanScreen()),
              );
            },
            backgroundColor: const Color(0xFF1954C2),
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        // No shape to make it flat
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(child: _buildNavItem(Icons.home, 'Home', 0)),
              Expanded(child: _buildNavItem(Icons.receipt_long, 'Transaksi', 1)),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24), // Same height as the icons
                    const SizedBox(height: 4),  // Same gap as the icons
                    Text(
                      'Scan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildNavItem(Icons.bar_chart, 'Laporan', 3)),
              Expanded(child: _buildNavItem(Icons.person_outline, 'Profil', 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1954C2) : AppTheme.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1954C2) : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
