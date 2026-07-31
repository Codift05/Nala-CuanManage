import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/budget_service.dart';
import '../models/budget.dart';
import '../widgets/load_error_view.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  bool _isLoading = true;
  String? _loadError;
  List<Budget> _budgets = [];
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final budgets = await _budgetService.getBudgets(
          month: _currentMonth, year: _currentYear);
      if (!mounted) return;
      setState(() => _budgets = budgets);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Anggaran belum dapat dimuat.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddBudgetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBudgetSheet(
        month: _currentMonth,
        year: _currentYear,
        onSaved: () {
          _loadBudgets();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Budget',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah anggaran',
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddBudgetSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? LoadErrorView(message: _loadError, onRetry: _loadBudgets)
              : _budgets.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadBudgets,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 24),
                          Text(
                            'Batas per kategori',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._budgets.map(_buildBudgetCard),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDF2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0DA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  size: 26,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada anggaran bulan ini',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _showAddBudgetSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Buat Anggaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _budgets.fold<int>(0, (sum, budget) => sum + budget.amount);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8738), Color(0xFFFFA04D)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL BUDGET BULAN INI',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: const Color(0xE6FFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currencyFormat.format(total),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${_budgets.length} kategori',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF54290B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    Color color = AppTheme.primaryColor;

    if (budget.categoryId == 'Food' || budget.categoryId == 'Makanan') {
      color = Colors.orange;
    } else if (budget.categoryId == 'Transport' ||
        budget.categoryId == 'Transportasi') {
      color = AppTheme.secondaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryId,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batas bulanan',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _currencyFormat.format(budget.amount),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBudgetSheet extends StatefulWidget {
  final int month;
  final int year;
  final VoidCallback onSaved;

  const _AddBudgetSheet(
      {required this.month, required this.year, required this.onSaved});

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _budgetService = BudgetService();

  final _amountController = TextEditingController();
  String _categoryId = 'Food';

  bool _isSaving = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Others'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    final budget = await _budgetService.createBudget(
      categoryId: _categoryId,
      amount: amount,
      month: widget.month,
      year: widget.year,
    );

    setState(() => _isSaving = false);

    if (budget != null && mounted) {
      Navigator.pop(context);
      widget.onSaved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Gagal menambahkan anggaran. Mungkin kategori sudah ada?')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Anggaran Baru',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                      value: c, child: Text(c, style: GoogleFonts.inter()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoryId = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Batas Anggaran Bulanan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) {
                  final amount = int.tryParse(
                        val?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
                      ) ??
                      0;
                  return amount > 0 ? null : 'Nominal harus lebih dari Rp 0';
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Anggaran',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
