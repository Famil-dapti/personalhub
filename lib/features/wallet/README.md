# wallet

Wallet mini-app: income/expense tracking with categories (Phase 1.1, online-only, AZN).

## Public surface
- `WalletScreen` — balance card + transaction list (route `/wallet`)
- `AddTransactionScreen` — income/expense form (route `/wallet/add`)
- `ManageCategoriesScreen` — preset + custom categories (route `/wallet/categories`)
- `WalletDashboardScreen` — pie + monthly trend charts (route `/wallet/dashboard`)
- Providers: `transactionsProvider`, `categoriesProvider`, `walletSummaryProvider`

## Dependencies
- Supabase (`transactions`, `categories` tables, RLS) via `supabaseClientProvider`
- Riverpod (AsyncNotifier), fl_chart, intl

## Layers
`data/` (models + repositories) -> `presentation/` (providers + screens + widgets)
