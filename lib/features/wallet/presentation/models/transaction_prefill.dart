import '../../data/models/category_model.dart';

/// Seed values passed to [AddTransactionScreen] via go_router `extra` when a
/// transaction is created from a notification. The form stays fully editable.
/// When [existingTransactionId] is set, saving COMMITS that pending draft
/// (upsert by id, pending -> false) instead of inserting a new row.
class TransactionPrefill {
  const TransactionPrefill({
    this.amountMagnitude,
    this.kind,
    this.description,
    this.notificationId,
    this.existingTransactionId,
  });

  final double? amountMagnitude;
  final CategoryKind? kind;
  final String? description;
  final String? notificationId;
  final String? existingTransactionId;
}
