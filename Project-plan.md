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

### `media_decisions` table
```sql
id uuid primary key
user_id uuid references auth.users
file_path text
decision text                  -- 'keep' | 'delete' | 'pending'
decided_at timestamptz
```

All tables: RLS enabled, `user_id = auth.uid()` policy.

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
- [ ] Android NotificationListenerService (Kotlin)
- [ ] Platform channel: Kotlin -> Flutter stream
- [ ] Save notifications to Supabase in background
- [ ] Archive UI: searchable list, filter by app/date
- [ ] Web view: read-only archive
- [ ] Foreground service with persistent notification

### Phase 3 — Media Cleaner
- [ ] Scan device media (photo_manager package)
- [ ] Tinder-style swipe card stack UI
- [ ] Swipe right = keep, swipe left = delete (moves to trash queue)
- [ ] Batch confirm delete screen
- [ ] Filter: photos only / videos only / all
- [ ] Progress stats: freed space estimate

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
