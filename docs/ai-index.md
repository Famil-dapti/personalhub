# ai-index.md — Codebase Map

Last updated: 2026-06-06 (Phase 4 Notification->Wallet integration code-complete: hybrid regex+Groq parser, settings tab, schema v5, SMS auto-route drafts)

## Project Root

| Path | Purpose |
|---|---|
| `lib/main.dart` | App entry point: Supabase.initialize, ProviderScope, MaterialApp.router |
| `lib/core/config/app_config.dart` | Supabase URL + anon key (filled with real values) |
| `lib/core/theme/app_theme.dart` | Material 3 light/dark themes, Google Fonts Inter |
| `lib/core/router/app_router.dart` | go_router config: auth redirect guard, StatefulShellRoute for 4 tabs; `/wallet/add` reads a TransactionPrefill via `extra` |
| `lib/core/supabase/supabase_service.dart` | supabaseClientProvider, authStateProvider, currentUserProvider |
| `lib/core/widgets/app_shell.dart` | Bottom NavigationBar shell (4 tabs, Turkish labels: Cuzdan/Bildirimler/Medya/Ayarlar) wrapping StatefulNavigationShell |
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
| `lib/features/wallet/data/models/transaction_model.dart` | Transaction data class (amount sign = income/expense; source/notificationId link; `pending` draft flag) |
| `lib/features/wallet/presentation/models/transaction_prefill.dart` | Seed values for AddTransactionScreen from a notification (amount/kind/description/notificationId; existingTransactionId = commit a draft) |
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

### notifications (Phase 2 archive/capture + Phase 4 wallet integration)
| Path | Purpose |
|---|---|
| `lib/features/notifications/data/models/notification_model.dart` | NotificationItem domain model (immutable; toInsert for capture) |
| `lib/features/notifications/data/notification_capture_service.dart` | MethodChannel bridge to Android listener (isPermissionGranted/openSettings/drainPending); no-op off-Android |
| `lib/features/notifications/data/groq_client.dart` | Phase 4 AI fallback: Groq chat-completions (llama-3.1-8b-instant, JSON mode, 8s timeout); sends only title+body; any failure -> null |
| `lib/features/notifications/domain/notification_parser.dart` | Phase 4 device-side parser: package routing -> generic regex (amount/currency/direction, date-noise stripped); parseNotification + lenient parseAmountLenient (SMS) |
| `lib/features/notifications/domain/package_templates.dart` | Bank package constants (Kapital/ABB/Leobank/M10/GPay) + kSmsPackages + BankTemplate scaffold (defers to generic until real samples) |
| `lib/features/notifications/domain/diacritics.dart` | foldAndLower: AZ/TR diacritics -> ASCII+lowercase for keyword matching |
| `lib/features/notifications/domain/parsed_transaction.dart` | ParsedTransaction result (amountMagnitude, TxnDirection, signedAmount, confidence, ParseSource) |
| `lib/features/notifications/presentation/providers/notifications_provider.dart` | notificationsProvider (Drift stream) + search/filter/selected + NotificationsController.ingest (capture write path; SMS NN.NN auto-route to a pending draft) |
| `lib/features/notifications/presentation/providers/capture_providers.dart` | capture service/permission providers + deviceIdentityProvider + NotificationCaptureController.drainAndIngest (stamps device + dedups; isTransaction via parseNotification) |
| `lib/features/notifications/presentation/providers/extractor_provider.dart` | transactionExtractorProvider: regex first, then Groq fallback only if a key is set (called lazily on "Cuzdana ekle") |
| `lib/features/notifications/presentation/screens/notifications_screen.dart` | Responsive archive: phone list / desktop master-detail; shared NotificationDetailBody |
| `lib/features/notifications/presentation/screens/notification_detail_screen.dart` | Pushed phone detail; "Cuzdana ekle" runs the extractor then opens the pre-filled AddTransactionScreen (links notification_id) |
| `lib/features/notifications/presentation/widgets/notification_card.dart` | Archive row (brand avatar, header, title/body, transaction badge) |
| `lib/features/notifications/presentation/widgets/search_field.dart` | Pill search bound to notificationSearchProvider |
| `lib/features/notifications/presentation/widgets/filter_chip_row.dart` | Tumu/Islemler/per-app filter chips |
| `lib/features/notifications/presentation/widgets/detected_transaction_card.dart` | "Islem olarak algilandi" card: shows parsed amount/direction + "Cuzdana ekle" |
| `lib/features/notifications/presentation/widgets/raw_payload_block.dart` | Monospace "Ham veri" payload block |
| `lib/features/notifications/presentation/widgets/capture_runs_on_phone_banner.dart` | Desktop/web read-only capture banner |
| `lib/features/notifications/presentation/widgets/permission_screen.dart` | Android notification-access request screen (deep-links to system settings) |
| `lib/features/notifications/presentation/widgets/notification_visuals.dart` | Deterministic per-app brand color + AppBrandAvatar |

