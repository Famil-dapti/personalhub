# Set 6 — Media Cleaner (Medya) · Desktop / Web

File: `Medya - Masaustu.html` · 1280×800 · light + dark · **companion (capture not possible)**.
A browser cannot read device media, so this is a dashboard, **not** the swipe tool.
Tokens: see `00 - Tokens.md`.

## Layout
- **Left rail** 88px, `Medya` active. Header `Medya Temizligi` + `Senklendi · 2 dk once` banner.

### Hero (not a dead "unsupported" page)
- Full-width `primary` gradient hero: eyebrow `COMPANION`, `headlineMedium` **Medya temizligi telefonda calisir**, explanation, white `Telefonda ac` button, and a **QR placeholder** to open on phone.

### Stats (synced from `media_decisions`)
- 4 stat cards: `Incelenen dosya`, `Saklanan` (income green), `Silinen` (expense red), `Bosaltilan alan`.

### History & chart
- **Bosaltilan alan — son 6 ay** area/bar chart (GB per month, `primary` gradient bars, value labels).
- **Son oturumlar** list — date, `N dosya incelendi`, freed GB (income green).

## States
- **Syncing** — hero + stat + chart skeletons.
- **No data** — `cloud_sync` / `Henuz veri yok` / `Telefonda ilk temizligi yaptiginizda…` + `Telefonda ac`.

## Companion rules
- Make clear the action happens on the phone, in full brand styling (no error page).
- Read-only history/stats only; optional QR / deep-link hint to continue on phone.

## New component callouts
- `CompanionHero` (+ `QrPlaceholder`), `StatCardRow`, `FreedSpaceChart`, `SessionHistoryList`.
- **Custom painter flag:** freed-space chart (Flutter: `fl_chart`).
