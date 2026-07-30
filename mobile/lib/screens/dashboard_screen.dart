import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  int _totalBalance = 0;
  List<Wallet> _wallets = [];
  List<TransactionItem> _recentTransactions = [];
  int _healthScore = 0;
  String _nudgeMessage = '';
  String _userName = 'Pengguna';
  List<Budget> _budgets = [];
  Map<String, int> _expenseByCategory = {};
  int _monthlyExpense = 0;
  int _monthlyBudget = 0;

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

      int total = 0;
      for (var w in wallets) {
        total += w.balance;
      }

      final monthlyTransactions = transactions.where(
        (tx) => tx.date.month == now.month && tx.date.year == now.year,
      );
      final expenseByCategory = <String, int>{};
      int monthlyExpense = 0;
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
        _monthlyBudget = budgets.fold(0, (sum, item) => sum + item.amount);
        _monthlyExpense = monthlyExpense;
        _expenseByCategory = expenseByCategory;
        _userName = (user?['name'] as String?)?.trim().isNotEmpty == true
            ? user!['name'] as String
            : 'Pengguna';
        if (healthData != null) {
          _healthScore = (healthData['score'] as num?)?.toInt() ?? 0;
          _nudgeMessage = healthData['nudgeMessage'] ?? '';
        } else {
          _healthScore = 72; // Fallback
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
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildBalanceCard(),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          if (_nudgeMessage.isNotEmpty) ...[
                            _buildNudgeBanner(),
                            const SizedBox(height: 24),
                          ],
                          _buildSectionTitle('Ringkasan bulan ini', null),
                          const SizedBox(height: 12),
                          _buildExpenseChart(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Budget', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BudgetScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          _buildBudgetCard(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Transaksi terbaru', null),
                          const SizedBox(height: 12),
                          _buildRecentTransactions(),
                          const SizedBox(height: 28),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Image.asset(
            'img/Logo Nala 4.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang,',
                style: const TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _showNotificationToast,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  CupertinoIcons.bell,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                Positioned(
                  right: 9,
                  top: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                  style: GoogleFonts.interTight(
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
              style: GoogleFonts.interTight(
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFA321), Color(0xFFF4820A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                    const Text(
                      'Total saldo',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        color: Color(0xE6FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                style: const TextStyle(
                                  fontFamily: '.SF Pro Display',
                                  color: Colors.white,
                                  fontSize: 29,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isBalanceVisible
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white,
                            size: 20,
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
                      style: const TextStyle(
                        fontFamily: '.SF Pro Text',
                        color: Color(0xE6FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildWalletBadge(primaryWallet?.type ?? 'CASH'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBadge(String type) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.20),
      ),
      child: Center(
        child: Icon(
          type == 'EWALLET'
              ? Icons.account_balance_wallet_rounded
              : type == 'BANK'
                  ? Icons.account_balance_rounded
                  : Icons.payments_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            CupertinoIcons.add,
            'Catat',
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
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            CupertinoIcons.chart_pie,
            'Budget',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            CupertinoIcons.heart,
            'Skor $_healthScore',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
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
            style: const TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Lihat semua',
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
      ],
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
              style: GoogleFonts.interTight(
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
                        entry.value.value.toDouble(),
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
                          style: GoogleFonts.interTight(
                            color: const Color(0xFF7D8794),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: _currencyFormat.format(_monthlyExpense),
                          style: GoogleFonts.interTight(
                            color: const Color(0xFF101217),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: _monthlyBudget > 0
                              ? ' dari ${_currencyFormat.format(_monthlyBudget)} budget'
                              : ' • belum ada budget',
                          style: GoogleFonts.interTight(
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
            style: GoogleFonts.interTight(
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
              style: GoogleFonts.interTight(
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
          style: GoogleFonts.interTight(
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
                      style: GoogleFonts.interTight(
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
                      style: GoogleFonts.interTight(
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
                style: GoogleFonts.interTight(
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
}
