class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['categoryId'],
      amount: (json['amount'] as num).toDouble(),
      month: json['month'],
      year: json['year'],
    );
  }
}
