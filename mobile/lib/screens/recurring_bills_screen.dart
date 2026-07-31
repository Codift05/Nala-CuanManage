import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/recurring_service.dart';
import '../services/wallet_service.dart';
import '../models/recurring_bill.dart';
import '../models/wallet.dart';
import '../widgets/load_error_view.dart';

class RecurringBillsScreen extends StatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  final _recurringService = RecurringService();
  bool _isLoading = true;
  String? _loadError;
  List<RecurringBill> _bills = [];
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final bills = await _recurringService.getRecurringBills();
      if (!mounted) return;
      setState(() => _bills = bills);
    } catch (_) {
      if (mounted) setState(() => _loadError = 'Tagihan belum dapat dimuat.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddBillSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRecurringBillSheet(
        onSaved: () {
          _loadBills();
        },
      ),
    );
  }

  Future<void> _deleteBill(String id) async {
    final success = await _recurringService.deleteRecurringBill(id);
    if (success) {
      _loadBills();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus tagihan')),
        );
      }
    }
  }

  Future<void> _confirmDeleteBill(RecurringBill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tagihan?'),
        content: Text('${bill.title} tidak akan diproses lagi setiap bulan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteBill(bill.id);
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
          'Tagihan Berulang',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah tagihan',
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddBillSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? LoadErrorView(message: _loadError, onRetry: _loadBills)
              : _bills.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadBills,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 24),
                          Text(
                            'Jadwal bulanan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._bills.map(_buildBillCard),
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
                  Icons.event_repeat_rounded,
                  size: 26,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Belum ada tagihan rutin',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _showAddBillSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Buat Tagihan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _bills.fold<int>(0, (sum, bill) => sum + bill.amount);
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
                  'TOTAL TAGIHAN BULANAN',
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
              '${_bills.length} tagihan',
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

  Widget _buildBillCard(RecurringBill bill) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0DA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TGL',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${bill.dueDate}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bill.categoryId} • ${bill.walletName ?? 'Dompet'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(bill.amount),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _confirmDeleteBill(bill),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddRecurringBillSheet extends StatefulWidget {
  final VoidCallback onSaved;

  const _AddRecurringBillSheet({required this.onSaved});

  @override
  State<_AddRecurringBillSheet> createState() => _AddRecurringBillSheetState();
}

class _AddRecurringBillSheetState extends State<_AddRecurringBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _recurringService = RecurringService();
  final _walletService = WalletService();

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _categoryId = 'Bills';
  String? _selectedWalletId;
  List<Wallet> _wallets = [];
  bool _isLoadingWallets = true;
  String? _walletLoadError;
  bool _isSaving = false;

  final List<String> _categories = [
    'Bills',
    'Entertainment',
    'Transport',
    'Food',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        if (_wallets.isNotEmpty) _selectedWalletId = _wallets.first.id;
        _isLoadingWallets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletLoadError = 'Daftar wallet belum dapat dimuat.';
        _isLoadingWallets = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedWalletId == null) return;

    setState(() => _isSaving = true);

    final amount = int.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    final dueDate = int.tryParse(_dueDateController.text) ?? 1;

    final bill = await _recurringService.createRecurringBill(
      title: _titleController.text,
      amount: amount,
      categoryId: _categoryId,
      walletId: _selectedWalletId!,
      dueDate: dueDate,
    );

    setState(() => _isSaving = false);

    if (bill != null && mounted) {
      Navigator.pop(context);
      widget.onSaved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan tagihan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingWallets || _walletLoadError != null) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: _isLoadingWallets
              ? const CircularProgressIndicator()
              : Text(
                  _walletLoadError!,
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
        ),
      );
    }

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
                'Tambah Tagihan Rutin',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Nama Tagihan (Misal: Netflix, Listrik)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(),
                      decoration: InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (val) {
                        final amount = int.tryParse(
                              val?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
                            ) ??
                            0;
                        return amount > 0 ? null : 'Nominal tidak valid';
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _dueDateController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(),
                      decoration: InputDecoration(
                        labelText: 'Tgl (1-31)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Isi tgl';
                        final num = int.tryParse(val);
                        if (num == null || num < 1 || num > 31) {
                          return 'Tgl tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category, style: GoogleFonts.inter()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _categoryId = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedWalletId,
                decoration: InputDecoration(
                  labelText: 'Sumber dana',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                items: _wallets.map((w) {
                  return DropdownMenuItem(
                      value: w.id,
                      child: Text(w.name, style: GoogleFonts.inter()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedWalletId = val);
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
                          'Simpan Tagihan',
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
