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
  final _dashboardKey = GlobalKey<DashboardScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey),
      const TransactionScreen(),
      const SizedBox(),
      ReportScreen(onBack: () => _onItemTapped(0)),
      const ProfileScreen(),
    ];
  }

  void _refreshScreen(int index) {
    if (index == 0) {
      _dashboardKey.currentState?.refresh();
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
      _selectedIndex = index;
    });
  }

  Future<void> _openScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
    if (result == true && mounted) {
      setState(() => _refreshScreen(_selectedIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8ECF2)),
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavItem(Icons.home_rounded, 'Home', 0)),
                Expanded(
                  child:
                      _buildNavItem(Icons.receipt_long_rounded, 'Transaksi', 1),
                ),
                Expanded(child: _buildScanNavItem()),
                Expanded(
                    child:
                        _buildNavItem(Icons.bar_chart_rounded, 'Laporan', 3)),
                Expanded(
                    child: _buildNavItem(Icons.person_rounded, 'Profil', 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanNavItem() {
    return GestureDetector(
      onTap: _openScan,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 25,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Scan',
            style: GoogleFonts.interTight(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8A94A3),
            ),
          ),
        ],
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
            color: isSelected ? AppTheme.primaryColor : const Color(0xFF8A94A3),
            size: 23,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.interTight(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color:
                  isSelected ? AppTheme.primaryColor : const Color(0xFF8A94A3),
            ),
          ),
        ],
      ),
    );
  }
}
