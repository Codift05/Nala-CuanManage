import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';

class ScanScreen extends StatefulWidget {
  final Map<String, dynamic>? initialDraft;

  const ScanScreen({super.key, this.initialDraft});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  static const _maxReceiptBytes = 1400000;

  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  bool _isSaving = false;
  bool _isLoadingWallets = true;
  String? _walletLoadError;
  Map<String, dynamic>? _scannedData;
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Shopping';

  final List<String> _categories = [
    'Shopping',
    'Food',
    'Transport',
    'Bills',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft case final draft?) _applyScannedData(draft);
    final cachedWallets = _walletService.cachedWallets;
    if (cachedWallets != null) {
      _wallets = cachedWallets;
      if (cachedWallets.isNotEmpty) _selectedWallet = cachedWallets.first;
      _isLoadingWallets = false;
    } else {
      _loadWallets();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyScannedData(Map<String, dynamic> result) {
    _scannedData = result;
    _amountController.text = (result['amount'] ?? 0).toString();
    _merchantController.text = result['merchant'] ?? '';
    _notesController.text = result['notes'] ?? '';
    final category = result['categoryId'];
    _selectedCategory = category is String && _categories.contains(category)
        ? category
        : 'Others';
    _isProcessing = false;
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
        if (wallets.isNotEmpty) _selectedWallet = wallets.first;
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

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _scannedData = null;
      });

      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > _maxReceiptBytes) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto struk terlalu besar. Ambil foto lebih dekat.'),
          ),
        );
        return;
      }
      final base64Image = await compute(base64Encode, bytes);

      final result = await _transactionService.scanReceipt(base64Image);

      if (!mounted) return;

      if (result != null) {
        setState(() => _applyScannedData(result));
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membaca struk. Coba lagi.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk belum dapat diproses. Coba lagi.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveTransaction() async {
    final amount = int.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari Rp 0')),
      );
      return;
    }
    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sumber dana terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _transactionService.createTransaction(
        walletId: _selectedWallet!.id,
        type: 'EXPENSE', // Usually receipts are expenses
        amount: amount,
        categoryId: _selectedCategory,
        merchant: _merchantController.text,
        notes: _notesController.text,
      );

      if (!mounted) return;

      if (result != null) {
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
              content: Text('Transaksi Berhasil Disimpan!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan transaksi!'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text('Transaksi belum dapat disimpan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Scan Struk',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: _scannedData != null ? _buildResultForm() : _buildScannerView(),
      ),
    );
  }

  Widget _buildScannerView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Catat dari struk',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ambil foto yang jelas. NALA akan menyiapkan draft untuk kamu periksa.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAEDF2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isProcessing
                      ? const CircularProgressIndicator(
                          color: AppTheme.primaryColor)
                      : Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0DA),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            size: 38,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                  const SizedBox(height: 20),
                  Text(
                    _isProcessing
                        ? 'Menganalisis struk dengan AI...'
                        : 'Pilih sumber struk',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isProcessing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOptionBtn(
                          Icons.camera_alt,
                          'Kamera',
                          () => _pickAndScanImage(ImageSource.camera),
                        ),
                        const SizedBox(width: 12),
                        _buildOptionBtn(
                          Icons.photo_library,
                          'Galeri',
                          () => _pickAndScanImage(ImageSource.gallery),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 116,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAEDF2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textPrimary, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Draft struk siap',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Periksa kembali data di bawah ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReviewNotice(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEAEDF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  'Nominal (Rp)',
                  _amountController,
                  confidenceField: 'amount',
                  isNumber: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Merchant',
                  _merchantController,
                  confidenceField: 'merchant',
                ),
                const SizedBox(height: 16),
                _buildTextField('Catatan', _notesController),
                const SizedBox(height: 16),
                Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: _inputDecoration(),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                _buildConfidenceLabel('categoryId'),
                const SizedBox(height: 16),
                Text(
                  'Sumber Dana',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWalletField(),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _scannedData = null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Scan Ulang',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ||
                          _isLoadingWallets ||
                          _walletLoadError != null ||
                          _selectedWallet == null
                      ? null
                      : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Simpan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletField() {
    if (_isLoadingWallets) {
      return InputDecorator(
        decoration: _inputDecoration(),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Memuat sumber dana...'),
          ],
        ),
      );
    }
    if (_walletLoadError != null) {
      return InputDecorator(
        decoration: _inputDecoration(),
        child: Row(
          children: [
            Expanded(child: Text(_walletLoadError!)),
            TextButton(onPressed: _loadWallets, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (_wallets.isEmpty) {
      return InputDecorator(
        decoration: _inputDecoration(),
        child: const Text('Belum ada sumber dana'),
      );
    }
    return DropdownButtonFormField<Wallet>(
      initialValue: _selectedWallet,
      decoration: _inputDecoration(),
      items: _wallets
          .map((wallet) => DropdownMenuItem(
                value: wallet,
                child: Text(wallet.name),
              ))
          .toList(),
      onChanged: (wallet) => setState(() => _selectedWallet = wallet),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? confidenceField,
    bool isNumber = false,
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
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: _inputDecoration(),
        ),
        if (confidenceField != null) _buildConfidenceLabel(confidenceField),
      ],
    );
  }

  Widget _buildReviewNotice() {
    final fields = (_scannedData?['reviewRequired'] as List<dynamic>? ?? [])
        .map((field) => switch (field) {
              'amount' => 'nominal',
              'merchant' => 'merchant',
              'categoryId' => 'kategori',
              _ => null,
            })
        .whereType<String>()
        .toList();
    final needsReview = fields.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: needsReview ? const Color(0xFFFFF4E5) : const Color(0xFFEAF8F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        needsReview
            ? 'AI kurang yakin pada ${fields.join(', ')}. Periksa sebelum menyimpan.'
            : 'Semua field terbaca jelas. Tetap periksa sebelum menyimpan.',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildConfidenceLabel(String field) {
    final confidence = _scannedData?['confidence'];
    final score = confidence is Map<String, dynamic> ? confidence[field] : null;
    if (score is! num) return const SizedBox.shrink();
    final percentage = (score * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Estimasi keyakinan AI $percentage%',
        style: TextStyle(
          color: score < 0.8 ? AppTheme.warningColor : AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}
