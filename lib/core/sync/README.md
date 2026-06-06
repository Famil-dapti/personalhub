# core/sync — Drift <-> Supabase sync engine

Reconciles the local Drift store with Supabase. The only Supabase caller for wallet data.

- **Public surface:** `SyncService.syncAll()`, `syncServiceProvider`,
  `syncBootstrapProvider` (watch it from the authenticated shell).
- **Push:** drains `SyncOutbox` oldest-first as idempotent upserts (and soft-delete
  updates). Writes the server-returned row back locally to avoid echo loops.
- **Pull:** per table, fetches rows with `updated_at` > stored watermark, upserts into
  Drift, advances the watermark. Tombstones (`deleted_at`) propagate as soft-deletes.
- **Conflict policy:** last-write-wins anchored to the server clock (Postgres
  `set_updated_at` trigger). Stops the push loop on first failure (offline) and retries
  on the next sync.
- **Triggers:** app start (initial sync), connectivity regained (`connectivity_plus`),
  and after every local write (controllers call `syncAll()`).
- **Depends on:** [core/db](../db/README.md), supabase_flutter, connectivity_plus.
