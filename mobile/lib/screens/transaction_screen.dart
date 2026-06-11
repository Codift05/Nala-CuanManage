import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Dummy data for demonstration
  final String currentMonth = 'Juni 2026';
  final double totalIncome = 12500000;
  final double totalExpense = 4350000;
  
  // Example data structure for UI
  final List<Map<String, dynamic>> transactionGroups = [
    {
      'date': 'Hari Ini, 11 Jun 2026',
      'transactions': [
        {
          'title': 'Makan Siang Nasi Padang',
          'category': 'Makanan',
          'account': 'Gopay',
          'amount': -35000,
          'icon': Icons.restaurant,
          'iconColor': Colors.orange,
        },
        {
          'title': 'Isi Saldo Flazz',
          'category': 'Transportasi',
          'account': 'BCA',
          'amount': -100000,
          'icon': Icons.directions_bus,
          'iconColor': Colors.blue,
        },
      ]
    },
    {
      'date': 'Kemarin, 10 Jun 2026',
      'transactions': [
        {
          'title': 'Gaji Bulanan',
          'category': 'Gaji',
          'account': 'BCA',
          'amount': 12500000,
          'icon': Icons.account_balance_wallet,
          'iconColor': Colors.green,
        },
        {
          'title': 'Langganan Internet',
          'category': 'Tagihan',
          'account': 'Kartu Kredit',
          'amount': -350000,
          'icon': Icons.wifi,
          'iconColor': Colors.purple,
        },
        {
          'title': 'Kopi Sore',
          'category': 'Makanan',
          'account': 'Ovo',
          'amount': -45000,
          'icon': Icons.local_cafe,
          'iconColor': Colors.brown,
        },
      ]
    },
  ];

  String _formatCurrency(double amount) {
    // Simple formatter, in a real app use intl package
    final isNegative = amount < 0;
    final absAmount = amount.abs().toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${isNegative ? '- ' : '+ '}Rp $absAmount';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildFilterRow(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = transactionGroups[index];
                  return _buildTransactionGroup(group);
                },
                childCount: transactionGroups.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Padding for FAB
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Transaksi',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  currentMonth,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textSecondary),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: AppTheme.textPrimary, size: 20),
                onPressed: () {
                  // Action to add new transaction manually
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: AppTheme.textPrimary, size: 20),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final balance = totalIncome - totalExpense;
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sisa Saldo',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${balance.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Pemasukan',
                  totalIncome,
                  Icons.arrow_downward,
                  AppTheme.successColor,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[200],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildSummaryItem(
                    'Pengeluaran',
                    totalExpense,
                    Icons.arrow_upward,
                    AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        _buildFilterChip('Semua', true),
        const SizedBox(width: 8),
        _buildFilterChip('Pemasukan', false),
        const SizedBox(width: 8),
        _buildFilterChip('Pengeluaran', false),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTransactionGroup(Map<String, dynamic> group) {
    final date = group['date'] as String;
    final transactions = group['transactions'] as List;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: transactions.asMap().entries.map((entry) {
                final index = entry.key;
                final tx = entry.value;
                final isLast = index == transactions.length - 1;
                return _buildTransactionItem(tx, !isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx, bool showDivider) {
    final amount = (tx['amount'] as num).toDouble();
    final isIncome = amount > 0;
    final iconColor = tx['iconColor'] as Color;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx['icon'] as IconData,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx['account'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(amount),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[100],
            indent: 64,
            endIndent: 16,
          ),
      ],
    );
  }
}
