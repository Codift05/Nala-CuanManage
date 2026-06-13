class Wallet {
  final String id;
  final String name;
  final String type;
  final double balance;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
    };
  }
}
