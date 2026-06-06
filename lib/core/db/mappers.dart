import 'package:drift/drift.dart';

import '../../features/wallet/data/models/category_model.dart';
import '../../features/wallet/data/models/transaction_model.dart';
import 'app_database.dart';

/// Conversions between Drift rows, domain models, and Supabase JSON.
/// Kept out of the model classes so the models stay storage-agnostic.

// --- Drift row -> domain model (UI) --------------------------------------

Transaction transactionToDomain(LocalTransaction r) => Transaction(
      id: r.id,
      userId: r.userId,
      amount: r.amount,
      createdAt: r.createdAt,
      currency: r.currency,
      categoryId: r.categoryId,
      description: r.description,
      source: r.source,
      notificationId: r.notificationId,
    );

Category categoryToDomain(LocalCategory r) => Category(
      id: r.id,
      userId: r.userId,
      name: r.name,
      kind: r.kind == 'income' ? CategoryKind.income : CategoryKind.expense,
      icon: r.icon,
      color: r.color,
      sortOrder: r.sortOrder,
    );

// --- Supabase JSON -> Drift companion (delta pull / push echo) ------------

LocalTransactionsCompanion transactionCompanionFromRemote(
    Map<String, dynamic> j) {
  return LocalTransactionsCompanion(
    id: Value(j['id'] as String),
    userId: Value(j['user_id'] as String),
    amount: Value((j['amount'] as num).toDouble()),
    currency: Value((j['currency'] as String?) ?? 'AZN'),
    categoryId: Value(j['category_id'] as String?),
    description: Value(j['description'] as String?),
    source: Value((j['source'] as String?) ?? 'manual'),
    notificationId: Value(j['notification_id'] as String?),
    createdAt: Value(DateTime.parse(j['created_at'] as String)),
    updatedAt: Value(DateTime.parse(j['updated_at'] as String)),
    deletedAt: Value(_parseNullableDate(j['deleted_at'])),
  );
}

LocalCategoriesCompanion categoryCompanionFromRemote(Map<String, dynamic> j) {
  return LocalCategoriesCompanion(
    id: Value(j['id'] as String),
    userId: Value(j['user_id'] as String?),
    name: Value(j['name'] as String),
    kind: Value(j['kind'] as String),
    icon: Value(j['icon'] as String?),
    color: Value(j['color'] as String?),
    sortOrder: Value((j['sort_order'] as int?) ?? 0),
    createdAt: Value(DateTime.parse(j['created_at'] as String)),
    updatedAt: Value(DateTime.parse(j['updated_at'] as String)),
    deletedAt: Value(_parseNullableDate(j['deleted_at'])),
  );
}

DateTime? _parseNullableDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
