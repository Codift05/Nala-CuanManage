import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../widgets/load_error_view.dart';
import '../widgets/horizontal_page_route.dart';

PageRouteBuilder<T> addTransactionRoute<T>({
  TransactionItem? transactionToEdit,
  Map<String, dynamic>? transactionDraft,
}) {
  return horizontalPageRoute<T>(
    AddTransactionScreen(
      transactionToEdit: transactionToEdit,
      transactionDraft: transactionDraft,
    ),
  );
}

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
  final Map<String, dynamic>? transactionDraft;

  const AddTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.transactionDraft,
  });

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
  bool _isLoadingWallets = true;
  String? _walletLoadError;

  final List<String> _categories = [
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
    } else if (widget.transactionDraft case final draft?) {
      _type = draft['type'] as String;
      _amountController.text = _rupiahFormatter.formatNumber(
        draft['amount'] as num,
      );
      _selectedWalletId = draft['walletId'] as String;
      _selectedCategory = draft['categoryId'] as String;
      _merchantController.text = draft['merchant'] as String? ?? '';
      _notesController.text = draft['notes'] as String? ?? '';
    }
    final cachedWallets = _walletService.cachedWallets;
    if (cachedWallets != null) {
      _wallets = cachedWallets;
      if (_selectedWalletId == null && cachedWallets.isNotEmpty) {
        _selectedWalletId = cachedWallets.first.id;
      }
      _isLoadingWallets = false;
    } else {
      _loadWallets();
    }
  }

  Future<void> _loadWallets() async {
    setState(() {
      _isLoadingWallets = true;
      _walletLoadError = null;
    });
    try {
      final wallets = await _walletService.getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        if (_selectedWalletId == null && _wallets.isNotEmpty) {
          _selectedWalletId = _wallets.first.id;
        }
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final amount = int.tryParse(
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
              : widget.transactionDraft != null
                  ? 'Tinjau Draft Nala'
                  : 'Tambah Transaksi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingWallets
          ? const Center(child: CircularProgressIndicator())
          : _walletLoadError != null
              ? LoadErrorView(
                  message: _walletLoadError,
                  onRetry: _loadWallets,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTypeSelector(),
                        const SizedBox(height: 16),
                        _buildAmountInput(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEAEDF2)),
                          ),
                          child: Column(
                            children: [
                              _buildWalletSelector(),
                              const SizedBox(height: 16),
                              _buildCategorySelector(),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Merchant / toko',
                                controller: _merchantController,
                                hint: 'Contoh: Indomaret',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                label: 'Catatan',
                                controller: _notesController,
                                hint: 'Opsional',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveTransaction,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    widget.transactionDraft != null
                                        ? 'Konfirmasi & Simpan'
                                        : 'Simpan Transaksi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
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
        backgroundColor: Colors.white,
        thumbColor: const Color(0xFFDFF45B),
        padding: const EdgeInsets.all(4),
        children: {
          'EXPENSE': _buildSegmentLabel(
            'Pengeluaran',
            AppTheme.textPrimary,
          ),
          'INCOME': _buildSegmentLabel(
            'Pemasukan',
            AppTheme.textPrimary,
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
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDF2)),
          ),
          child: TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [_rupiahFormatter],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Nominal',
              hintText: '0',
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary.withValues(alpha: 0.55),
              ),
              fillColor: Colors.transparent,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 58,
                minHeight: 56,
              ),
              prefixIcon: Center(
                widthFactor: 1,
                child: Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // Controlled value changes after the wallets API finishes loading.
          // ignore: deprecated_member_use
          value: _selectedWalletId,
          decoration: const InputDecoration(),
          items: _wallets.map((w) {
            return DropdownMenuItem(
              value: w.id,
              child: Text(w.name, style: TextStyle()),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // Controlled value changes with the income/expense selector.
          // ignore: deprecated_member_use
          value: _selectedCategory,
          decoration: const InputDecoration(),
          items: _categories.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c, style: TextStyle()),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
