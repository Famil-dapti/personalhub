# notifications — Notification Archiver (Phase 2)

Browse archived Android notifications. Capture is Android-only; every other
client (web/desktop/iOS) is a read-only archive.

## Public surface
- `NotificationsScreen` — responsive: phone list (tap → pushed detail) or
  desktop/web master-detail (read-only, with capture-runs-on-phone banner).
- `NotificationDetailScreen` — pushed phone detail (full title/body, detected-
  transaction card, raw payload).
- `notificationsProvider` (stream from Drift), `filteredNotificationsProvider`
  (search + chip filter), `notificationsControllerProvider.ingest()` — the
  write entry point the Android capture channel will call (Phase 2B).

## Data flow
Offline-first, lightweight: notifications are immutable/append-only, so there
is no edit/delete/conflict machinery. Capture writes to Drift + the sync
outbox (`ingest`), sync pushes upserts to Supabase, and all clients delta-pull
by the `created_at` watermark. UI streams from Drift only.

## Dependencies
`core/db` (Drift + outbox), `core/sync`, `core/supabase`, `core/widgets`,
`core/utils/formatters`, Riverpod, go_router.

## Phase 2B — native capture (built & device-verified)
- `NotificationArchiverService` (Kotlin) captures every posted notification to a
  SharedPreferences buffer (works while the app is closed).
- MethodChannel `personalhub/notifications`: isPermissionGranted / openSettings /
  drainPending. Dart `NotificationCaptureService` wraps it (no-op off-Android).
- `NotificationCaptureController.drainAndIngest()` drains the buffer on app
  open/resume and feeds each through `ingest()` (Drift + outbox + sync).
- `PermissionScreen` deep-links to system "Notification access" settings.

## Still pending
- Foreground service for capture hardening on aggressive-OEM (MIUI) battery killers.
- Per-device attribution (two phones / one account) — before Phase 3 (see Project-state backlog).
- Wallet link ("Cuzdana ekle" / amount+category parsing) is Phase 4.
