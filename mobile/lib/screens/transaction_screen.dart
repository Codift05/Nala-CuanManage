import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalBalance = 0;
  List<Map<String, dynamic>> _transactionGroups = [];
  String _selectedFilter = 'Semua';
  List<TransactionItem> _allTransactions = [];
  List<TransactionItem> _filteredMonthlyTransactions = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactionsFuture = _transactionService.getTransactions();
      final walletsFuture = _walletService.getWallets();
      
      _allTransactions = await transactionsFuture;
      final wallets = await walletsFuture;
      
      setState(() {
        _totalBalance = wallets.fold(
          0.0,
          (total, wallet) => total + wallet.balance,
        );
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('Load transactions error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    _filteredMonthlyTransactions = _allTransactions.where((tx) {
      // Filter by Month and Year
      if (tx.date.month != _selectedMonth.month || tx.date.year != _selectedMonth.year) {
        return false;
      }
      // Filter by Search Query
      if (query.isNotEmpty) {
        final title = (tx.merchant ?? tx.categoryId ?? tx.type).toLowerCase();
        final notes = (tx.notes ?? '').toLowerCase();
        if (!title.contains(query) && !notes.contains(query)) {
          return false;
        }
      }
      // Filter by Type (Semua/Pemasukan/Pengeluaran)
      if (_selectedFilter == 'Pemasukan' && tx.type != 'INCOME') return false;
      if (_selectedFilter == 'Pengeluaran' && tx.type != 'EXPENSE') return false;
      
      return true;
    }).toList();

    double income = 0;
    double expense = 0;

    for (var tx in _filteredMonthlyTransactions) {
      if (tx.type == 'INCOME') {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
    });

    _updateTransactionGroups();
  }

  void _updateTransactionGroups() {
    Map<String, List<TransactionItem>> grouped = {};
    final now = DateTime.now();

    for (var tx in _filteredMonthlyTransactions) {
      String dateStr = _formatDate(tx.date);

      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (txDate == today) {
        dateStr = 'Hari Ini, $dateStr';
      } else if (txDate == yesterday) {
        dateStr = 'Kemarin, $dateStr';
      }

      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(tx);
    }

    List<Map<String, dynamic>> groups = [];
    grouped.forEach((key, value) {
      value.sort((a, b) => b.date.compareTo(a.date));
      groups.add({
        'date': key,
        'transactions': value.map((tx) {
          IconData icon = Icons.receipt_long;
          Color iconColor = Colors.grey;

          if (tx.type == 'INCOME') {
            icon = Icons.account_balance_wallet;
            iconColor = Colors.green;
          } else if (tx.categoryId == 'Food' || tx.categoryId == 'Makanan') {
            icon = Icons.restaurant;
            iconColor = Colors.orange;
          } else if (tx.categoryId == 'Transport' ||
              tx.categoryId == 'Transportasi') {
            icon = Icons.directions_bus;
            iconColor = Colors.blue;
          }

          return {
            'title': tx.merchant ?? tx.categoryId ?? tx.type,
            'category': tx.categoryId ?? 'Lainnya',
            'account': tx.wallet?.name ?? 'Wallet',
            'amount': tx.type == 'EXPENSE' ? -tx.amount : tx.amount,
            'icon': icon,
            'iconColor': iconColor,
            'rawTransaction': tx,
          };
        }).toList(),
      });
    });

    setState(() {
      _transactionGroups = groups;
    });
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    return '${isNegative ? '- ' : '+ '}${_currencyFormat.format(absAmount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadTransactions,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final group = _transactionGroups[index];
                          return _buildTransactionGroup(group);
                        }, childCount: _transactionGroups.length),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80), // Padding for FAB
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_isSearching) {
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                ),
                onChanged: (value) => _applyFilters(),
              ),
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
              icon: const Icon(Icons.close, color: AppTheme.textPrimary, size: 20),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _applyFilters();
              },
            ),
          ),
        ],
      );
    }
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
            GestureDetector(
              onTap: _showMonthPicker,
              child: Row(
                children: [
                  Text(
                    _formatMonthYear(_selectedMonth),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
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
                icon: const Icon(
                  Icons.add,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadTransactions();
                  }
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
                icon: const Icon(
                  Icons.search,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
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
            'Total Saldo',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(_totalBalance),
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
                  _totalIncome,
                  Icons.arrow_downward,
                  AppTheme.successColor,
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey[200]),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildSummaryItem(
                    'Pengeluaran',
                    _totalExpense,
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

  Widget _buildSummaryItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
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
          _currencyFormat.format(amount),
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
        _buildFilterChip('Semua'),
        const SizedBox(width: 8),
        _buildFilterChip('Pemasukan'),
        const SizedBox(width: 8),
        _buildFilterChip('Pengeluaran'),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _applyFilters();
      },
      child: Container(
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
    final rawTx = tx['rawTransaction'] as TransactionItem;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(transactionToEdit: rawTx),
          ),
        );
        if (result == true) {
          _loadTransactions();
        }
      },
      child: Column(
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
                    color: isIncome
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
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
      ),
    );
  }

  void _showMonthPicker() {
    final now = DateTime.now();
    final List<DateTime> months = [];
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i, 1));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Bulan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    final isSelected = month.month == _selectedMonth.month && month.year == _selectedMonth.year;
                    return ListTile(
                      title: Text(
                        _formatMonthYear(month),
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                      onTap: () {
                        setState(() {
                          _selectedMonth = month;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
