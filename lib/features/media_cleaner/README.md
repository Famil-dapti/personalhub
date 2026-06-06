# media_cleaner — Media Cleaner (Phase 3)

Swipe-review device photos + videos to keep or delete (Tinder-style). Android/
mobile-only; web is a read-only stats view (no device file access).

## Public surface
- `MediaCleanerScreen` — swipe deck (4-way: Left=Delete, Right=Keep, Up=Favorite/
  Protect, Down=Later) + mirror buttons + Undo + Tumu/Foto/Video filter + stats
  panel + filter/sort sheet (route `/media`).
- `MediaDeleteConfirmScreen` — batch confirm of the pending-delete queue, then OS
  MediaStore trash dialog (route `/media/delete`).
- Providers (`media_providers.dart`): media deck, filters, `MediaStats`, index
  controller, `MediaCleanerController` (record decision / undo / enqueue delete).
- `MediaFilter` (domain) — pure filter/sort engine (type, album, date, size,
  screenshots-only, random; undecided-only is the default queue).

## Data flow
Decisions are LOCAL-ONLY (Drift, keyed by assetId + deviceId) and never synced as
rows, so a reviewed item is never re-shown. Only per-device AGGREGATE stats
(total/decided/kept/deleted) sync to Supabase `media_stats` (shown on phones and
web, read-only). Indexing = first-launch full scan + per-launch delta. Deleted
assets drop from the index but the decision row persists (cumulative stats survive).

## Dependencies
`photo_manager` (device media, isolated from web via conditional import),
`flutter_card_swiper` (swipe deck), `core/db` (Drift: LocalMediaAssets /
LocalMediaDecisions / LocalMediaStats, schema v4), `core/sync`,
`deviceIdentityProvider` (per-device attribution), Riverpod, go_router.
