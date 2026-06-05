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

### wallet (Phase 1.1 — built, online-only, AZN)
| Path | Purpose |
|---|---|
| `lib/features/wallet/data/models/transaction_model.dart` | Transaction data class (amount sign = income/expense) |
| `lib/features/wallet/data/models/category_model.dart` | Category data class + CategoryKind enum |
| `lib/features/wallet/data/repositories/transaction_repository.dart` | Transactions CRUD via Supabase |
| `lib/features/wallet/data/repositories/category_repository.dart` | Categories read (presets+own) + create/delete |
| `lib/features/wallet/presentation/providers/wallet_provider.dart` | transactionsProvider (AsyncNotifier) + walletSummaryProvider |
| `lib/features/wallet/presentation/providers/category_provider.dart` | categoriesProvider (AsyncNotifier) + categoryMapProvider |
| `lib/features/wallet/presentation/providers/dashboard_provider.dart` | expenseByCategoryProvider + monthlyTotalsProvider |
| `lib/features/wallet/presentation/screens/wallet_screen.dart` | Balance card + transaction list, FAB to add |
| `lib/features/wallet/presentation/screens/add_transaction_screen.dart` | Income/expense form + category picker + date |
| `lib/features/wallet/presentation/screens/manage_categories_screen.dart` | List presets + add/delete custom categories |
| `lib/features/wallet/presentation/screens/wallet_dashboard_screen.dart` | fl_chart: expense pie + 6-month trend bars |
| `lib/features/wallet/presentation/widgets/balance_card.dart` | AZN balance + month income/expense |
| `lib/features/wallet/presentation/widgets/transaction_tile.dart` | List item with category icon/color |
| `lib/features/wallet/presentation/widgets/category_visuals.dart` | Icon-name->IconData map + hex->Color helpers |
| `lib/core/utils/formatters.dart` | formatMoney / formatSignedMoney / formatDate (tr_TR) |

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
| `supabase/migrations/20260606022924_categories.sql` | categories table + RLS + Turkish presets; transactions.category->category_id FK |
| `.github/workflows/deploy-web.yml` | CI: push to main -> build Flutter web -> deploy to GitHub Pages (famil-dapti.github.io/personalhub) |
| `.github/workflows/deploy-staging.yml` | CI: push to dev + migration change → supabase db push |
| `.github/workflows/deploy-production.yml` | CI: push to main + migration change → supabase db push |
| `pubspec.yaml` | Dependencies: supabase_flutter ^2.9, flutter_riverpod ^2.6.1, go_router ^15.1, google_fonts, fl_chart, intl, uuid |

## Navigation Routes
| Route | Screen | Auth required |
|---|---|---|
| `/auth/login` | LoginScreen | No |
| `/auth/signup` | SignupScreen | No |
| `/wallet` | WalletScreen (tab 0) | Yes |
| `/wallet/add` | AddTransactionScreen | Yes |
| `/wallet/categories` | ManageCategoriesScreen | Yes |
| `/wallet/dashboard` | WalletDashboardScreen | Yes |
| `/notifications` | NotificationsScreen (tab 1) | Yes |
| `/media` | MediaCleanerScreen (tab 2) | Yes |

## Key Patterns
- State: Riverpod `Provider` / `AsyncNotifierProvider`. No `StateNotifier`, no `ChangeNotifier`.
- Navigation: `context.go()` only. No `Navigator.push`.
- Async state: `AsyncValue<T>` from Riverpod for loading/error/data.
- Supabase: anon key + RLS. Service role key never in client code.
- Each feature: `data/` → `domain/` → `presentation/` layers.
