class RecurringBill {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String walletId;
  final int dueDate;
  final String? walletName;

  RecurringBill({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.dueDate,
    this.walletName,
  });

  factory RecurringBill.fromJson(Map<String, dynamic> json) {
    return RecurringBill(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'],
      walletId: json['walletId'],
      dueDate: json['dueDate'],
      walletName: json['wallet']?['name'],
    );
  }
}
