# ai-index.md — Codebase Map

Last updated: 2026-06-06 (Phase 2A — Notification Archiver UI + data layer)

## Project Root

| Path | Purpose |
|---|---|
| `lib/main.dart` | App entry point: Supabase.initialize, ProviderScope, MaterialApp.router |
| `lib/core/config/app_config.dart` | Supabase URL + anon key (filled with real values) |
| `lib/core/theme/app_theme.dart` | Material 3 light/dark themes, Google Fonts Inter |
| `lib/core/router/app_router.dart` | go_router config: auth redirect guard, StatefulShellRoute for 3 tabs |
| `lib/core/supabase/supabase_service.dart` | supabaseClientProvider, authStateProvider, currentUserProvider |
| `lib/core/widgets/app_shell.dart` | Bottom NavigationBar shell wrapping StatefulNavigationShell |
| `lib/core/widgets/app_spacing.dart` | Spacing tokens (4..32) + reusable gap/FAB-clearance SizedBoxes |
| `lib/core/widgets/app_feedback.dart` | Floating success/error snackbar helpers |
| `lib/core/widgets/skeleton.dart` | Shimmer skeleton primitives (Skeleton, SkeletonBox, SkeletonListTile) |
| `lib/core/widgets/empty_state.dart` | Reusable icon+title+hint+action empty state |
| `docs/design/claude-design-brief.md` | Brief for Claude Design: 6 mockup sets (3 apps x phone/desktop) |

## Features

### auth
| Path | Purpose |
|---|---|
| `lib/features/auth/data/auth_repository.dart` | signIn, signUp, signOut via Supabase auth |
| `lib/features/auth/presentation/providers/auth_provider.dart` | AuthActions: calls repo, returns nullable error string |
| `lib/features/auth/presentation/screens/login_screen.dart` | Email/password login form |
| `lib/features/auth/presentation/screens/signup_screen.dart` | Sign up form + email confirmation screen |

### wallet (Phase 1.1 built; Phase 1.2 offline-first via Drift)
| Path | Purpose |
|---|---|
| `lib/features/wallet/data/models/transaction_model.dart` | Transaction data class (amount sign = income/expense) |
| `lib/features/wallet/data/models/category_model.dart` | Category data class + CategoryKind enum |
| `lib/features/wallet/presentation/providers/wallet_provider.dart` | transactionsProvider (StreamProvider from Drift) + TransactionsController (write+outbox) + walletSummaryProvider |
| `lib/features/wallet/presentation/providers/category_provider.dart` | categoriesProvider (StreamProvider from Drift) + CategoriesController + categoryMapProvider |
| `lib/features/wallet/presentation/providers/dashboard_provider.dart` | expenseByCategoryProvider + monthlyTotalsProvider |
| `lib/features/wallet/presentation/screens/wallet_screen.dart` | Balance card + transaction list, FAB to add |
| `lib/features/wallet/presentation/screens/add_transaction_screen.dart` | Income/expense form + category picker + date |
| `lib/features/wallet/presentation/screens/manage_categories_screen.dart` | List presets + add/delete custom categories |
| `lib/features/wallet/presentation/screens/wallet_dashboard_screen.dart` | fl_chart: expense pie + 6-month trend bars |
| `lib/features/wallet/presentation/widgets/balance_card.dart` | AZN balance + month income/expense |
| `lib/features/wallet/presentation/widgets/transaction_tile.dart` | List item with category icon/color |
| `lib/features/wallet/presentation/widgets/category_visuals.dart` | Icon-name->IconData map + hex->Color helpers |
| `lib/core/utils/formatters.dart` | formatMoney / formatSignedMoney / formatDate (tr_TR) |

