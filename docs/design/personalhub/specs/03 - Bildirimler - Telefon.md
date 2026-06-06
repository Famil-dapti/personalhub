# Set 3 — Notification Archiver (Bildirimler) · Phone

File: `Bildirimler - Telefon.html` · 380×800 · light + dark · **interactive**.
Full: background capture + browse + search. Tokens: see `00 - Tokens.md`.

## Chrome
App bar `Bildirimler` + overflow. Bottom nav `Bildirimler` active.

## A. Archive list
- **Search bar** — pill `surfaceContainerHigh`, `Baslik, metin veya uygulama ara`.
- **Filter chips** — horizontal scroll: `Tumu`, `Islemler` (payments), per-app (`Kapital`, `Birbank`, `WhatsApp`…). Selected = `primaryContainer`.
- **Grouping by day** (`Bugun`/`Dun`/dated).
- **Notification card** — leading 40px rounded app icon (brand color), header `app adi · relatif zaman`, title (`titleSmall`, bold), body 2-line ellipsis (`bodySmall`).
  - When `is_transaction`: a `Islem` badge (`primaryContainer`, payments icon) + inline `Islem olustur` text button.
- Empty filter result → inline `Sonuc yok`.

## B. Notification detail (pushed)
- App identity row, full title (`headlineSmall`), full body (`bodyLarge`).
- If `is_transaction`: highlighted `primaryContainer` card — `Islem olarak algilandi`, pre-filled amount + category, `Cuzdana ekle` filled button (confirmation affordance).
- **Ham veri** block (monospace package / posted / is_transaction) — full payload exists but only summarized in list.

## C. Permission / setup (phone only)
- First-run: 96px `primaryContainer` rounded icon (`notifications_active`), `Bildirim erisimi gerekli`, explanation, privacy reassurance card, `Ayarlari ac` (filled) + `Daha sonra` (text).
- **Access-not-granted empty state**: `notifications_paused`, `Erisim verilmedi`, `Ayarlari ac`.

## States
- **Loading** — search skeleton + 6 three-line shimmer rows.
- **Empty** — `notifications_off` / `Henuz bildirim yok`.
- **Error** — `cloud_off` / `Bir sorun olustu` / `Tekrar dene`.

## New component callouts
- `NotificationCard` (+ transaction badge + `Islem olustur` action), `FilterChipRow`, `SearchField`, `NotificationDetail` (+ `DetectedTransactionCard`), `PermissionScreen`, `RawPayloadBlock`.
