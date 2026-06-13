import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/recurring_service.dart';
import '../services/wallet_service.dart';
import '../models/recurring_bill.dart';
import '../models/wallet.dart';

class RecurringBillsScreen extends StatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  final _recurringService = RecurringService();
  bool _isLoading = true;
  List<RecurringBill> _bills = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    final bills = await _recurringService.getRecurringBills();
    setState(() {
      _bills = bills;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tagihan Rutin',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _showAddBillSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bills.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBills,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _bills.length,
                    itemBuilder: (context, index) {
                      final bill = _bills[index];
                      return _buildBillCard(bill);
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
          Icon(Icons.autorenew, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada tagihan rutin',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showAddBillSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Buat Tagihan'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(RecurringBill bill) {
    IconData icon = Icons.receipt_long;
    Color color = AppTheme.primaryColor;

    if (bill.categoryId.toLowerCase() == 'bills' || bill.categoryId.toLowerCase() == 'tagihan') {
      icon = Icons.receipt;
      color = const Color(0xFF1954C2);
    } else if (bill.categoryId.toLowerCase() == 'entertainment' || bill.categoryId.toLowerCase() == 'hiburan') {
      icon = Icons.movie;
      color = const Color(0xFFE91E63);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  bill.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tgl ${bill.dueDate} • ${bill.walletName ?? 'Dompet'}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _deleteBill(bill.id),
                child: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
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
    final wallets = await _walletService.getWallets();
    setState(() {
      _wallets = wallets;
      if (_wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first.id;
      }
      _isLoadingWallets = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedWalletId == null) return;
    
    setState(() => _isSaving = true);
    
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
    if (_isLoadingWallets) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Nama Tagihan (Misal: Netflix, Listrik)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Isi nominal' : null,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Isi tgl';
                        final num = int.tryParse(val);
                        if (num == null || num < 1 || num > 31) return 'Tgl tidak valid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                decoration: InputDecoration(
                  labelText: 'Sumber Dana (Otomatis potong)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _wallets.map((w) {
                  return DropdownMenuItem(value: w.id, child: Text(w.name, style: GoogleFonts.inter()));
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Tagihan',
                          style: GoogleFonts.inter(
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
