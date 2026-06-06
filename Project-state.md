# Project-state.md

## Current Phase
**Phase 1.2 — Offline queue (Drift)** ✅ CODE COMPLETE (analyze clean, web build OK, migration live on remote).
Parallel: Claude Design brief delivered (awaiting returned mockups to implement).
Next: manual end-to-end offline test on device/web, then commit + deploy.

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
Nothing. Phase 1.1 done and deployed. Session closed for handoff to a new chat.

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

**Phase 1.2 — remaining before done**
- Manual end-to-end test: add/delete offline, reconnect, confirm sync both directions + multi-device.
- Commit to `dev` and deploy (user controls commit/push).
- Known: `unsafeIndexedDb` not safe across multiple simultaneously-writing tabs (single-user, low risk).

**Deferred / backlog**
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

## Git Workflow
- Always work on `dev` branch
- Commit with: `git commit --author="Claude <noreply@anthropic.com>" -m "..."`
- Migration changes auto-deploy to Supabase on push to dev or main
- Merge dev -> main when a phase or feature is complete
- Never commit directly to main
