# Project-state.md

## Current Phase
**Phase 1 — Wallet App** (not started)

## Status
Phase 0 complete. Flutter shell + auth + CI/CD fully wired. Supabase credentials in place.
Waiting to verify first migration ran successfully via CI/CD, then Phase 1 begins.

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
- [ ] First CI/CD migration run verified

## In Progress
Nothing.

## Next Task — Phase 1: Wallet App

Build in this order:
1. `lib/features/wallet/data/models/transaction_model.dart` — Transaction data class
2. `lib/features/wallet/data/repositories/transaction_repository.dart` — CRUD via Supabase
3. `lib/features/wallet/presentation/providers/wallet_provider.dart` — Riverpod AsyncNotifier
4. `lib/features/wallet/presentation/screens/wallet_screen.dart` — Replace placeholder: balance card + transaction list
5. `lib/features/wallet/presentation/screens/add_transaction_screen.dart` — Add income/expense form
6. `lib/features/wallet/presentation/widgets/transaction_tile.dart` — List item widget
7. `lib/features/wallet/presentation/widgets/balance_card.dart` — Summary card at top

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

## Git Workflow
- Always work on `dev` branch
- Commit with: `git commit --author="Claude <noreply@anthropic.com>" -m "..."`
- Migration changes auto-deploy to Supabase on push to dev or main
- Merge dev -> main when a phase or feature is complete
- Never commit directly to main
