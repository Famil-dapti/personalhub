import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';

class CategoryRepository {
  const CategoryRepository(this._client);

  final SupabaseClient _client;

  // Returns system presets + the user's own categories (RLS enforces visibility).
  Future<List<Category>> fetchAll() async {
    final rows = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return rows.map<Category>((r) => Category.fromJson(r)).toList();
  }

  Future<Category> create(Category category) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('categories')
        .insert(category.toInsert(userId))
        .select()
        .single();
    return Category.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
