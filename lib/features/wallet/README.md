# wallet

Wallet mini-app: income/expense tracking with categories (Phase 1.1, online-only, AZN).

## Public surface
- `WalletScreen` — balance card + transaction list (route `/wallet`)
- `AddTransactionScreen` — income/expense form (route `/wallet/add`); accepts a
  `TransactionPrefill` via go_router `extra` to seed an editable draft from a
  notification (Phase 4)
- `ManageCategoriesScreen` — preset + custom categories (route `/wallet/categories`)
- `WalletDashboardScreen` — pie + monthly trend charts (route `/wallet/dashboard`)
- Providers: `transactionsProvider`, `categoriesProvider`, `walletSummaryProvider`

Screens are responsive (`context.isWide`): desktop renders a two-column home with
inline quick-add + search, centered forms, and side-by-side dashboard charts.

## Dependencies
- Supabase (`transactions`, `categories` tables, RLS) via `supabaseClientProvider`
- Riverpod (AsyncNotifier), fl_chart, intl

## Layers
`data/` (models + repositories) -> `presentation/` (providers + screens + widgets)
