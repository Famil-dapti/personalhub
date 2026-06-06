# core/db — Local Drift database (offline-first)

Local source of truth for wallet data. UI reads come from here; writes land here
first (optimistic) and queue an outbox row for the sync engine.

- **Public surface:** `AppDatabase` (reactive `watch*` reads, atomic write+outbox
  helpers, watermark + bulk-upsert for sync), `appDatabaseProvider`, the row->domain
  and JSON->companion mappers in `mappers.dart`.
- **Tables:** `LocalTransactions`, `LocalCategories` (mirrors + `updatedAt`/`deletedAt`),
  `SyncOutbox` (pending mutations), `SyncState` (per-table pull watermark).
- **Cross-platform:** `driftDatabase()` — native via path_provider; web via WASM with
  **relative** URIs (`sqlite3.wasm`, `drift_worker.js` in `web/`) so they resolve under
  the GitHub Pages `/personalhub/` base-href. On Pages storage falls back to IndexedDB
  (no COOP/COEP headers for OPFS).
- **Codegen:** `dart run build_runner build --delete-conflicting-outputs`. The generated
  `app_database.g.dart` is committed (CI does not run build_runner).
- **Depends on:** drift, drift_flutter, sqlite3_flutter_libs, path_provider, uuid.
