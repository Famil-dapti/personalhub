# Project-plan.md — PersonalHub Super App

## Vision

A personal "app-in-app" suite accessible from any device (Android phone, second phone, computer, browser). All data synced via Supabase. Three mini-apps live inside a single shell:

1. **Wallet** — manual + auto-detected income/expense tracking
2. **Notification Archiver** — captures every Android notification; future integration auto-categorizes transactions
3. **Media Cleaner** — scans device media, Tinder-style swipe to keep or delete

## Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| UI framework | Flutter (Dart) | Single codebase for Android APK + iOS IPA + Flutter Web |
| Backend | Supabase (free tier) | Auth, PostgreSQL, Storage, Realtime — no server to manage |
| State management | Riverpod | Compile-safe, testable, no context threading |
| Navigation | go_router | Deep linking, web URL support |
| Android foreground | Kotlin platform channel | NotificationListenerService requires native Android |
| HTTP/API | Supabase Flutter SDK | Official, type-safe |

## Supabase Schema (planned)

### `transactions` table
```sql
id uuid primary key
user_id uuid references auth.users
amount numeric not null        -- positive = income, negative = expense
currency text default 'AZN'    -- Phase 1.1: AZN only (single currency)
category_id uuid references categories on delete set null
description text
source text                    -- 'manual' | 'notification'
notification_id uuid           -- FK to notifications if auto-detected
created_at timestamptz default now()
```

### `categories` table (Phase 1.1)
```sql
id uuid primary key
user_id uuid references auth.users on delete cascade  -- NULL = system preset (shared)
name text not null
kind text not null             -- 'income' | 'expense'
icon text                      -- Material icon identifier
color text                     -- hex string e.g. '#4CAF50'
sort_order int default 0
created_at timestamptz default now()
```
RLS: `select` where `user_id is null OR user_id = auth.uid()`; write only own rows.
Preset categories are seeded as system rows (`user_id IS NULL`) — no per-user seeding needed.

### `notifications` table
```sql
id uuid primary key
user_id uuid references auth.users
app_package text
app_name text
title text
body text
posted_at timestamptz
is_transaction bool default false
raw_json jsonb                 -- full notification payload
```

### media decisions — LOCAL-ONLY (revised Phase 3, 2026-06-06)
Individual media decisions are **not** a Supabase table. They live only in Drift
(`LocalMediaDecisions`, keyed by `assetId + deviceId`) and are never synced — they are
per-device and high-volume, with no cross-device merge need. Only per-device **aggregate**
stats sync (below).

### `media_stats` table (Phase 3 — per-device aggregate only)
```sql
id uuid primary key
user_id uuid references auth.users
device_id text                 -- which phone these counters belong to
device_name text
total int                      -- indexed assets
decided int                    -- reviewed (kept/deleted/favorite/later)
kept int
deleted int                    -- cumulative; survives asset removal
updated_at timestamptz         -- server set_updated_at trigger; delta-pull watermark
```
Migration `20260607090000_media_stats.sql` (RLS + trigger). Shown on phones AND web (read-only).

All Supabase tables: RLS enabled, `user_id = auth.uid()` policy.

## Project Phases

### Phase 0 — Foundation (current)
- [ ] Flutter project scaffold
- [ ] Supabase project creation + schema
- [ ] Auth flow (email/password, Google OAuth)
- [ ] Shell app: bottom nav with 3 tabs (Wallet, Notifications, Media)
- [ ] Theme system, routing

### Phase 1 — Wallet App

**Phase 1.1 — Core Wallet (online-only)** ← current
- [ ] `categories` table migration + preset seed (system rows)
- [ ] Transaction + Category models
- [ ] Repositories: transactions CRUD, categories read/create
- [ ] Riverpod providers (AsyncNotifier)
- [ ] Wallet screen: balance card + transaction list
- [ ] Add transaction form (income/expense, category picker)
- [ ] Category management screen (add custom categories)
- [ ] Dashboard: AZN balance, monthly summary, category breakdown
- [ ] Charts (fl_chart): category pie + monthly trend
- Single currency (AZN). Online-only — requires connection.

**Phase 1.2 — Offline queue (Drift)** — code complete 2026-06-06
- [x] Local cache: **Drift** (typed SQL, web/WASM, Riverpod streams) — chosen over Hive (relational FK) and PowerSync (paid cloud, overkill)
- [x] Write queue: `SyncOutbox` drained oldest-first on reconnect (idempotent upserts + soft-delete)
- [x] Conflict handling: last-write-wins anchored to server clock (`set_updated_at` trigger) + `deleted_at` tombstones
- [x] Optimistic UI updates: writes hit Drift first, UI streams from Drift, sync runs in background
- [ ] Manual end-to-end verification (offline add/delete -> reconnect -> bidirectional sync)

### Phase 2 — Notification Archiver

Split so the Android-testing dependency does not block progress: 2A is fully
cross-platform and web-verifiable now; 2B is the native capture path, written
later and verified on-device in one session (same device session as the
Phase 1.2 offline E2E test).

**Phase 2A — Data layer + Archive UI (cross-platform)** — code complete 2026-06-06
- [x] Lightweight sync (NOT full offline-first): notifications are immutable/
      append-only, so no edit/delete/LWW machinery. Capture → Drift + outbox →
      Supabase upsert; all clients delta-pull by `created_at` watermark.
