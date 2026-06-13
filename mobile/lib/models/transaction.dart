class TransactionItem {
  final String id;
  final String walletId;
  final String type; // INCOME, EXPENSE
  final double amount;
  final String? categoryId;
  final String? merchant;
  final String? notes;
  final DateTime date;
  final WalletInfo? wallet; // From include: { wallet: true }

  TransactionItem({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.categoryId,
    this.merchant,
    this.notes,
    required this.date,
    this.wallet,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'],
      walletId: json['walletId'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'],
      merchant: json['merchant'],
      notes: json['notes'],
      date: DateTime.parse(json['date']),
      wallet: json['wallet'] != null ? WalletInfo.fromJson(json['wallet']) : null,
    );
  }
}

class WalletInfo {
  final String name;
  final String type;

  WalletInfo({required this.name, required this.type});

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      name: json['name'],
      type: json['type'],
    );
  }
}
