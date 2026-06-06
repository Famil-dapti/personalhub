# Project-state.md

## Current Phase
**Phase 3 — Media Cleaner** ✅ **CODE COMPLETE (2026-06-06; on-device verify deferred).** Swipe-review
of device photos + videos. See the Phase 3 section below for the full breakdown. Drift schemaVersion is
now **4**. Supabase migration for the new `media_stats` table is written but **NOT yet deployed**.

**Phase 2 — Notification Archiver** ✅ Phase 2A (UI/data) MERGED+LIVE; **Phase 2B (native capture)
CODE COMPLETE + VERIFIED ON DEVICE** (uncommitted on `dev`). Captured notifications flow:
Kotlin NotificationListenerService -> local buffer -> Dart drain on app open -> ingest (Drift +
outbox) -> Supabase -> web. Confirmed working on a real Xiaomi phone (2026-06-06).

Also fixed this session: **missing `INTERNET` permission in the main AndroidManifest** (release
APKs couldn't reach Supabase — DNS errno 7; debug/profile manifests had it so only release broke).

Remaining deferred (user decision): **Phase 1.2 offline E2E test** + **design implementation**
(mockups in docs/design/personalhub/).

**Pre-Phase-3 fixes (2026-06-06, user request):**
1. **Duplicate-notification bug FIXED.** Android re-delivered the same notification (heads-up then
   collapse-to-bar) and group summaries, so each was archived twice. Two-layer dedup now:
   (a) native — `NotificationArchiverService` skips `FLAG_GROUP_SUMMARY` and drops repeats by a
   bounded in-memory `key|postTime` signature set; (b) Dart ingest — `NotificationsController.ingest`
   skips when an identical row (postedAt + appPackage + title + body) already exists in Drift
   (`AppDatabase.notificationExistsLike`), covering service-restart/buffer edges. CODE COMPLETE;
   on-device re-verify pending (deferred with the rest of Android testing).
2. **"Clear all notifications" button ADDED.** Bildirimler AppBar → delete-sweep action (shown only
   when the archive is non-empty) → confirm dialog → `NotificationsController.clearAll`:
   remote-first hard delete from Supabase (`SyncService.purgeNotifications`, frees DB space) then
   local wipe + notification-outbox purge (`AppDatabase.clearAllNotificationsLocal`). Remote-first so
   an offline failure leaves both stores intact and is retryable. Note: no tombstones, so a second
   device keeps its local copies until it also clears (server space is freed regardless).
   `flutter analyze` clean; tests pass.

**Pre-Phase-3 requirement (NEW, user 2026-06-06):** the same app runs on TWO phones under one
account, so notifications must carry **per-device attribution** (which phone captured each one) and
the archive should let you tell/filter by device. ✅ **DONE 2026-06-06** (CODE COMPLETE; on-device
re-verify deferred with the rest of Android testing):
- Migration `20260606120000_notification_device_attribution.sql` adds `device_id` + `device_name`
  to `notifications` (additive/idempotent; existing rows NULL).
- Drift mirror: `LocalNotifications.deviceId/deviceName`; schemaVersion 2→3 + onUpgrade addColumn
  (v1 installs get the table fresh; only v2 needs the columns added). `app_database.g.dart` regen'd.
- `deviceIdentityProvider` (capture_providers): stable per-install uuid persisted in
  shared_preferences + human-readable model name read natively (`Build.MANUFACTURER + Build.MODEL`
  via the existing MethodChannel `getDeviceModel`). Stamped at ingest in `NotificationCaptureController`
  (drain runs in-app on the capturing phone). dedup is now device-scoped so a copy synced from the
  other phone is never mistaken for a local duplicate.
  - **Toolchain note:** initially tried `device_info_plus`, but it transitively pulls `win32`, whose
    Dart 3.12 dot-shorthand syntax crashes the old bundled analyzer during drift codegen
    (`visitDotShorthandInvocation`) and hangs/fails build_runner. Solution: read the model natively
    (no extra dep) + a new `build.yaml` disabling the unused `riverpod_generator` builder. drift
    runtime/sqlite3 versions unchanged (web wasm still matches).
- UI: AppBar device-filter popup (shown only with 2+ devices), device label on cards (2+ devices)
  + always in the detail pane.

**Phase 1.2 — Offline queue (Drift)** ✅ CODE COMPLETE, COMMITTED, MERGED TO MAIN, DEPLOYED LIVE.
Partially verified (launch + production wasm serving). Authenticated offline E2E (add -> persist ->
sync) NOT yet runtime-verified — deferred to on-device (Android phone) test.

## Phase 3 — Media Cleaner (2026-06-06, CODE COMPLETE; on-device verify deferred)

Swipe-review device media to keep or delete. **Android/mobile-only**; web is a read-only stats view
(no device file access). On-device verification is deferred to the **same parked Android test session**
as the notification re-verify + Phase 1.2 offline E2E.

**Decisions locked with the user:**
- **Scope:** photos + videos, with a Tumu/Foto/Video filter.
- **Swipe (flutter_card_swiper, 4-way):** Left=Delete, Right=Keep, Up=Favorite/Protect, Down=Later
  (defer) — plus mirror action buttons + Undo (Geri al).
- **Decisions are LOCAL-ONLY (Drift)**, keyed by `assetId + deviceId`, so a reviewed item is never
  re-shown. Individual decision rows are **NEVER synced**.
- **Only per-device AGGREGATE stats sync** to Supabase (new `media_stats` table): total / decided /
  kept / deleted, shown on phones AND web (read-only). Reuses `deviceIdentityProvider` for attribution.
- **Rich filter/sort over a LOCAL media index:** type, album/folder, date (newest/oldest), size
  (largest first), screenshots-only, random; "undecided only" is the default queue.
- **Indexing:** first-launch FULL scan + per-launch DELTA (new/removed). Background WorkManager
  ("index while app closed") was **DEFERRED** — unreliable on the user's Xiaomi/MIUI (battery kill);
  the on-launch delta covers the need.
- **Deletion:** pending-delete queue -> batch confirm screen -> OS MediaStore trash dialog via
  `PhotoManager.editor.deleteWithIds`; deleted assets drop from the index but the local decision row
  persists (so cumulative deleted stats survive).

**What was built:**
- `features/media_cleaner/data/models/media_models.dart` — MediaAsset, MediaStats, enums.
- `features/media_cleaner/data/media_scanner.dart` + `media_scanner_io.dart` + `media_scanner_web.dart`
  — conditional import; `photo_manager` is isolated from the web build via `if (dart.library.io)`.
- `features/media_cleaner/domain/media_filter.dart` — pure filter/sort engine.
- `features/media_cleaner/presentation/providers/media_providers.dart` — deck, filters, stats, index
  controller, `MediaCleanerController`.
- `features/media_cleaner/presentation/screens/media_cleaner_screen.dart` (rewritten) +
  `media_delete_confirm_screen.dart`.
- `features/media_cleaner/presentation/widgets/` — media_card.dart, media_stats_panel.dart,
  media_filter_sheet.dart, format_bytes.dart.
- **Drift:** tables LocalMediaAssets, LocalMediaDecisions, LocalMediaStats added; **schemaVersion 3->4**
  + onUpgrade creates the 3 tables (`core/db/tables.dart`, `app_database.dart`). Mappers + sync wired
  (`kMediaStatsTable` pulled by `updated_at`). New route `/media/delete`.
- **Android manifest:** READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, ACCESS_MEDIA_LOCATION,
  READ_EXTERNAL_STORAGE (maxSdk 32).
- **pubspec:** `photo_manager ^3.9.0`, `flutter_card_swiper ^7.2.0` (drift/sqlite3 versions UNCHANGED —
  web wasm still matches).
- **Supabase migration:** `supabase/migrations/20260607090000_media_stats.sql` (media_stats table + RLS
  + set_updated_at trigger). ⛔ **NOT yet applied to remote — pending deploy.**

**Future note:** connect to Google Photos accounts later so the app can also review/act on cloud photos
(recorded in Project-plan.md as a future phase).

## Status
Phase 1.1 built, merged to main, and DEPLOYED. Web app live at
**https://famil-dapti.github.io/personalhub/** (GitHub Pages, auto-deploy on push to main).
Repo is PUBLIC (required for free Pages; secret scan clean). Migration for categories deployed
to Supabase. User created a login account and confirmed the app works end-to-end.
Supabase MCP in `.mcp.json` + authenticated; tools load on next IDE session restart.
Custom domain DEFERRED — staying on github.io URL for now; will migrate host later for a nicer name.

## Completed
- [x] Architecture decision: Flutter + Supabase + Riverpod + go_router
- [x] Project documentation: CLAUDE.md, Project-plan.md, docs/
- [x] Flutter 3.44.1 installed at /Users/familmammadov/development/flutter/
- [x] Flutter project scaffolded: `personalhub` (Android + Web targets)
- [x] Dependencies: supabase_flutter, flutter_riverpod, riverpod_annotation, go_router, google_fonts, fl_chart, intl, uuid, shared_preferences
- [x] Core: AppConfig (Supabase credentials filled), AppTheme (Material 3, Inter font), AppRouter (go_router, auth redirect guard), AppShell (3-tab bottom nav)
- [x] Supabase providers: supabaseClientProvider, authStateProvider, currentUserProvider
- [x] Auth feature: AuthRepository, AuthActions, LoginScreen, SignupScreen
- [x] Shell: Wallet / Notifications / Media tabs with placeholder screens
- [x] flutter analyze → No issues found
- [x] Git repo initialized: github.com/Famil-dapti/personalhub
- [x] Branches: main (production), dev (active development — always work here)
- [x] CI/CD: GitHub Actions deploy on push to dev or main (paths: supabase/migrations/**)
- [x] GitHub secrets set: SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_ID, SUPABASE_DB_PASSWORD
- [x] Supabase CLI installed (v2.105.0), supabase init done
- [x] Initial migration written: supabase/migrations/20260605213540_initial_schema.sql
- [x] First migration verified: tables created in Supabase via native GitHub integration
- [x] Phase 1.1 Wallet: models, repositories, providers, screens (wallet/add/categories/dashboard), fl_chart
- [x] categories migration `20260606022924_categories.sql` deployed (Turkish presets + category_id FK)
- [x] intl tr_TR locale init; all wallet UI in Turkish
- [x] Merged dev -> main; repo made PUBLIC (secret scan clean)
- [x] Web deploy CI: `.github/workflows/deploy-web.yml` (build web + GitHub Pages on push to main)
- [x] Live: https://famil-dapti.github.io/personalhub/ (verified HTTP 200); login account created

## In Progress
**Phase 2A complete on `dev` (uncommitted).** Notification Archiver data layer + archive UI built.
Three on-device/visual threads parked for one combined session:
1. **Phase 2B native capture** — Kotlin NotificationListenerService + foreground service +
   platform channel → `NotificationsController.ingest()`; phone permission flow.
2. **Phase 1.2 on-device test** — offline add/delete + reconnect sync.
3. **Design implementation** — Claude Design mockups (`docs/design/personalhub/`).

### Phase 2A — what was built (2026-06-06)
- **Decision: lightweight sync, not full offline-first.** Notifications are immutable/append-only,
  so no edit/delete/LWW/tombstone machinery (unlike wallet). Capture → Drift + outbox → Supabase
  upsert; clients delta-pull by `created_at` watermark.
- **No server migration needed** — `notifications` table + RLS already exist (initial_schema).
  Only the Drift mirror was added: `LocalNotifications` table, schemaVersion 1→2 + `onUpgrade`
  migration (creates the new table for existing web/IndexedDB installs).
- `core/db`: LocalNotifications table, watch/upsert/enqueueUpsert helpers, mappers (raw_json jsonb
  re-encoded to string). `core/sync`: `_pullTable` generalized with a `watermarkColumn` param;
  notifications pulled by `created_at`. `core/utils/formatters`: `formatRelativeTime` + `formatTime`.
- Feature `features/notifications/`: NotificationItem model; providers (stream + search/filter/
  selected + `NotificationsController.ingest` = the Phase 2B capture write entry point); responsive
  screen (phone list w/ pushed detail + desktop/web master-detail); widgets (card+badge, search,
  filter chips, detected-transaction card, raw payload, capture banner, brand avatar).
- Route added: `/notifications/detail`. `flutter analyze` clean; `flutter build web` OK; tests pass.
- **Wallet↔notification link stays Phase 4** (per user): "Cuzdana ekle" shows a "coming later"
  toast; `is_transaction` badge renders but no amount/category parsing yet.

## Next Task — new session (two tracks)

**Track A — UX/UI polish (wallet)** ✅ DONE (2026-06-06)
- New shared primitives: `core/widgets/{app_spacing,app_feedback,skeleton,empty_state}.dart`
- Date-grouped transaction list (Bugun/Dun/date headers) + swipe-to-delete (Dismissible)
- Loading skeletons on wallet/categories/dashboard; friendly empty states everywhere
- Success/error snackbars on add/delete (transaction + category)
- Category delete confirmation dialog; add-category live preview chip + drag handle
- Bar-chart income/expense legend; spacing tokens replace magic numbers
- Theme already had light+dark; new widgets are all colorScheme-driven (dark-safe)

**Design handoff (in progress)**
- `docs/design/claude-design-brief.md` — full project brief for Claude Design to produce
  6 mockups: {Wallet, Notifications, Media} x {phone, desktop}. User uploads brief, returns
  outputs, Claude implements. Track B starts in parallel after user approval.

**Track B — Phase 1.2: offline queue (Drift)** ✅ CODE COMPLETE (2026-06-06)
- Engine: **Drift** + drift_flutter; local DB = source of truth, UI streams from Drift
- New: `core/db/` (tables, AppDatabase, mappers, provider) + `core/sync/` (SyncService,
  providers). Offline-first repos replaced old Supabase-direct repositories (deleted).
- Outbox write queue + delta pull by `updated_at` watermark; soft-delete tombstones;
  LWW anchored to server clock (Postgres `set_updated_at` trigger).
- Sync triggers: app start, connectivity_plus reconnect, after every local write.
- Client-side UUIDs (uuid v4) so rows have stable ids offline.
- Migration `20260606074518_offline_sync_columns.sql` **applied to remote** (additive,
  idempotent; verified updated_at + deleted_at on transactions + categories).
- Web: `web/sqlite3.wasm` (2.9.4) + `web/drift_worker.js` (2.28.2) committed; relative
  URIs resolve under `/personalhub/` base-href. GitHub Pages = IndexedDB (no OPFS headers).
- `flutter analyze` clean; `flutter build web` OK; codegen `app_database.g.dart` committed.

**Phase 1.2 — verify status (2026-06-06)**
- ✅ App launches clean on Chrome (debug run): Supabase init, no startup crash.
- ✅ **Production verified**: live https://famil-dapti.github.io/personalhub/ serves
  `sqlite3.wasm` (application/wasm) + `drift_worker.js` + base-href `/personalhub/`; Pages deploy
  run = success. The risky web WASM-load path is correctly wired for deploy.
- ✅ Release artifact (`build/web`) serves the same correctly.
- ⛔ **NOT verified (deferred to on-device next session):** authenticated offline flow
  (login -> add -> instant local persist -> Drift DB open -> sync row appears in Supabase ->
  delete -> reconnect). No drivable surface this session: macOS desktop not configured
  (only android+web targets), no Android device/emulator connected, Flutter-web canvas not
  scriptable. Plan: build to the Android phone next session, test offline add/delete + reconnect
  sync there; debug if issues.
- Test login account: famil.mammadov@dapti.az (password held by user, not stored here).

**Phase 1.2 — known gotchas (for next session)**
- ⚠️ **Debug `flutter run -d chrome` does NOT serve `sqlite3.wasm`/`drift_worker.js` (404)** even
  though other web/ assets serve fine — so Drift-on-web fails in *local debug web* runs. Production
  (release/Pages) is unaffected (verified). To test web offline locally, serve the release build
  (`flutter build web` then static-serve `build/web`) instead of `flutter run -d chrome`.
- `unsafeIndexedDb` not safe across multiple simultaneously-writing tabs (single-user, low risk).
- pubspec.lock is now committed (un-ignored) so CI resolves drift 2.28.2 / sqlite3 2.9.4 matching
  the committed `web/` wasm+worker binaries — do NOT bump drift/sqlite3 without refreshing those files.

**Deferred / backlog**
- ✅ **Per-device notification attribution — DONE 2026-06-06** (see the Pre-Phase-3 section above for
  what shipped). On-device re-verify deferred with the rest of Android testing.
- **APK distribution + auto-update (DECIDED, not yet implemented).** Chosen approach = "Option B":
  CI builds a **signed** release APK on push/tag and publishes it to **GitHub Releases**; the app
  checks the GitHub Releases API on launch and offers one-tap download/install of a newer version.
  Free, no Firebase (stays on GitHub+Supabase), and handles native changes (full APK reinstall).
  Prereq: a **fixed keystore stored as a GitHub secret** so every build is signed with the same key
  (Android rejects updates signed by a different key). Note: pure-OTA tools (e.g. Shorebird) only
  push Dart/UI changes — native changes (Phase 2B Kotlin listener, new permissions/plugins) always
  need a full APK, so Shorebird could be layered on later for fast Dart fixes but is not the base.
  USB is only ever needed for live `flutter run` debugging, not for installs.
  **Timing:** implement after the full super app is feature-complete (or re-discuss then).
  Meanwhile: Wallet is already live on web (add-to-home-screen, always current); the APK mainly
  matters for the Android-only Notification Archiver.
  **Caveat (Android 13+):** sideloaded APKs (GitHub Releases download, Bluetooth share) hit the
  "restricted settings" block — notification access can't be toggled until the user does App info →
  ⋮ → "Allow restricted settings" once. USB/adb installs are exempt (why the USB phone worked but
  the Bluetooth-shared phone needed the extra step). Document this for end users of Option B.
- Custom domain: migrate host (Cloudflare Pages `personalhub.pages.dev`) or buy cheap domain for a nicer URL
- Update GitHub Actions to Node 24-compatible versions (deprecation warning, deadline 2026-06-16)

## Known Blockers
- Flutter PATH must be added to ~/.zshrc manually:
  `export PATH="$PATH:/Users/familmammadov/development/flutter/bin"`
- Supabase MCP tools not loaded in current IDE session — restart IDE to load them.

## Architecture Decisions Log
| Date | Decision | Reason |
|---|---|---|
| 2026-06-05 | Flutter + Supabase | Single codebase for Android + Web; free tier sufficient for personal use |
| 2026-06-05 | Riverpod for state | Compile-safe, no context threading, testable |
| 2026-06-05 | go_router for navigation | Web URL support, deep linking |
| 2026-06-05 | Notification archiver Android-only | iOS does not permit third-party notification interception |
| 2026-06-05 | Media Cleaner mobile-only | Browser cannot access device filesystem |
| 2026-06-05 | iOS: Wallet read/write only | Both daily phones are Android; iOS is secondary access |
| 2026-06-06 | Single Supabase project (no staging) | No live data to protect; staging added later when needed |
| 2026-06-06 | Phase 1.1 single currency (AZN) | Simplest start; multi-currency added later if needed |
| 2026-06-06 | Categories: separate table, system presets (user_id NULL) | Custom categories + icons/colors; no per-user seeding |
| 2026-06-06 | Online-only for 1.1; offline queue = Phase 1.2 | Offline sync is high complexity; ship core wallet first |
| 2026-06-06 | transactions.category text → category_id FK | Relational integrity; no live data so safe to alter |
| 2026-06-06 | Web hosting = GitHub Pages (deploy on main) | Repo already on GitHub, no new account, free; Supabase kept for backend |
| 2026-06-06 | Repo made PUBLIC | GitHub Pages free only on public repos; secret scan clean (only Supabase anon key, public-safe). Live: famil-dapti.github.io/personalhub |
| 2026-06-06 | Keep Supabase (not Firebase) | Backend works; hosting is a separate layer; FCM can be added later for APK push |
| 2026-06-06 | Custom domain deferred | GitHub gives no domain; nice free name needs host migration (pages.dev) or cheap domain. Stay on github.io for now |
| 2026-06-06 | APK dist = GitHub Releases + in-app update check (Option B), deferred to end | Free, no Firebase, handles native changes; needs fixed CI keystore. Implement after super app feature-complete |
| 2026-06-06 | Media decisions are LOCAL-ONLY (Drift, assetId+deviceId); only per-device AGGREGATE stats sync (media_stats) | Decisions are per-device, high-volume, and never need cross-device merge; syncing rows is waste. Aggregate stats give a cross-device dashboard cheaply |
| 2026-06-06 | Media indexing = on-launch full + per-launch delta; background WorkManager DEFERRED | MIUI/Xiaomi battery kill makes background scans unreliable; on-launch delta covers new/removed media without the WorkManager complexity |
| 2026-06-06 | photo_manager isolated via conditional import (`if (dart.library.io)`) | Keeps the web build green — photo_manager has no web support; web shows read-only stats only |

## Git Workflow
- Always work on `dev` branch
- Commit with: `git commit --author="Claude <noreply@anthropic.com>" -m "..."`
- Migration changes auto-deploy to Supabase on push to dev or main
- Merge dev -> main when a phase or feature is complete
- Never commit directly to main
