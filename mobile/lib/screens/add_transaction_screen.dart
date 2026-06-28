import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';

class RupiahInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  String formatNumber(num value) => _formatter.format(value);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }

    final value = int.tryParse(digits);
    if (value == null) return oldValue;

    final formatted = _formatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final TransactionItem? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionService = TransactionService();
  final _walletService = WalletService();

  String _type = 'EXPENSE';
  String? _selectedWalletId;
  String? _selectedCategory;
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  final _rupiahFormatter = RupiahInputFormatter();

  List<Wallet> _wallets = [];
  bool _isLoading = false;

  List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Income',
    'Salary',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _type = widget.transactionToEdit!.type;
      _amountController.text = _rupiahFormatter.formatNumber(
        widget.transactionToEdit!.amount.round(),
      );
      _selectedCategory = widget.transactionToEdit!.categoryId;
      if (_selectedCategory != null &&
          !_categories.contains(_selectedCategory!)) {
        _categories.add(_selectedCategory!);
      }
      _selectedWalletId = widget.transactionToEdit!.walletId;
      _merchantController.text = widget.transactionToEdit!.merchant ?? '';
      _notesController.text = widget.transactionToEdit!.notes ?? '';
    }
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.getWallets();
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      if (_selectedWalletId == null && _wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first.id;
      }
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final amount = double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    Map<String, dynamic>? result;
    if (widget.transactionToEdit != null) {
      result = await _transactionService.updateTransaction(
        id: widget.transactionToEdit!.id,
        walletId: _selectedWalletId!,
        type: _type,
        amount: amount,
        categoryId: _selectedCategory,
        merchant: _merchantController.text.isNotEmpty
            ? _merchantController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
    } else {
      result = await _transactionService.createTransaction(
        walletId: _selectedWalletId!,
        type: _type,
        amount: amount,
        categoryId: _selectedCategory,
        merchant: _merchantController.text.isNotEmpty
            ? _merchantController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      if (result['warning'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['warning']),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil ditambahkan'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      Navigator.pop(context, true); // return true to indicate success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan transaksi'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
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
          widget.transactionToEdit != null
              ? 'Edit Transaksi'
              : 'Tambah Transaksi',
        ),
      ),
      body: _wallets.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 22),
                    _buildAmountInput(),
                    const SizedBox(height: 22),
                    _buildWalletSelector(),
                    const SizedBox(height: 22),
                    _buildCategorySelector(),
                    const SizedBox(height: 22),
                    _buildTextField(
                      label: 'Merchant / Toko',
                      controller: _merchantController,
                      hint: 'Misal: Indomaret, Gofood...',
                    ),
                    const SizedBox(height: 22),
                    _buildTextField(
                      label: 'Catatan',
                      controller: _notesController,
                      hint: 'Tambahkan catatan opsional',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTransaction,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Simpan Transaksi',
                                style: GoogleFonts.interTight(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: _type,
        backgroundColor: const Color(0xFFE9ECF2),
        thumbColor: Colors.white,
        padding: const EdgeInsets.all(4),
        children: {
          'EXPENSE': _buildSegmentLabel(
            'Pengeluaran',
            _type == 'EXPENSE' ? AppTheme.errorColor : AppTheme.textSecondary,
          ),
          'INCOME': _buildSegmentLabel(
            'Pemasukan',
            _type == 'INCOME' ? AppTheme.successColor : AppTheme.textSecondary,
          ),
        },
        onValueChanged: (value) {
          if (value == null) return;
          setState(() {
            _type = value;
            _selectedCategory = value == 'EXPENSE' ? 'Food' : 'Income';
          });
        },
      ),
    );
  }

  Widget _buildSegmentLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.interTight(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nominal',
          style: GoogleFonts.interTight(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [_rupiahFormatter],
          style: GoogleFonts.interTight(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: GoogleFonts.interTight(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary.withValues(alpha: 0.55),
            ),
            fillColor: Colors.white,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 58,
              minHeight: 56,
            ),
            prefixIcon: Center(
              widthFactor: 1,
              child: Text(
                'Rp',
                style: GoogleFonts.interTight(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
              borderSide: const BorderSide(
                color: AppTheme.textSecondary,
                width: 1,
              ),
            ),
          ),
          validator: (value) {
            final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
            if (digits.isEmpty) {
              return 'Nominal tidak boleh kosong';
            }
            if (int.tryParse(digits) == null || int.parse(digits) <= 0) {
              return 'Nominal tidak valid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWalletSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dompet / Sumber Dana',
          style: GoogleFonts.interTight(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedWalletId,
          decoration: const InputDecoration(),
          items: _wallets.map((w) {
            return DropdownMenuItem(
              value: w.id,
              child: Text(w.name, style: GoogleFonts.interTight()),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedWalletId = val);
          },
          hint: const Text('Pilih Dompet'),
          validator: (value) => value == null ? 'Pilih dompet' : null,
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: GoogleFonts.interTight(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(),
          items: _categories.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c, style: GoogleFonts.interTight()),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedCategory = val);
          },
          hint: const Text('Pilih Kategori'),
          validator: (value) => value == null ? 'Pilih kategori' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.interTight(),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
