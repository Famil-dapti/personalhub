# Set 5 — Media Cleaner (Medya) · Phone

File: `Medya - Telefon.html` · 380×800 · light + dark · **interactive (swipe deck)**.
Full: scan + swipe-sort + batch delete. Tokens: see `00 - Tokens.md`.

## Chrome
App bar `Medya` + `delete_sweep` (trash count). Bottom nav `Medya` active.

## A. Swipe deck
- **Filter** segmented `Tumu` / `Fotograflar` / `Videolar`.
- **Meter row** — `Ilerleme` `120 / 540` (tabular) + `Bosaltilacak (tahmini)` running `~1,2 GB` (income green). Thin progress `linebar` under it.
- **Card stack** (Tinder-style) — top card draggable. Photo/video fills card; bottom gradient overlay; meta = place + `tarih · boyut · tur`; video badge top-left (`videocam` + duration).
  - **Swipe right (>100px) = keep**, **swipe left = delete** (to trash queue, not deleted). `SAKLA` / `SIL` rotated stamps fade in with drag.
  - Under-card buttons: `del` (close, `errorContainer`), `undo` (center), `keep` (favorite, income tint). 48–60px targets.
  - **Undo** restores the last decision (also offered in snackbar).
- End-of-deck → `Tumu incelendi`.

## B. Trash review / batch confirm
- Warning card (`errorContainer`): `N dosya kalici olarak silinecek (~Y GB). Geri alinamaz.`
- 3-col **thumbnail grid**; each tile has per-item un-mark (×) + size chip + video marker.
- Footer danger button `N dosyayi sil · Y GB` → confirm **dialog** → success snackbar `X dosya silindi, ~Y GB bosaldi`.

## C. Filters & stats
- Stats card: `Taranan`, `Fotograf`, `Video`. Session summary card (`bosaltilan` GB, kept vs deleted) + completion empty-style `Tebrikler!`.

## States
- **Scanning** — spinner + `Medya taraniyor` + `312 / 540` + progress bar.
- **Empty** — `photo_library` / `Taranacak medya yok`.
- **Permission not granted** — `no_photography` / `Medya erisimi yok` / `Izin ver`.

## New component callouts
- `SwipeDeck` + `MediaCard` (+ keep/del stamps), `DeckActionBar`, `FreedSpaceMeter`, `TrashGrid`, `ConfirmDeleteDialog`, `SessionStats`.
- **Custom painter flag:** the swipe stack + drag physics is custom (Flutter: `flutter_card_swiper` or gesture-driven `Transform`). Everything else is standard M3.
