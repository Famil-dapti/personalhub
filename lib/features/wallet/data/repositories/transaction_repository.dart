import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';

class TransactionRepository {
  const TransactionRepository(this._client);

  final SupabaseClient _client;

  Future<List<Transaction>> fetchAll() async {
    final rows = await _client
        .from('transactions')
        .select()
        .order('created_at', ascending: false);
    return rows.map<Transaction>((r) => Transaction.fromJson(r)).toList();
  }

  Future<Transaction> create(Transaction transaction) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('transactions')
        .insert(transaction.toInsert(userId))
        .select()
        .single();
    return Transaction.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }
}
