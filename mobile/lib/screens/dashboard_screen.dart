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
import '../models/wallet.dart';
import '../models/transaction.dart';
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
  
  bool _isLoading = true;
  double _totalBalance = 0;
  List<Wallet> _wallets = [];
  List<TransactionItem> _recentTransactions = [];
  int _healthScore = 0;
  String _healthStatus = 'Memuat...';
  String _nudgeMessage = '';

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
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
            if (text.contains('berhasil') && (text.contains('gopay') || text.contains('bca'))) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Ada SMS pemotongan dana terdeteksi!'),
                  action: SnackBarAction(
                    label: 'Catat ke Nala',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
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
      print('SMS listener error: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final wallets = await _walletService.getWallets();
      final transactions = await _transactionService.getTransactions(limit: 3);
      final healthData = await _healthService.getHealthScore();
      
      double total = 0;
      for (var w in wallets) {
        total += w.balance;
      }
      
      setState(() {
        _wallets = wallets;
        _totalBalance = total;
        _recentTransactions = transactions;
        if (healthData != null) {
          _healthScore = healthData['score'];
          _healthStatus = healthData['status'];
          _nudgeMessage = healthData['nudgeMessage'] ?? '';
        } else {
          _healthScore = 72; // Fallback
          _healthStatus = 'Cukup Sehat';
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      );
                    }),
                    const SizedBox(height: 16),
                    _buildBudgetCard(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Terakhir', () {}),
                    const SizedBox(height: 16),
                    _buildRecentTransactions(),
                    const SizedBox(height: 80), // Extra space for bottom nav
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
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
              'MI',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Haii, Mip',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Stack(
          children: [
            const Icon(Icons.notifications_none, size: 28, color: AppTheme.textPrimary),
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
        border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB74D),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tips_and_updates, color: Colors.white, size: 20),
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
              Icon(Icons.visibility_outlined, color: Colors.white.withValues(alpha: 0.7), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_totalBalance),
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
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
              
              String label = '${wallet.name} ${_currencyFormat.format(wallet.balance)}';
              return _buildAccountChip(icon, label, color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChip(IconData icon, String label, Color iconColor) {
    return Container(
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
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
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
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: DonutChart(
                  strokeWidth: 14,
                  data: [
                    DonutChartData(32, AppTheme.errorColor),
                    DonutChartData(18, AppTheme.infoColor),
                    DonutChartData(14, AppTheme.warningColor),
                    DonutChartData(36, AppTheme.neutralColor),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildLegendItem(AppTheme.errorColor, 'Makan 32%')),
                        Expanded(child: _buildLegendItem(AppTheme.infoColor, 'Transport 18%')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildLegendItem(AppTheme.warningColor, 'Belanja 14%')),
                        Expanded(child: _buildLegendItem(AppTheme.neutralColor, 'Lainnya 36%')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Total ',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
              ),
              Text(
                'Rp 1.840.000',
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                ' dari Rp 2.500.000 budget',
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
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
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 12,
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
      child: const Column(
        children: [
          BudgetProgressBar(
            label: 'Makan',
            percentage: 78,
            activeColor: AppTheme.warningColor,
          ),
          SizedBox(height: 20),
          BudgetProgressBar(
            label: 'Transport',
            percentage: 52,
            activeColor: AppTheme.successColor,
          ),
          SizedBox(height: 20),
          BudgetProgressBar(
            label: 'Belanja',
            percentage: 102,
            activeColor: AppTheme.errorColor,
          ),
        ],
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
          
          IconData icon = item.type == 'INCOME' ? Icons.arrow_downward : Icons.shopping_bag_outlined;
          Color color = item.type == 'INCOME' ? AppTheme.successColor : AppTheme.errorColor;
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

  Widget _buildTransactionItem(IconData icon, String title, String subtitle, String amount, Color amountColor, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
            child: Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
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
          border: Border.all(color: const Color(0xFF1954C2).withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1954C2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety, color: Colors.white, size: 24),
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
