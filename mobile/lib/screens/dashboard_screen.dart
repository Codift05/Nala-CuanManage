import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/donut_chart.dart';
import 'health_screen.dart';
import '../services/wallet_service.dart';
import '../services/transaction_service.dart';
import '../services/health_service.dart';
import '../services/budget_service.dart';
import '../services/auth_service.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../models/budget.dart';
import 'budget_screen.dart';
import 'add_transaction_screen.dart';
import 'package:telephony/telephony.dart';
import 'package:home_widget/home_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final HealthService _healthService = HealthService();
  final BudgetService _budgetService = BudgetService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isBalanceVisible = true;
  double _totalBalance = 0;
  List<Wallet> _wallets = [];
  List<TransactionItem> _recentTransactions = [];
  int _healthScore = 0;
  String _healthStatus = 'Memuat...';
  String _nudgeMessage = '';
  String _userName = 'Pengguna';
  List<Budget> _budgets = [];
  Map<String, double> _expenseByCategory = {};
  double _monthlyExpense = 0;
  double _monthlyBudget = 0;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final Telephony telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    _loadData(showFullScreenLoader: true);
    _initHomeWidget();
    _initSmsListener();
  }

  void _initHomeWidget() {
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri?.host == 'add_transaction' && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ).then((result) {
          if (result == true && mounted) _loadData();
        });
      }
    });
  }

  void _initSmsListener() async {
    try {
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      if (permissionsGranted ?? false) {
        telephony.listenIncomingSms(
          onNewMessage: (SmsMessage message) {
            if (!mounted) return;
            String text = message.body?.toLowerCase() ?? '';
            if (text.contains('berhasil') &&
                (text.contains('gopay') || text.contains('bca'))) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ada SMS pemotongan dana terdeteksi!'),
                  action: SnackBarAction(
                    label: 'Catat ke Nala',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        ),
                      ).then((result) {
                        if (result == true && mounted) _loadData();
                      });
                    },
                  ),
                  duration: const Duration(seconds: 10),
                ),
              );
            }
          },
          listenInBackground: false,
        );
      }
    } catch (e) {
      debugPrint('SMS listener error: $e');
    }
  }

  Future<T> _safeLoad<T>(Future<T> request, T fallback) async {
    try {
      return await request.timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('Dashboard request failed: $error');
      return fallback;
    }
  }

  Future<void> refresh() => _loadData();

  Future<void> _loadData({bool showFullScreenLoader = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = showFullScreenLoader;
        _isRefreshing = !showFullScreenLoader;
      });
    }

    try {
      final now = DateTime.now();
      final results = await Future.wait<Object?>([
        _safeLoad<List<Wallet>>(
          _walletService.getWallets(),
          const <Wallet>[],
        ),
        _safeLoad<List<TransactionItem>>(
          _transactionService.getTransactions(),
          const <TransactionItem>[],
        ),
        _safeLoad<Map<String, dynamic>?>(
          _healthService.getHealthScore(),
          null,
        ),
        _safeLoad<List<Budget>>(
          _budgetService.getBudgets(month: now.month, year: now.year),
          const <Budget>[],
        ),
        _safeLoad<Map<String, dynamic>?>(
          _authService.getCurrentUser(),
          null,
        ),
      ]);

      final wallets = results[0] as List<Wallet>;
      final transactions = results[1] as List<TransactionItem>;
      final healthData = results[2] as Map<String, dynamic>?;
      final budgets = results[3] as List<Budget>;
      final user = results[4] as Map<String, dynamic>?;

      double total = 0;
      for (var w in wallets) {
        total += w.balance;
      }

      final monthlyTransactions = transactions.where(
        (tx) => tx.date.month == now.month && tx.date.year == now.year,
      );
      final expenseByCategory = <String, double>{};
      double monthlyExpense = 0;
      for (final tx in monthlyTransactions) {
        if (tx.type != 'EXPENSE') continue;
        monthlyExpense += tx.amount;
        final category = tx.categoryId ?? 'Lainnya';
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + tx.amount;
      }

      if (!mounted) return;

      setState(() {
        _wallets = wallets;
        _totalBalance = total;
        _recentTransactions = transactions.take(3).toList();
        _budgets = budgets;
        _monthlyBudget = budgets.fold(0.0, (sum, item) => sum + item.amount);
        _monthlyExpense = monthlyExpense;
        _expenseByCategory = expenseByCategory;
        _userName = (user?['name'] as String?)?.trim().isNotEmpty == true
            ? user!['name'] as String
            : 'Pengguna';
        if (healthData != null) {
          _healthScore = (healthData['score'] as num?)?.toInt() ?? 0;
          _healthStatus = healthData['status'] as String? ?? 'Belum tersedia';
          _nudgeMessage = healthData['nudgeMessage'] ?? '';
        } else {
          _healthScore = 72; // Fallback
          _healthStatus = 'Cukup Sehat';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 18),
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildBalanceCard(),
                          const SizedBox(height: 26),
                          if (_nudgeMessage.isNotEmpty) ...[
                            _buildNudgeBanner(),
                            const SizedBox(height: 20),
                          ],
                          _buildHealthCard(context),
                          const SizedBox(height: 26),
                          _buildSectionTitle('Pengeluaran Bulan Ini', null),
                          const SizedBox(height: 12),
                          _buildExpenseChart(),
                          const SizedBox(height: 26),
                          _buildSectionTitle('Budget Bulan Ini', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BudgetScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          _buildBudgetCard(),
                          const SizedBox(height: 26),
                          _buildSectionTitle('Transactions', () {}),
                          const SizedBox(height: 12),
                          _buildRecentTransactions(),
                          const SizedBox(height: 26),
                          _buildSectionTitle('Weekly insights', null),
                          const SizedBox(height: 12),
                          _buildWeeklyInsights(context),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  if (_isRefreshing)
                    const Positioned(
                      top: 0,
                      left: 22,
                      right: 22,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: AppTheme.primaryColor,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  height: 1,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101217),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hi, $_userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7D8794),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showNotificationToast,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeaderIcon(Icons.notifications_rounded),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D7A),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFF4F6FA), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: 25, color: const Color(0xFF0E1116)),
      ),
    );
  }

  void _showNotificationToast() {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        tween:
            Tween(begin: -100.0, end: MediaQuery.of(context).padding.top + 28),
        builder: (context, value, child) {
          return Positioned(
            top: value,
            left: 24,
            right: 24,
            child: Material(color: Colors.transparent, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF3FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belum ada notifikasi baru',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF101217),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 22, color: Color(0xFF7A8492)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A94A3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates_rounded,
              color: Color(0xFFB45309),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _nudgeMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final primaryWallet = _wallets.isNotEmpty ? _wallets.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _isBalanceVisible
                                    ? _currencyFormat.format(_totalBalance)
                                    : 'Rp •••••••',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF101217),
                                  fontSize: 31,
                                  height: 1,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isBalanceVisible
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.visibility_off_rounded,
                            color: const Color(0xFF101217),
                            size: 23,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      primaryWallet == null
                          ? 'Tidak ada wallet aktif'
                          : '${primaryWallet.name} · Active',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF101217),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildWalletBadge(primaryWallet?.type ?? 'CASH'),
            ],
          ),
          const SizedBox(height: 18),
          _buildQuickAction(
            Icons.add_rounded,
            'Tambah transaksi',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddTransactionScreen(),
                ),
              ).then((result) {
                if (result == true && mounted) _loadData();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBadge(String type) {
    final colors = switch (type) {
      'EWALLET' => [AppTheme.primaryColor, AppTheme.secondaryColor],
      'BANK' => [AppTheme.secondaryColor, AppTheme.primaryColor],
      _ => [AppTheme.secondaryColor, AppTheme.primaryColor],
    };

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          type == 'EWALLET'
              ? Icons.account_balance_wallet_rounded
              : type == 'BANK'
                  ? Icons.account_balance_rounded
                  : Icons.payments_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 14 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback? onSeeAll) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7D8794),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHealthCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kesehatan Keuangan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101217),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skor $_healthScore • $_healthStatus',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A94A3)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart() {
    final entries = _expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const colors = [
      AppTheme.secondaryColor,
      AppTheme.primaryColor,
      AppTheme.primaryColor,
      Color(0xFF10B981),
      Color(0xFF7C3AED),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: entries.isEmpty
          ? Text(
              'Belum ada pengeluaran bulan ini.',
              style: GoogleFonts.inter(
                color: const Color(0xFF7D8794),
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: [
                SizedBox(
                  width: 124,
                  height: 124,
                  child: DonutChart(
                    strokeWidth: 15,
                    data: entries.asMap().entries.map((entry) {
                      return DonutChartData(
                        entry.value.value,
                        colors[entry.key % colors.length],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: entries.asMap().entries.map((entry) {
                        final percentage = _monthlyExpense > 0
                            ? (entry.value.value / _monthlyExpense) * 100
                            : 0.0;
                        return SizedBox(
                          width: itemWidth,
                          child: _buildLegendItem(
                            colors[entry.key % colors.length],
                            '${entry.value.key} ${percentage.toStringAsFixed(0)}%',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFE8ECF2), height: 1),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Total ',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7D8794),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: _currencyFormat.format(_monthlyExpense),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF101217),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: _monthlyBudget > 0
                              ? ' dari ${_currencyFormat.format(_monthlyBudget)} budget'
                              : ' • belum ada budget',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7D8794),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF7D8794),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _budgets.isEmpty
          ? Text(
              'Belum ada budget bulan ini.',
              style: GoogleFonts.inter(
                color: const Color(0xFF7D8794),
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              children: _budgets.asMap().entries.expand((entry) {
                final budget = entry.value;
                final spent = _expenseByCategory[budget.categoryId] ?? 0;
                final percentage =
                    budget.amount > 0 ? (spent / budget.amount) * 100 : 0.0;
                final color = percentage > 100
                    ? AppTheme.errorColor
                    : percentage >= 75
                        ? AppTheme.warningColor
                        : AppTheme.successColor;

                return [
                  if (entry.key > 0) const SizedBox(height: 18),
                  BudgetProgressBar(
                    label: budget.categoryId,
                    percentage: percentage,
                    activeColor: color,
                  ),
                ];
              }).toList(),
            ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Belum ada transaksi.',
          style: GoogleFonts.inter(
            color: const Color(0xFF7D8794),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: _recentTransactions.asMap().entries.map((entry) {
          int index = entry.key;
          TransactionItem item = entry.value;

          final icon = item.type == 'INCOME'
              ? Icons.arrow_downward_rounded
              : _categoryIcon(item.categoryId);
          final color = item.type == 'INCOME'
              ? const Color(0xFF10B981)
              : AppTheme.secondaryColor;
          String prefix = item.type == 'INCOME' ? '+' : '-';

          return _buildTransactionItem(
            icon,
            item.merchant ?? 'Transaksi',
            item.categoryId ?? item.type,
            '$prefix${_currencyFormat.format(item.amount)}',
            color,
            isLast: index == _recentTransactions.length - 1,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(
    IconData icon,
    String title,
    String subtitle,
    String amount,
    Color amountColor, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: amountColor, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF101217),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7D8794),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: const Color(0xFF101217),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Divider(
              color: const Color(0xFFE8ECF2),
              height: 1,
            ),
          ),
      ],
    );
  }

  IconData _categoryIcon(String? category) {
    final normalized = (category ?? '').toLowerCase();
    if (normalized.contains('food') || normalized.contains('makan')) {
      return Icons.restaurant_rounded;
    }
    if (normalized.contains('transport')) return Icons.directions_car_rounded;
    if (normalized.contains('salary') || normalized.contains('gaji')) {
      return Icons.work_rounded;
    }
    if (normalized.contains('grocer')) return Icons.local_grocery_store_rounded;
    return Icons.shopping_bag_rounded;
  }

  Widget _buildWeeklyInsights(BuildContext context) {
    final budgetUsage = _monthlyBudget > 0
        ? ((_monthlyExpense / _monthlyBudget) * 100).clamp(0, 999).round()
        : 0;
    final topCategory = _expenseByCategory.entries.isEmpty
        ? 'budget'
        : (_expenseByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return SizedBox(
      height: 184,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildInsightCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Financial score',
            body: 'Skor kamu $_healthScore, $_healthStatus',
            color: const Color(0xFF111827),
            imageColor: const Color(0xFFEEF3FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HealthScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
          _buildInsightCard(
            icon: Icons.local_grocery_store_rounded,
            title: 'Most spending',
            body: 'Pengeluaran terbesar ada di $topCategory',
            color: AppTheme.secondaryColor,
            imageColor: const Color(0xFFFFEEF2),
          ),
          const SizedBox(width: 12),
          _buildInsightCard(
            icon: Icons.track_changes_rounded,
            title: 'Budget progress',
            body: _monthlyBudget > 0
                ? '$budgetUsage% budget bulan ini sudah dipakai'
                : 'Budget bulan ini belum dibuat',
            color: AppTheme.primaryColor,
            imageColor: const Color(0xFFEEF3FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
    required Color imageColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 172,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  color: imageColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF9AA3AF),
                      size: 18,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7D8794),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF101217),
                    fontSize: 16,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
