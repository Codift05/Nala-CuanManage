import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/budget_service.dart';
import '../models/budget.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _budgetService = BudgetService();
  bool _isLoading = true;
  List<Budget> _budgets = [];

  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final budgets = await _budgetService.getBudgets(
        month: _currentMonth, year: _currentYear);
    setState(() {
      _budgets = budgets;
      _isLoading = false;
    });
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
        title: const Text('Anggaran Bulanan'),
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
          : _budgets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBudgets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      return _buildBudgetCard(budget);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada anggaran bulan ini',
            style: GoogleFonts.interTight(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showAddBudgetSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Buat Anggaran'),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    IconData icon = Icons.category;
    Color color = AppTheme.primaryColor;

    if (budget.categoryId == 'Food' || budget.categoryId == 'Makanan') {
      icon = Icons.restaurant;
      color = Colors.orange;
    } else if (budget.categoryId == 'Transport' ||
        budget.categoryId == 'Transportasi') {
      icon = Icons.directions_bus;
      color = AppTheme.secondaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryId,
                  style: GoogleFonts.interTight(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Batas: Rp ${budget.amount.toInt()}',
                  style: GoogleFonts.interTight(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final amount = double.tryParse(
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
                style: GoogleFonts.interTight(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.interTight()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoryId = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.interTight(),
                decoration: InputDecoration(
                  labelText: 'Batas Anggaran Bulanan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Batas anggaran tidak boleh kosong'
                    : null,
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
                          style: GoogleFonts.interTight(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
