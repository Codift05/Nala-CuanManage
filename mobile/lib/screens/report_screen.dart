import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_item_card.dart';
import '../services/transaction_service.dart';

class ReportScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ReportScreen({super.key, this.onBack});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _transactionService.getTransactions();
      final now = DateTime.now();
      final monthlyTransactions = transactions.where(
        (tx) => tx.date.month == now.month && tx.date.year == now.year,
      );

      double income = 0;
      double expense = 0;
      Map<String, double> categoryExpense = {};

      for (var tx in monthlyTransactions) {
        if (tx.type == 'INCOME') {
          income += tx.amount;
        } else {
          expense += tx.amount;
          String cat = tx.categoryId ?? 'Lainnya';
          categoryExpense[cat] = (categoryExpense[cat] ?? 0) + tx.amount;
        }
      }

      List<Map<String, dynamic>> catList = [];
      categoryExpense.forEach((key, value) {
        double percentage = expense > 0 ? (value / expense) * 100 : 0;

        IconData icon = Icons.receipt_long;
        Color iconColor = const Color(0xFF1954C2);
        Color iconBgColor = const Color(0xFFE2E8F0);

        if (key == 'Food' || key == 'Makanan') {
          icon = Icons.restaurant;
          iconColor = AppTheme.errorColor;
          iconBgColor = const Color(0xFFFFE0E0);
        } else if (key == 'Transport' || key == 'Transportasi') {
          icon = Icons.directions_car;
          iconColor = const Color(0xFFB45309);
          iconBgColor = const Color(0xFFFFEDD5);
        } else if (key == 'Belanja') {
          icon = Icons.shopping_bag_outlined;
          iconColor = const Color(0xFF3730A3);
          iconBgColor = const Color(0xFFE0E7FF);
        }

        catList.add({
          'title': key,
          'amount': value,
          'percentage': percentage,
          'icon': icon,
          'iconColor': iconColor,
          'iconBgColor': iconBgColor,
          'barColor': iconColor,
        });
      });

      catList.sort((a, b) => b['amount'].compareTo(a['amount']));

      if (!mounted) return;
      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _expenseCategories = catList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load report error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FC,
      ), // Slightly bluish-gray background to match the mockup
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadReport,
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
                      const SizedBox(height: 24),
                      _buildDatePicker(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(),
                      const SizedBox(height: 32),
                      _buildTrendChart(),
                      const SizedBox(height: 32),
                      Text(
                        'Terbesar Bulan Ini',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildExpenseList(),
                      const SizedBox(height: 32),
                      _buildExportButton(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (widget.onBack != null)
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
        if (widget.onBack != null) const SizedBox(width: 16),
        Text(
          'Laporan Keuangan',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEF6), // Light purple-gray
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chevron_left,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              _formatMonthYear(DateTime.now()),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildSummaryCard(
            title: 'Pemasukan',
            amount: _currencyFormat.format(_totalIncome),
            iconData: Icons.arrow_downward,
            iconColor: const Color(0xFF1954C2),
            iconBgColor: const Color(0xFFE2E8FF),
            badgeText: '+12%',
            badgeColor: const Color(0xFFE2E8FF),
            badgeTextColor: const Color(0xFF1954C2),
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            title: 'Pengeluaran',
            amount: _currencyFormat.format(_totalExpense),
            iconData: Icons.arrow_upward,
            iconColor: AppTheme.errorColor,
            iconBgColor: const Color(0xFFFFE5E5),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 12, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tren 3 Bulan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Icon(Icons.bar_chart, color: AppTheme.textPrimary),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 240,
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(const Color(0xFF1954C2), 'Masuk'),
                  const SizedBox(width: 16),
                  _buildLegendDot(AppTheme.errorColor, 'Keluar'),
                ],
              ),
              const Spacer(),
              // Placeholder for the actual chart bars
              const Divider(color: Color(0xFFEEEEEE), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildXAxisLabel('Mar', false),
                  _buildXAxisLabel('Apr', false),
                  _buildXAxisLabel('Mei', true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
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
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildXAxisLabel(String label, bool isSelected) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF1954C2) : AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildExpenseList() {
    if (_expenseCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            'Belum ada pengeluaran bulan ini.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _expenseCategories.map((cat) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ExpenseItemCard(
            icon: cat['icon'],
            iconBgColor: cat['iconBgColor'],
            iconColor: cat['iconColor'],
            title: cat['title'],
            amount: _currencyFormat.format(cat['amount']),
            percentage: (cat['percentage'] as num).toDouble(),
            barColor: cat['barColor'],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Export logic
        },
        icon: const Icon(Icons.download, color: Colors.white, size: 20),
        label: Text(
          'Ekspor sebagai PDF',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1954C2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