### settings (Phase 4 — per-account Groq API key for the AI fallback parser)
| Path | Purpose |
|---|---|
| `lib/features/settings/presentation/screens/settings_screen.dart` | "Ayarlar" tab: masked Groq API key field (Kaydet/Temizle) + AI-fallback on/off status |
| `lib/features/settings/presentation/providers/settings_provider.dart` | groqApiKeyProvider (synced stream) + SettingsController.setGroqKey/clearGroqKey (Drift+outbox, row id == user id) |

### media_cleaner (Phase 3 — code complete; Android/mobile-only, web = read-only stats)
| Path | Purpose |
|---|---|
| `lib/features/media_cleaner/data/models/media_models.dart` | MediaAsset, MediaStats, enums (type/decision/sort) |
| `lib/features/media_cleaner/data/media_scanner.dart` | Scanner interface + conditional import (`if (dart.library.io)`) isolating photo_manager from web |
| `lib/features/media_cleaner/data/media_scanner_io.dart` | Mobile scanner: photo_manager full scan + per-launch delta (new/removed) |
| `lib/features/media_cleaner/data/media_scanner_web.dart` | Web no-op scanner (no device file access; stats-only) |
| `lib/features/media_cleaner/domain/media_filter.dart` | Pure filter/sort engine (type/album/date/size/screenshots/random; undecided-only default) |
| `lib/features/media_cleaner/presentation/providers/media_providers.dart` | Deck, filters, stats, index controller, MediaCleanerController (record decision / undo / enqueue delete) |
| `lib/features/media_cleaner/presentation/screens/media_cleaner_screen.dart` | Swipe deck (4-way) + filter + stats panel + Undo (route `/media`) |
| `lib/features/media_cleaner/presentation/screens/media_delete_confirm_screen.dart` | Batch confirm of pending-delete queue -> OS MediaStore trash dialog (route `/media/delete`) |
| `lib/features/media_cleaner/presentation/widgets/media_card.dart` | Swipe card: thumbnail + type/size badges |
| `lib/features/media_cleaner/presentation/widgets/media_stats_panel.dart` | Per-device total/decided/kept/deleted counters |
| `lib/features/media_cleaner/presentation/widgets/media_filter_sheet.dart` | Filter/sort bottom sheet |
| `lib/features/media_cleaner/presentation/widgets/format_bytes.dart` | Human-readable byte formatter |

### offline-first (Phase 1.2 — Drift local DB + sync engine)
| Path | Purpose |
|---|---|
| `lib/core/db/tables.dart` | Drift tables: LocalTransactions (+pending draft flag), LocalCategories (+updatedAt/deletedAt), LocalNotifications (append-only + deviceId/deviceName), LocalMediaAssets, LocalMediaDecisions (assetId+deviceId, local-only), LocalMediaStats, LocalUserSettings (per-user Groq key), SyncOutbox, SyncState |
| `lib/core/db/app_database.dart` | AppDatabase (schemaVersion 5): reactive watch* reads, atomic write+outbox, watermark+upsert helpers, notificationExistsLike dedup, transactionExistsForNotification guard, user-settings + media helpers; onUpgrade v4->5 creates user_settings + adds transactions.pending; cross-platform `driftDatabase()` open |
| `lib/core/db/app_database.g.dart` | Generated drift code (committed; CI does not run build_runner) |
| `lib/core/db/mappers.dart` | Drift row -> domain model; Supabase JSON -> Drift companion (incl. media_stats + user_settings; transactions carry `pending`) |
| `lib/core/db/database_provider.dart` | appDatabaseProvider (singleton AppDatabase) |
| `lib/core/sync/sync_service.dart` | Push outbox (idempotent upsert / soft-delete) + delta pull (transactions/categories by updated_at, notifications by created_at, media_stats + user_settings by updated_at watermark); LWW = server clock. Media decision rows are NEVER synced (local-only) |
| `lib/core/sync/sync_providers.dart` | syncServiceProvider + syncBootstrapProvider (initial sync + connectivity_plus reconnect trigger) |

