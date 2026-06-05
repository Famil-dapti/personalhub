# Project-state.md

## Current Phase
**Phase 1.1 — Core Wallet (online-only)** (planning done, build not started)

## Status
Phase 0 complete. Flutter shell + auth + CI/CD fully wired. Supabase credentials in place.
Phase 1.1 design decided (see decisions log). Single currency AZN; categories table with
system presets; online-only. Offline queue deferred to Phase 1.2 (separate session).
Supabase MCP added to `.mcp.json` + authenticated; tools load on next IDE session restart.

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

## In Progress
Phase 1.1 committed + pushed to dev (commit 224ebce). Migration `20260606022924_categories.sql`
deploying to Supabase via native GitHub integration. Next: verify presets seeded + manual test
(flutter run). MCP tools load on next IDE session restart.

## Next Task — Phase 1.1: Core Wallet (online-only)

Build in this order:
1. `supabase/migrations/<ts>_categories.sql` — new migration: categories table + RLS +
   preset system rows; alter transactions: drop `category` text, add `category_id` FK
2. `lib/features/wallet/data/models/category_model.dart` — Category data class
3. `lib/features/wallet/data/models/transaction_model.dart` — Transaction data class
4. `lib/features/wallet/data/repositories/category_repository.dart` — read presets + own, create custom
5. `lib/features/wallet/data/repositories/transaction_repository.dart` — CRUD via Supabase
6. `lib/features/wallet/presentation/providers/wallet_provider.dart` — Riverpod AsyncNotifier (transactions)
7. `lib/features/wallet/presentation/providers/category_provider.dart` — categories AsyncNotifier
8. `lib/features/wallet/presentation/screens/wallet_screen.dart` — Replace placeholder: balance card + list
9. `lib/features/wallet/presentation/widgets/balance_card.dart` — AZN balance + monthly summary
10. `lib/features/wallet/presentation/widgets/transaction_tile.dart` — List item (category icon/color)
11. `lib/features/wallet/presentation/screens/add_transaction_screen.dart` — income/expense form + category picker
12. `lib/features/wallet/presentation/screens/manage_categories_screen.dart` — add/list custom categories
13. Dashboard charts (fl_chart): category pie + monthly trend

## Known Blockers
- Flutter PATH must be added to ~/.zshrc manually:
  `export PATH="$PATH:/Users/familmammadov/development/flutter/bin"`

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

## Git Workflow
- Always work on `dev` branch
- Commit with: `git commit --author="Claude <noreply@anthropic.com>" -m "..."`
- Migration changes auto-deploy to Supabase on push to dev or main
- Merge dev -> main when a phase or feature is complete
- Never commit directly to main
