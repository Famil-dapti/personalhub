# Set 2 — Wallet (Cuzdan) · Desktop / Web

File: `Cuzdan - Masaustu.html` · Frame 1280×800 · light + dark · **full read/write**.
Tokens: see `00 - Tokens.md`.

## Chrome
- **Left rail** 88px (`surfaceContainer`): `Cuzdan` (active, `secondaryContainer` pill), `Bildirim`, `Medya`, spacer, `Cikis`.
- **Top header** of content: title `Cuzdan`, search field (`Islem ara`), filled `Islem Ekle`.

## A. Home — two-column (380px / fluid)
- **Left column**: `BalanceCard` (same roles as phone) + inline **Hizli Ekle** card (segmented + amount + 3 quick category chips + `Kaydet`). Quick-add replaces the phone's pushed screen.
- **Right column**: `Islemler` header + grouped transaction list (day headers, same row anatomy), independent scroll. Gutter 24.

### States
- **Loading** — left balance skeleton + 6 shimmer rows.
- **Empty** — `Henuz islem yok` + tonal `Islem Ekle`.
- **Error** — `cloud_off` / `Bir sorun olustu` / `Tekrar dene`.

## B. Add transaction — right-side panel
- Not a new page: a 420px right panel slides over a dimmed list. Header `Islem Ekle` + close. Same fields as phone (segmented, amount with focused 2px `primary` outline, category chips, `Aciklama`, `Tarih`). Footer `Vazgec` / `Kaydet`. (Centered modal dialog is an acceptable alternative.)

## C. Categories — same two sections; **Add via dialog** (not bottom sheet) with identical icon/color/preview controls.

## D. Dashboard (Ozet) — charts side by side
- Two-column grid: **Donut** card (180px canvas + legend) and **Son 6 Ay** bars card (larger 300px canvas). Same legends and amount pairing.

## Desktop specifics
- Larger gutters (24), content max-widths, persistent rail. Two-pane / master-detail patterns where useful. Hover states on rows; visible scrollbars in scroll regions.

## New component callouts
- `NavRail`, `QuickAddCard`, `AddTransactionPanel` (right-docked), `DialogAddCategory`, plus all Set-1 components reused at desktop density.