## Infrastructure

| Path | Purpose |
|---|---|
| `android/app/src/main/kotlin/com/personalhub/personalhub/NotificationArchiverService.kt` | NotificationListenerService: captures notifications -> SharedPreferences buffer (Phase 2B) |
| `android/app/src/main/kotlin/com/personalhub/personalhub/MainActivity.kt` | MethodChannel `personalhub/notifications`: isPermissionGranted/openSettings/drainPending |
| `android/app/src/main/AndroidManifest.xml` | INTERNET permission (release-build fix) + NotificationListenerService declaration + media perms (READ_MEDIA_IMAGES, READ_MEDIA_VIDEO, ACCESS_MEDIA_LOCATION, READ_EXTERNAL_STORAGE maxSdk 32) |
| `supabase/migrations/20260605213540_initial_schema.sql` | Creates transactions + notifications tables with RLS |
| `supabase/migrations/20260606022924_categories.sql` | categories table + RLS + Turkish presets; transactions.category->category_id FK |
| `supabase/migrations/20260606074518_offline_sync_columns.sql` | Adds updated_at (server trigger) + deleted_at tombstones + delta indexes to transactions/categories |
| `supabase/migrations/20260606120000_notification_device_attribution.sql` | Adds device_id + device_name to notifications (which phone captured each one) |
| `supabase/migrations/20260607090000_media_stats.sql` | media_stats table (per-device aggregate: total/decided/kept/deleted) + RLS + set_updated_at trigger (deployed) |
| `supabase/migrations/20260608090000_user_settings.sql` | user_settings table (per-user Groq API key; one row per user) + RLS + set_updated_at trigger |
| `supabase/migrations/20260608091000_transaction_pending.sql` | Adds transactions.pending (SMS draft flag; excluded from balance until committed) |
| `web/sqlite3.wasm`, `web/drift_worker.js` | Drift web runtime (version-matched: sqlite3 2.9.4, drift 2.28.2); served under /personalhub/ via base-href |
| `.github/workflows/deploy-web.yml` | CI: push to main -> build Flutter web -> deploy to GitHub Pages (famil-dapti.github.io/personalhub) |
| `.github/workflows/deploy-staging.yml` | CI: push to dev + migration change → supabase db push |
| `.github/workflows/deploy-production.yml` | CI: push to main + migration change → supabase db push |
| `pubspec.yaml` | Deps: supabase_flutter ^2.9, flutter_riverpod ^2.6.1, go_router ^15.1, google_fonts, fl_chart, intl, uuid, shared_preferences, drift + drift_flutter + sqlite3_flutter_libs + connectivity_plus (offline), photo_manager ^3.9.0 + flutter_card_swiper ^7.2.0 (media cleaner; drift/sqlite3 unchanged) |
| `build.yaml` | Codegen config: disables riverpod_generator (unused; crashes old analyzer on SDK 3.12), leaves only drift_dev |

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
| `/media/delete` | MediaDeleteConfirmScreen | Yes |
| `/settings` | SettingsScreen (tab 3) | Yes |

## Key Patterns
- State: Riverpod `Provider` / `StreamProvider`. Wallet/category lists stream from Drift; writes go through plain controller classes (write to Drift + outbox, then kick sync). No `StateNotifier`, no `ChangeNotifier`.
- Offline-first: Drift = local source of truth; UI never reads Supabase directly. The sync engine is the only Supabase caller for wallet data. Client-generated UUIDs (`uuid` v4) so rows have stable ids offline. Soft-delete (`deletedAt`) — never hard-delete synced rows.
- Navigation: `context.go()` only. No `Navigator.push`.
- Async state: `AsyncValue<T>` from Riverpod for loading/error/data.
- Supabase: anon key + RLS. Service role key never in client code.
- Each feature: `data/` → `domain/` → `presentation/` layers.
