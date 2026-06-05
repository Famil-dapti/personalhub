# ai-index.md — Codebase Map

Last updated: 2026-06-06

## Project Root

| Path | Purpose |
|---|---|
| `lib/main.dart` | App entry point: Supabase.initialize, ProviderScope, MaterialApp.router |
| `lib/core/config/app_config.dart` | Supabase URL + anon key (filled with real values) |
| `lib/core/theme/app_theme.dart` | Material 3 light/dark themes, Google Fonts Inter |
| `lib/core/router/app_router.dart` | go_router config: auth redirect guard, StatefulShellRoute for 3 tabs |
| `lib/core/supabase/supabase_service.dart` | supabaseClientProvider, authStateProvider, currentUserProvider |
| `lib/core/widgets/app_shell.dart` | Bottom NavigationBar shell wrapping StatefulNavigationShell |

## Features

### auth
| Path | Purpose |
|---|---|
| `lib/features/auth/data/auth_repository.dart` | signIn, signUp, signOut via Supabase auth |
| `lib/features/auth/presentation/providers/auth_provider.dart` | AuthActions: calls repo, returns nullable error string |
| `lib/features/auth/presentation/screens/login_screen.dart` | Email/password login form |
| `lib/features/auth/presentation/screens/signup_screen.dart` | Sign up form + email confirmation screen |

### wallet (Phase 1 — not yet built)
| Path | Purpose |
|---|---|
| `lib/features/wallet/presentation/screens/wallet_screen.dart` | Placeholder — shows logout button |

### notifications (Phase 2 — not yet built)
| Path | Purpose |
|---|---|
| `lib/features/notifications/presentation/screens/notifications_screen.dart` | Placeholder |

### media_cleaner (Phase 3 — not yet built)
| Path | Purpose |
|---|---|
| `lib/features/media_cleaner/presentation/screens/media_cleaner_screen.dart` | Placeholder |

## Infrastructure

| Path | Purpose |
|---|---|
| `supabase/migrations/20260605213540_initial_schema.sql` | Creates transactions + notifications tables with RLS |
| `.github/workflows/deploy-staging.yml` | CI: push to dev + migration change → supabase db push |
| `.github/workflows/deploy-production.yml` | CI: push to main + migration change → supabase db push |
| `pubspec.yaml` | Dependencies: supabase_flutter ^2.9, flutter_riverpod ^2.6.1, go_router ^15.1, google_fonts, fl_chart, intl, uuid |

## Navigation Routes
| Route | Screen | Auth required |
|---|---|---|
| `/auth/login` | LoginScreen | No |
| `/auth/signup` | SignupScreen | No |
| `/wallet` | WalletScreen (tab 0) | Yes |
| `/notifications` | NotificationsScreen (tab 1) | Yes |
| `/media` | MediaCleanerScreen (tab 2) | Yes |

## Key Patterns
- State: Riverpod `Provider` / `AsyncNotifierProvider`. No `StateNotifier`, no `ChangeNotifier`.
- Navigation: `context.go()` only. No `Navigator.push`.
- Async state: `AsyncValue<T>` from Riverpod for loading/error/data.
- Supabase: anon key + RLS. Service role key never in client code.
- Each feature: `data/` → `domain/` → `presentation/` layers.
