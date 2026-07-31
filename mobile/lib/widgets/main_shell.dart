import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../screens/report_screen.dart';
import '../screens/transaction_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/add_transaction_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _navIndexes = [0, 1, 3, 4];

  int _selectedIndex = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _pageController = PageController();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashboardKey),
      const TransactionScreen(),
      const ReportScreen(),
      const ProfileScreen(),
    ];
  }

  void _refreshScreen(int index) {
    if (index == 0) {
      _dashboardKey.currentState?.refresh();
    } else if (index == 1) {
      _screens[1] = TransactionScreen(key: UniqueKey());
    } else if (index == 3) {
      _screens[2] = ReportScreen(key: UniqueKey());
    }
  }

  void _onItemTapped(int index) {
    final page = _navIndexes.indexOf(index);
    if (page == -1 || index == _selectedIndex) return;

    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? 0).round()
        : _navIndexes.indexOf(_selectedIndex);
    setState(() => _selectedIndex = index);

    if ((page - currentPage).abs() > 1) {
      _pageController.jumpToPage(page > currentPage ? page - 1 : page + 1);
    }
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    if (result == true && mounted) {
      setState(() => _refreshScreen(_selectedIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedIndex != 0) _onItemTapped(0);
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE9ECF1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(-1 + (_selectedIndex * .5), 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / 5,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 5,
                        ),
                        child: DecoratedBox(
                          key: ValueKey('main-tab-$_selectedIndex'),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF45B),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          Icons.home_rounded,
                          'Beranda',
                          0,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          Icons.receipt_long_rounded,
                          'Transaksi',
                          1,
                        ),
                      ),
                      Expanded(child: _buildAddNavItem()),
                      Expanded(
                        child: _buildNavItem(
                          Icons.bar_chart_rounded,
                          'Laporan',
                          3,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          Icons.person_rounded,
                          'Profil',
                          4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddNavItem() {
    return Semantics(
      button: true,
      label: 'Tambah transaksi',
      child: GestureDetector(
        onTap: _openAddTransaction,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      key: ValueKey('main-nav-$index'),
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF171A12)
                  : const Color(0xFF8A94A3),
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF171A12)
                    : const Color(0xFF8A94A3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
