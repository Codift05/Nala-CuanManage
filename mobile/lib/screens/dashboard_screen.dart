import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/donut_chart.dart';
import '../widgets/budget_progress_bar.dart';
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
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();
  final HealthService _healthService = HealthService();
  final BudgetService _budgetService = BudgetService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
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
    _loadData();
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
                      );
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

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final wallets = await _walletService.getWallets();
      final transactions = await _transactionService.getTransactions();
      final healthData = await _healthService.getHealthScore();
      final now = DateTime.now();
      final budgets = await _budgetService.getBudgets(
        month: now.month,
        year: now.year,
      );
      final user = await _authService.getCurrentUser();

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
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (_nudgeMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNudgeBanner(),
                      ],
                      const SizedBox(height: 24),
                      _buildBalanceCard(),
                      const SizedBox(height: 24),
                      _buildHealthCard(context),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Pengeluaran Bulan Ini', null),
                      const SizedBox(height: 16),
                      _buildExpenseChart(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Budget Bulan Ini', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetScreen(),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      _buildBudgetCard(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Terakhir', () {}),
                      const SizedBox(height: 16),
                      _buildRecentTransactions(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final parts = _userName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    final initials = parts.isEmpty
        ? 'NA'
        : parts.map((part) => part[0].toUpperCase()).join();

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF1954C2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Hai, $_userName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Stack(
          children: [
            const Icon(
              Icons.notifications_none,
              size: 28,
              color: AppTheme.textPrimary,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.backgroundColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNudgeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5), // Light orange/yellow background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB74D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _nudgeMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB45309), // Dark orange text
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Saldo',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(_totalBalance),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _wallets.map((wallet) {
              IconData icon = Icons.account_balance_wallet;
              Color color = Colors.white;
              if (wallet.type == 'CASH') {
                icon = Icons.money;
                color = Colors.greenAccent;
              } else if (wallet.type == 'EWALLET') {
                icon = Icons.favorite;
                color = Colors.lightBlueAccent;
              }

              String label =
                  '${wallet.name} ${_currencyFormat.format(wallet.balance)}';
              return _buildAccountChip(icon, label, color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChip(IconData icon, String label, Color iconColor) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 80,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Lihat semua \u2192',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1954C2),
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
      AppTheme.errorColor,
      AppTheme.infoColor,
      AppTheme.warningColor,
      AppTheme.successColor,
      AppTheme.secondaryColor,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: entries.isEmpty
          ? Text(
              'Belum ada pengeluaran bulan ini.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            )
          : Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                Divider(color: Colors.grey.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Total ',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_monthlyExpense),
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _monthlyBudget > 0
                            ? ' dari ${_currencyFormat.format(_monthlyBudget)} budget'
                            : ' • belum ada budget',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _budgets.isEmpty
          ? Text(
              'Belum ada budget bulan ini.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            )
          : Column(
              children: _budgets.asMap().entries.expand((entry) {
                final budget = entry.value;
                final spent = _expenseByCategory[budget.categoryId] ?? 0;
                final percentage = budget.amount > 0
                    ? (spent / budget.amount) * 100
                    : 0.0;
                final color = percentage > 100
                    ? AppTheme.errorColor
                    : percentage >= 75
                    ? AppTheme.warningColor
                    : AppTheme.successColor;

                return [
                  if (entry.key > 0) const SizedBox(height: 20),
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
      return const Text("Belum ada transaksi.");
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: _recentTransactions.asMap().entries.map((entry) {
          int index = entry.key;
          TransactionItem item = entry.value;

          IconData icon = item.type == 'INCOME'
              ? Icons.arrow_downward
              : Icons.shopping_bag_outlined;
          Color color = item.type == 'INCOME'
              ? AppTheme.successColor
              : AppTheme.errorColor;
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
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor, // light gray
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF4A4A4A)),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Text(
            amount,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: amountColor,
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 80, right: 20),
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.1),
              height: 1,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8FF), // Light blue tint
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1954C2).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1954C2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kesehatan Keuangan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Skor $_healthScore • $_healthStatus',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1954C2),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF1954C2)),
          ],
        ),
      ),
    );
  }
}
