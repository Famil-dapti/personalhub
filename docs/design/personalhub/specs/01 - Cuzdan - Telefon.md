# Set 1 — Wallet (Cuzdan) · Phone

File: `Cuzdan - Telefon.html` · Frame 380×800 · light + dark · **interactive**.
Tokens: see `00 - Tokens.md`.

## Chrome
- **Status bar** 36px. **App bar**: title `Cuzdan` (`titleLarge`) + actions `Ozet` (bar_chart), `Kategoriler` (category), `Cikis` (logout).
- **Bottom nav**: `Cuzdan` (active) / `Bildirimler` / `Medya`. Active pill `primaryContainer`.
- **Extended FAB** bottom-right, `Islem Ekle` (add), `primaryContainer`.

## A. Wallet home
- **Balance card** — `primary` gradient, `onPrimary` text. `Bakiye` label (`bodySmall`), amount `headlineMedium` tabular. Two summary tiles inside a translucent fill: `Bu ay gelir` (south_west) and `Bu ay gider` (north_east).
- **Transaction list** grouped by day. Day header `Bugun`/`Dun`/`6 Haziran 2025` (`labelLarge`, `onSurfaceVariant`). Newest first.
  - **Row** — leading 44px category avatar (icon at category color on a 13%-tint circle); title = category name (`titleSmall`); subtitle = `aciklama · tarih` (1 line, ellipsis, `bodySmall`); trailing signed amount (`bodyLarge`, income green / expense red).
  - **Delete** — swipe row right-to-left (>110px) reveals red `error` background → confirm dialog → success snackbar `Islem silindi`. **Long-press** (550ms) also opens the dialog.
- **Spacing** — 16 edge; balance card → list 16; rows 11 vertical.

### States
- **Loading** — skeleton: balance card block (150px) + 4 shimmer rows.
- **Empty** — icon `receipt_long`, `Henuz islem yok`, hint, tonal `Islem Ekle`.
- **Error** — icon `cloud_off` in `errorContainer`, `Bir sorun olustu`, message, tonal `Tekrar dene`.

## B. Add transaction
- Segmented `Gider` / `Gelir` (selected tints text expense-red / income-green). Switching swaps category set.
- **Tutar** field, `headlineSmall`, suffix `AZN`.
- **Kategori** — choice-chip wrap, each colored category icon + name; one selectable (`secondaryContainer`).
- **Aciklama (istege bagli)** — multi-line.
- **Tarih** — row opening date picker.
- **Kaydet** — filled, full-width; inline spinner while saving → snackbar `Islem eklendi` + close.

## C. Manage categories
- Sections `Gider Kategorileri` / `Gelir Kategorileri` (`labelLarge`, `primary`).
- Row — avatar + name; presets show `Hazir kategori` tag (not deletable); custom show delete (confirm → snackbar).
- Empty section → `Henuz kategori yok`.
- **FAB** `Kategori Ekle` → **bottom sheet** (drag handle): kind toggle, `Kategori adi`, **icon picker** (12 chips), **color picker** (8 swatches), **live preview chip**. `Kaydet` → snackbar.

## D. Dashboard (Ozet)
- **Donut** `Bu Ay Gider Dagilimi` (conic gradient by category) + center total + legend list (colored dot + name + amount).
- **Bar chart** `Son 6 Ay`, income vs expense, with legend `Gelir`/`Gider`. Never color-only — amounts/labels paired.
- States: loading (donut circle + bar block skeleton); empty `Henuz veri yok`.

## New component callouts
- `BalanceCard`, `TransactionRow` (+ swipe-to-dismiss background), `ExtendedFab`, `CategoryChip`, `SegmentedToggle`, `AddCategorySheet` (icon+color+preview), `DonutLegend`, `IncomeExpenseBars`.
