# Project-state.md

## Current Phase
**Phase 0 — Foundation** (complete — pending Supabase credentials)

## Status
Flutter project scaffolded and compiling clean. Auth, shell, router all wired up. Blocked on Supabase credentials.

## Completed
- [x] Architecture decision: Flutter + Supabase
- [x] Project documentation created (CLAUDE.md, Project-plan.md, docs/)
- [x] Flutter 3.44.1 installed (/Users/familmammadov/development/flutter/)
- [x] Flutter project created: `personalhub` (Flutter + Web)
- [x] Dependencies added: supabase_flutter, flutter_riverpod, go_router, google_fonts, fl_chart, intl, uuid
- [x] Core infrastructure: AppConfig, AppTheme (Material 3), AppRouter (go_router), AppShell (bottom nav)
- [x] Supabase service providers: supabaseClientProvider, authStateProvider, currentUserProvider
- [x] Auth feature: AuthRepository, AuthActions, LoginScreen, SignupScreen
- [x] Shell: 3-tab bottom nav (Wallet, Notifications, Media) with placeholder screens
- [x] Auth redirect guard: unauthenticated -> /auth/login, authenticated -> /wallet
- [x] `flutter analyze` → No issues found

## In Progress
Nothing.

## Next Task
**Connect to Supabase (user action required):**
1. Go to supabase.com → create a new project
2. Project Settings → API → copy "Project URL" and "anon public" key
3. Paste into `lib/core/config/app_config.dart`:
   ```dart
   static const supabaseUrl = 'https://xxxx.supabase.co';
   static const supabaseAnonKey = 'eyJ...';
   ```
4. Run schema SQL from Project-plan.md in Supabase SQL Editor
5. `flutter run` to test auth flow on device/emulator

After credentials: **Phase 1 — Wallet App** begins.

## Known Blockers
- Supabase project URL and anon key needed (user must create project at supabase.com)
- Flutter PATH must be added to ~/.zshrc manually: `export PATH="$PATH:/Users/familmammadov/development/flutter/bin"`

## Architecture Decisions Log
| Date | Decision | Reason |
|---|---|---|
| 2026-06-05 | Flutter + Supabase | Single codebase for Android + Web; Supabase free tier sufficient for personal use |
| 2026-06-05 | Riverpod for state | Compile-safe, no context threading, testable |
| 2026-06-05 | go_router for navigation | Web URL support, deep linking |
| 2026-06-05 | Notification archiver Android-only | iOS does not permit third-party notification interception |
| 2026-06-05 | Media Cleaner mobile-only | Browser cannot access device filesystem |
| 2026-06-05 | iOS: Wallet only | Both daily phones are Android; iOS is secondary access for Wallet read/write only |
