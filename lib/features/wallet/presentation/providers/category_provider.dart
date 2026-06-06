import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/database_provider.dart';
import '../../../../core/db/mappers.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../data/models/category_model.dart';

// Reactive category list from the local Drift store. Includes system presets
// (userId null) pulled from Supabase plus the user's own categories.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCategories().map(
        (rows) => rows.map(categoryToDomain).toList(),
      );
});

final categoriesControllerProvider = Provider<CategoriesController>((ref) {
  return CategoriesController(ref);
});

class CategoriesController {
  CategoriesController(this._ref);

  final Ref _ref;
  static const _uuid = Uuid();

  Future<String?> add(Category c) async {
    try {
      final userId = _ref.read(supabaseClientProvider).auth.currentUser!.id;
      final id = _uuid.v4();
      final now = DateTime.now();
      final row = LocalCategoriesCompanion.insert(
        id: id,
        name: c.name,
        kind: c.kind.name,
        createdAt: now,
        updatedAt: now,
        userId: Value(userId),
        icon: Value(c.icon),
        color: Value(c.color),
        sortOrder: Value(c.sortOrder),
      );
      final payload = {
        'id': id,
        'user_id': userId,
        'name': c.name,
        'kind': c.kind.name,
        'icon': c.icon,
        'color': c.color,
        'sort_order': c.sortOrder,
        'created_at': now.toIso8601String(),
      };
      await _ref.read(appDatabaseProvider).enqueueUpsertCategory(row, payload);
      _ref.read(syncServiceProvider).syncAll();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String?> remove(String id) async {
    try {
      await _ref.read(appDatabaseProvider).enqueueDeleteCategory(id);
      _ref.read(syncServiceProvider).syncAll();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }
}

// Quick id -> Category lookup for rendering transaction tiles.
final categoryMapProvider = Provider<Map<String, Category>>((ref) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
  return {for (final c in categories) c.id: c};
});
