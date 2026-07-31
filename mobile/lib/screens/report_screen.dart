import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/expense_item_card.dart';
import '../widgets/load_error_view.dart';
import '../services/transaction_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with AutomaticKeepAliveClientMixin {
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  String? _loadError;
  int _totalIncome = 0;
  int _totalExpense = 0;
  List<Map<String, dynamic>> _expenseCategories = [];
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _trendData = [];

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

  String _formatMonthShort(DateTime d) {
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
    return months[d.month - 1];
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final transactions = await _transactionService.getTransactions();
      final monthlyTransactions = transactions.where(
        (tx) =>
            tx.date.month == _selectedDate.month &&
            tx.date.year == _selectedDate.year,
      );

      int income = 0;
      int expense = 0;
      Map<String, int> categoryExpense = {};

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
        Color iconColor = AppTheme.primaryColor;
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

      List<Map<String, dynamic>> trendData = [];
      for (int i = 2; i >= 0; i--) {
        DateTime monthDate =
            DateTime(_selectedDate.year, _selectedDate.month - i);
        final monthTxs = transactions.where((tx) =>
            tx.date.month == monthDate.month && tx.date.year == monthDate.year);
        int inc = 0;
        int exp = 0;
        for (var tx in monthTxs) {
          if (tx.type == 'INCOME') {
            inc += tx.amount;
          } else {
            exp += tx.amount;
          }
        }
        trendData.add({
          'month': _formatMonthShort(monthDate),
          'income': inc,
          'expense': exp,
        });
      }

      if (!mounted) return;
      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _expenseCategories = catList;
        _trendData = trendData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load report error: $e');
      if (mounted) {
        setState(() {
          _loadError = 'Laporan belum dapat dimuat.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? LoadErrorView(message: _loadError, onRetry: _loadReport)
                : RefreshIndicator(
                    onRefresh: _loadReport,
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
                          const SizedBox(height: 16),
                          _buildDatePicker(),
                          const SizedBox(height: 16),
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildTrendChart(),
                          const SizedBox(height: 24),
                          Text(
                            'Pengeluaran terbesar',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildExpenseList(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildHeader() {
    return Text(
      'Laporan',
      style: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _selectedDate =
                  DateTime(_selectedDate.year, _selectedDate.month - 1));
              _loadReport();
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.chevron_left,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatMonthYear(_selectedDate),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _selectedDate =
                  DateTime(_selectedDate.year, _selectedDate.month + 1));
              _loadReport();
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Pemasukan',
            amount: _currencyFormat.format(_totalIncome),
            iconData: Icons.south_west_rounded,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            title: 'Pengeluaran',
            amount: _currencyFormat.format(_totalExpense),
            iconData: Icons.north_east_rounded,
            color: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData iconData,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
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
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 15, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Icon(
              Icons.bar_chart_rounded,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(AppTheme.primaryColor, 'Masuk'),
                  const SizedBox(width: 16),
                  _buildLegendDot(AppTheme.errorColor, 'Keluar'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _trendData.isEmpty
                    ? const SizedBox()
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.center,
                          groupsSpace: 50,
                          maxY: _trendData.fold<double>(0, (max, e) {
                                final inc = (e['income'] as int).toDouble();
                                final exp = (e['expense'] as int).toDouble();
                                final val = inc > exp ? inc : exp;
                                return val > max ? val : max;
                              }) *
                              1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < _trendData.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _trendData[index]['month'],
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: index == 2
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: index == 2
                                              ? AppTheme.primaryColor
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color(0xFFEEEEEE), width: 1),
                            ),
                          ),
                          barGroups: _trendData.asMap().entries.map((e) {
                            final index = e.key;
                            final data = e.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (data['income'] as int).toDouble(),
                                  color: AppTheme.primaryColor,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                                BarChartRodData(
                                  toY: (data['expense'] as int).toDouble(),
                                  color: AppTheme.errorColor,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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

  Widget _buildExpenseList() {
    if (_expenseCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAEDF2)),
        ),
        child: Text(
          'Belum ada pengeluaran bulan ini.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
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
}
