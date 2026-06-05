class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.createdAt,
    this.currency = 'AZN',
    this.categoryId,
    this.description,
    this.source = 'manual',
    this.notificationId,
  });

  final String id;
  final String userId;
  final double amount; // positive = income, negative = expense
  final DateTime createdAt;
  final String currency;
  final String? categoryId;
  final String? description;
  final String source; // 'manual' | 'notification'
  final String? notificationId;

  bool get isIncome => amount >= 0;
  bool get isExpense => amount < 0;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      currency: (json['currency'] as String?) ?? 'AZN',
      categoryId: json['category_id'] as String?,
      description: json['description'] as String?,
      source: (json['source'] as String?) ?? 'manual',
      notificationId: json['notification_id'] as String?,
    );
  }

  // Insert payload. Omits id (DB default) and lets RLS bind user_id.
  // created_at is sent explicitly so a user-picked date is preserved.
  Map<String, dynamic> toInsert(String userId) {
    return {
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'category_id': categoryId,
      'description': description,
      'source': source,
      'notification_id': notificationId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
