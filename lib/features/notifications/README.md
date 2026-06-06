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

## Phase 4 — Wallet integration
- `domain/` parser (`notification_parser`, `package_templates`, `diacritics`,
  `parsed_transaction`): device-side, free, offline. Routes by app package, then
  a generic regex extracts amount/currency/direction (date-noise stripped,
  diacritics folded). It is the single transaction detector (sets `isTransaction`).
- `data/groq_client.dart` + `presentation/providers/extractor_provider.dart`:
  AI fallback. The extractor runs regex first and only calls Groq when regex
  misses AND the account set a key (see the `settings` feature). Lazy — on the
  "Cuzdana ekle" tap, not per-notification.
- "Cuzdana ekle" opens the pre-filled, editable AddTransactionScreen; saving
  links `notification_id` and sets `source='notification'`.
- SMS auto-route: in `ingest`, an SMS-app notification whose body has an `NN.NN`
  amount becomes a cancelable `pending` transaction draft (native-capture path
  only, idempotent via `transactionExistsForNotification`).

## Still pending
- Foreground service for capture hardening on aggressive-OEM (MIUI) battery killers.
- Per-package bank templates are scaffolded but defer to the generic parser
  until real on-device notification samples are captured.
