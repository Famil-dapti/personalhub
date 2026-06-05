import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    return ref.read(categoryRepositoryProvider).fetchAll();
  }

  Future<String?> addCategory(Category category) async {
    try {
      await ref.read(categoryRepositoryProvider).create(category);
      ref.invalidateSelf();
      await future;
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String?> removeCategory(String id) async {
    try {
      await ref.read(categoryRepositoryProvider).delete(id);
      ref.invalidateSelf();
      await future;
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
