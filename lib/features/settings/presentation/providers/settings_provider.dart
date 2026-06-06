import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/db/database_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/sync/sync_providers.dart';

/// The signed-in user's Groq API key (null/empty = AI fallback disabled).
/// Streamed from the synced Drift store so all devices see the same value.
final groqApiKeyProvider = StreamProvider<String?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchUserSettings().map((row) => row?.groqApiKey);
});

final settingsControllerProvider =
    Provider<SettingsController>((ref) => SettingsController(ref));

/// Writes per-user settings to Drift + the sync outbox (offline-first), then
/// kicks a background sync. The settings row id is the user's own id so both
/// phones converge on a single row (no duplicate-row conflict on push).
class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  Future<String?> setGroqKey(String? key) async {
    try {
      final userId = _ref.read(supabaseClientProvider).auth.currentUser!.id;
      final normalized = (key == null || key.trim().isEmpty) ? null : key.trim();
      final row = LocalUserSettingsCompanion(
        id: Value(userId),
        userId: Value(userId),
        groqApiKey: Value(normalized),
        updatedAt: Value(DateTime.now()),
      );
      final payload = {
        'id': userId,
        'user_id': userId,
        'groq_api_key': normalized,
      };
      await _ref
          .read(appDatabaseProvider)
          .enqueueUpsertUserSettings(row, payload);
      _ref.read(syncServiceProvider).syncAll();
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String?> clearGroqKey() => setGroqKey(null);
}
