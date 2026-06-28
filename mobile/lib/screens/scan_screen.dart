import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _scannedData;
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Belanja';

  final List<String> _categories = [
    'Belanja',
    'Food',
    'Transport',
    'Bills',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.getWallets();
    if (mounted) {
      setState(() {
        _wallets = wallets;
        if (wallets.isNotEmpty) _selectedWallet = wallets.first;
      });
    }
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _scannedData = null;
      });

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await _transactionService.scanReceipt(base64Image);

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _scannedData = result;
          _amountController.text = (result['amount'] ?? 0).toString();
          _merchantController.text = result['merchant'] ?? '';
          _notesController.text = result['notes'] ?? '';

          String cat = result['categoryId'] ?? 'Belanja';
          if (!_categories.contains(cat)) {
            cat = 'Others';
          }
          _selectedCategory = cat;
          _isProcessing = false;
        });
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveTransaction() async {
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
        amount: double.tryParse(_amountController.text) ?? 0,
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
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Scan Struk',
          style: GoogleFonts.interTight(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _scannedData != null ? _buildResultForm() : _buildScannerView(),
      ),
    );
  }

  Widget _buildScannerView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isProcessing
              ? const CircularProgressIndicator(color: AppTheme.primaryColor)
              : Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 32),
          Text(
            _isProcessing
                ? 'Menganalisis struk dengan AI...'
                : 'Pilih metode input struk',
            style: GoogleFonts.interTight(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 48),
          if (!_isProcessing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOptionBtn(
                  Icons.camera_alt,
                  'Kamera',
                  () => _pickAndScanImage(ImageSource.camera),
                ),
                const SizedBox(width: 32),
                _buildOptionBtn(
                  Icons.photo_library,
                  'Galeri',
                  () => _pickAndScanImage(ImageSource.gallery),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOptionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultForm() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Struk Terdeteksi',
                        style: GoogleFonts.interTight(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Periksa kembali data di bawah ini',
                        style: GoogleFonts.interTight(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildTextField('Nominal (Rp)', _amountController, isNumber: true),
            const SizedBox(height: 16),
            _buildTextField('Merchant', _merchantController),
            const SizedBox(height: 16),
            _buildTextField('Catatan', _notesController),
            const SizedBox(height: 16),
            Text(
              'Kategori',
              style: GoogleFonts.interTight(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: _inputDecoration(),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),
            Text(
              'Sumber Dana',
              style: GoogleFonts.interTight(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Wallet>(
              value: _selectedWallet,
              decoration: _inputDecoration(),
              items: _wallets
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWallet = v),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Scan Ulang',
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
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
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.interTight(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: _inputDecoration(),
        ),
      ],
    );
  }
}