### notifications (Phase 2A — archive UI + data built; 2B native capture pending)
| Path | Purpose |
|---|---|
| `lib/features/notifications/data/models/notification_model.dart` | NotificationItem domain model (immutable; toInsert for capture) |
| `lib/features/notifications/presentation/providers/notifications_provider.dart` | notificationsProvider (Drift stream) + search/filter/selected providers + NotificationsController.ingest (capture write path) |
| `lib/features/notifications/presentation/screens/notifications_screen.dart` | Responsive archive: phone list / desktop master-detail; shared NotificationDetailBody |
| `lib/features/notifications/presentation/screens/notification_detail_screen.dart` | Pushed phone detail (reads selectedNotificationProvider) |
| `lib/features/notifications/presentation/widgets/notification_card.dart` | Archive row (brand avatar, header, title/body, transaction badge) |
| `lib/features/notifications/presentation/widgets/search_field.dart` | Pill search bound to notificationSearchProvider |
| `lib/features/notifications/presentation/widgets/filter_chip_row.dart` | Tumu/Islemler/per-app filter chips |
| `lib/features/notifications/presentation/widgets/detected_transaction_card.dart` | "Islem olarak algilandi" card (wallet link = Phase 4) |
| `lib/features/notifications/presentation/widgets/raw_payload_block.dart` | Monospace "Ham veri" payload block |
| `lib/features/notifications/presentation/widgets/capture_runs_on_phone_banner.dart` | Desktop/web read-only capture banner |
| `lib/features/notifications/presentation/widgets/notification_visuals.dart` | Deterministic per-app brand color + AppBrandAvatar |

### media_cleaner (Phase 3 — not yet built)
| Path | Purpose |
|---|---|
| `lib/features/media_cleaner/presentation/screens/media_cleaner_screen.dart` | Placeholder |

### offline-first (Phase 1.2 — Drift local DB + sync engine)
| Path | Purpose |
|---|---|
| `lib/core/db/tables.dart` | Drift tables: LocalTransactions, LocalCategories (+updatedAt/deletedAt), LocalNotifications (immutable, append-only), SyncOutbox, SyncState |
| `lib/core/db/app_database.dart` | AppDatabase: reactive watch* reads, atomic write+outbox, watermark + upsert helpers; cross-platform `driftDatabase()` open (web = relative wasm/worker URIs) |
| `lib/core/db/app_database.g.dart` | Generated drift code (committed; CI does not run build_runner) |
| `lib/core/db/mappers.dart` | Drift row -> domain model; Supabase JSON -> Drift companion |
| `lib/core/db/database_provider.dart` | appDatabaseProvider (singleton AppDatabase) |
| `lib/core/sync/sync_service.dart` | Push outbox (idempotent upsert / soft-delete) + delta pull (transactions/categories by updated_at, notifications by created_at watermark); LWW = server clock |
| `lib/core/sync/sync_providers.dart` | syncServiceProvider + syncBootstrapProvider (initial sync + connectivity_plus reconnect trigger) |

## Infrastructure

| Path | Purpose |
|---|---|
| `supabase/migrations/20260605213540_initial_schema.sql` | Creates transactions + notifications tables with RLS |
| `supabase/migrations/20260606022924_categories.sql` | categories table + RLS + Turkish presets; transactions.category->category_id FK |
| `supabase/migrations/20260606074518_offline_sync_columns.sql` | Adds updated_at (server trigger) + deleted_at tombstones + delta indexes to transactions/categories |
| `web/sqlite3.wasm`, `web/drift_worker.js` | Drift web runtime (version-matched: sqlite3 2.9.4, drift 2.28.2); served under /personalhub/ via base-href |
| `.github/workflows/deploy-web.yml` | CI: push to main -> build Flutter web -> deploy to GitHub Pages (famil-dapti.github.io/personalhub) |
| `.github/workflows/deploy-staging.yml` | CI: push to dev + migration change → supabase db push |
| `.github/workflows/deploy-production.yml` | CI: push to main + migration change → supabase db push |
| `pubspec.yaml` | Deps: supabase_flutter ^2.9, flutter_riverpod ^2.6.1, go_router ^15.1, google_fonts, fl_chart, intl, uuid, drift + drift_flutter + sqlite3_flutter_libs + connectivity_plus (offline) |

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
| `/notifications/detail` | NotificationDetailScreen | Yes |
| `/media` | MediaCleanerScreen (tab 2) | Yes |

## Key Patterns
- State: Riverpod `Provider` / `StreamProvider`. Wallet/category lists stream from Drift; writes go through plain controller classes (write to Drift + outbox, then kick sync). No `StateNotifier`, no `ChangeNotifier`.
- Offline-first: Drift = local source of truth; UI never reads Supabase directly. The sync engine is the only Supabase caller for wallet data. Client-generated UUIDs (`uuid` v4) so rows have stable ids offline. Soft-delete (`deletedAt`) — never hard-delete synced rows.
- Navigation: `context.go()` only. No `Navigator.push`.
- Async state: `AsyncValue<T>` from Riverpod for loading/error/data.
- Supabase: anon key + RLS. Service role key never in client code.
- Each feature: `data/` → `domain/` → `presentation/` layers.