- [x] Drift `LocalNotifications` mirror (schema v2 + onUpgrade migration; no
      server migration needed — table + RLS already exist)
- [x] Archive UI: search, filter chips (Tumu/Islemler/per-app), day grouping,
      notification card (+ transaction badge), detail view, raw payload block
- [x] Responsive: phone list (pushed detail) + desktop/web master-detail
- [x] Web read-only archive (capture-runs-on-phone banner)
- [x] `flutter analyze` clean; `flutter build web` OK; tests pass

**Phase 2B — Android native capture** — built & device-verified 2026-06-06
- [x] Android NotificationListenerService (Kotlin) → SharedPreferences buffer (approach B)
- [x] Platform channel `personalhub/notifications` → Dart drain → `NotificationsController.ingest()`
- [x] Phone permission/setup flow (deep-link to NotificationListener settings) + PermissionScreen
- [x] Fixed missing INTERNET permission in main manifest (release-only network break)
- [x] On-device verification: sent self a message → capture → archive → Supabase → web ✅
- [ ] Foreground service for capture hardening (MIUI battery-kill resilience) — optional, deferred
- [ ] Per-device attribution (two phones / one account) — REQUIRED before Phase 3

### Phase 3 — Media Cleaner — code complete 2026-06-06 (on-device verify deferred)

Android/mobile-only; web is a read-only stats view (no device file access).

- [x] Scan device media (photo_manager) — first-launch FULL scan + per-launch DELTA (new/removed);
      background WorkManager deferred (unreliable on MIUI battery-kill)
- [x] Tinder-style swipe card stack UI (flutter_card_swiper)
- [x] **4-way swipe**: Left=Delete, Right=Keep, Up=Favorite/Protect, Down=Later (defer) — plus
      mirror action buttons + Undo (Geri al)
- [x] Pending-delete queue + batch confirm screen -> OS MediaStore trash dialog
      (`PhotoManager.editor.deleteWithIds`)
- [x] Filter: Tumu / Foto / Video + rich sort (album/folder, date, size-largest, screenshots-only,
      random; "undecided only" is the default queue)
- [x] Progress stats: total / decided / kept / deleted per device
- [x] **Decisions LOCAL-ONLY** (Drift, keyed assetId+deviceId; never re-shown; never synced as rows)
- [x] **Only per-device AGGREGATE stats sync** (Supabase `media_stats`, shown on phones + web read-only)
- [ ] On-device verification (deferred to the same parked Android test session as 1.2/2 re-verify)
- [ ] Deploy `media_stats` migration to Supabase (written, not yet applied)

### Phase 5 — Transaction Attachments (future — after all 3 apps ready)
- [ ] Optional image per transaction (receipt/proof)
- [ ] Upload flow: image → Supabase Storage (temporary) → move to a predefined Google Drive folder
- [ ] After the move succeeds, DELETE the Supabase Storage copy (free plan — keep storage near-zero)
- [ ] DB stores ONLY the Drive link (not the binary)
- [ ] Add `attachment_url text` column to transactions (single additive migration when built)
- Open questions (decide when built): Drive API auth (OAuth vs service account), folder structure,
  web vs mobile upload paths.

### Phase 4 — Wallet + Notification Integration
- [ ] ML/regex parser: detect transaction amounts in notification body
- [ ] Auto-create transaction draft from matching notification
- [ ] User confirms or dismisses draft
- [ ] Link notification_id to transaction record

### Phase 6 — Cloud Photos (future idea)
- [ ] Connect Google Photos account(s) via OAuth so Media Cleaner can also review/act on cloud photos
- [ ] Mirror the same swipe-review + keep/delete flow over Google Photos library items
- Open questions (decide when built): Google Photos Library API scopes/quota, delete-vs-archive
  semantics in the cloud, how cloud decisions relate to the local decision store.

## Folder Structure (planned)

```
lib/
  main.dart
  core/
    theme/
    router/
    supabase/         # client init, auth provider
    widgets/          # shared widgets
  features/
    auth/
    wallet/
      data/           # repositories, models
      domain/         # use cases
      presentation/   # screens, widgets, providers
    notifications/
      data/
      domain/
      presentation/
    media_cleaner/
      data/
      domain/
      presentation/
android/
  app/src/main/kotlin/
    NotificationService.kt
    MainActivity.kt
web/                  # Flutter web build output
docs/
  ai-index.md
  clean-code-principles.md
  research/
```

## Platform Feature Matrix

| Feature | Android | iOS | Web (browser) |
|---|---|---|---|
| Wallet (view/add/edit) | ✅ | ✅ | ✅ |
| Notification Archiver (capture) | ✅ | ❌ Apple restriction | ❌ |
| Notification Archiver (view archive) | ✅ | ✅ read-only | ✅ read-only |
| Media Cleaner | ✅ | ✅ | ❌ no device file access |

**iOS usage context:** User has two Android phones (primary use) and may access Wallet from iOS. Flutter produces a valid iOS IPA — no code changes needed for Wallet feature parity.

## Key Constraints

- Supabase free tier: 500MB DB, 1GB storage, 50k MAU — sufficient for personal use.
- NotificationListenerService requires user to manually grant permission in Android Settings.
- Media file deletion is irreversible — always show confirm screen before executing.
- Flutter Web cannot access device files — Media Cleaner is mobile-only.
- No service_role key in client app — use anon key + RLS.
- iOS build requires a Mac with Xcode — can build when/if needed; not a primary target.
