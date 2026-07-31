import 'package:flutter/material.dart';
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
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE9ECF1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(Icons.home_rounded, 'Beranda', 0),
                ),
                Expanded(
                  child: _buildNavItem(
                    Icons.receipt_long_rounded,
                    'Transaksi',
                    1,
                  ),
                ),
                Expanded(child: _buildScanNavItem()),
                Expanded(
                  child: _buildNavItem(
                    Icons.bar_chart_rounded,
                    'Laporan',
                    3,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(Icons.person_rounded, 'Profil', 4),
                ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 28,
              color: Colors.white,
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF0DA) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
                  isSelected ? AppTheme.primaryColor : const Color(0xFF8A94A3),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color:
                  isSelected ? AppTheme.primaryColor : const Color(0xFF8A94A3),
            ),
          ),
        ],
      ),
    );
  }
}
