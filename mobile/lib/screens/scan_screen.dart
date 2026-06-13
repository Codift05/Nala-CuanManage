import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String selectedSource = 'Tunai';
  bool _isSaving = false;
  
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  Future<void> _saveTransaction() async {
    setState(() => _isSaving = true);
    try {
      final wallets = await _walletService.getWallets();
      if (wallets.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada wallet ditemukan!')));
        setState(() => _isSaving = false);
        return;
      }
      
      final walletId = wallets.first.id; // Using the first wallet available for dummy integration
      
      final result = await _transactionService.createTransaction(
        walletId: walletId,
        type: 'EXPENSE',
        amount: 47500,
        categoryId: 'Belanja', 
        merchant: 'Indomaret Manado',
        notes: 'Hasil Scan Otomatis',
      );
      
      if (!mounted) return;
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Transaksi Berhasil Disimpan!'),
          backgroundColor: AppTheme.successColor,
        ));
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan transaksi!'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background for camera
      body: SafeArea(
        child: Stack(
          children: [
            // Fake Camera Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF121212),
                      const Color(0xFF2C2C2C).withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            
            // Scan Frame Overlay
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 200.0), // Shift up to avoid bottom sheet
                child: _buildScanFrame(),
              ),
            ),

            // Top Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Scan Struk',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_off, color: Colors.white, size: 24),
                    onPressed: () {
                      // Toggle flash
                    },
                  ),
                ],
              ),
            ),

            // Bottom Sheet Modal
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomSheet(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return Container(
      width: 280,
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1954C2).withValues(alpha: 0.8), // Blue frame
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Simulated scanning line
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF1954C2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1954C2).withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Success Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF1954C2), size: 24),
            ),
            const SizedBox(height: 16),
            
            // Status Text
            Text(
              'Struk Terdeteksi!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Indomaret Manado',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Divider
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 24),
            
            // Amount
            Text(
              'Rp 47.500',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1954C2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 16, color: Color(0xFF1954C2)),
                  const SizedBox(width: 8),
                  Text(
                    'Belanja',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1954C2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF1954C2)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Source of Funds
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sumber Dana',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppTheme.textPrimary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedSource,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Notes
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Catatan (Opsional)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF1954C2)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1954C2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Ulangi Scan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1954C2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1954C2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Simpan Transaksi',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.check, color: Colors.white, size: 16),
                          ],
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
}
