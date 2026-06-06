import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import '../supabase/supabase_service.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(appDatabaseProvider),
    ref.watch(supabaseClientProvider),
  );
});

/// Bootstraps background sync for the session: an initial push/pull plus a
/// re-sync whenever connectivity is regained. Watch it from the authenticated
/// shell so it stays alive while the user is signed in.
final syncBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(syncServiceProvider);

  service.syncAll(); // initial sync once the session is up

  final sub = Connectivity().onConnectivityChanged.listen((results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online) service.syncAll();
  });
  ref.onDispose(sub.cancel);
});
