# Set 4 — Notification Archiver (Bildirimler) · Desktop / Web

File: `Bildirimler - Masaustu.html` · 1280×800 · light + dark · **read-only archive**.
No capture, no permission flow (browser/desktop cannot intercept Android notifications).
Tokens: see `00 - Tokens.md`.

## Layout — master-detail
- **Left rail** 88px, `Bildirim` active.
- **List pane** 420px: header `Bildirimler`, search field, filter chips (`Tumu`/`Islemler`/per-app), day-grouped rows. Selected row = `secondaryContainer`. Each row: app icon + header + title + 1-line body; transaction rows carry the `payments` badge.
- **Detail pane** (fluid): top **capture banner** `tertiaryContainer` — `Yakalama Android telefonunuzda calisir. Bu gorunum salt-okunurdur.` Then app identity, full title/body, detected-transaction summary card (read-only — no `Cuzdana ekle` button here), and `Ham veri` block (adds parsed amount/category fields).

## Read-only specifics
- Browsing / filtering / exporting only — no capture, no create-transaction action on desktop.
- Same search + filters as phone. Subtle persistent banner makes the phone-capture model clear.

## States
- **Loading** — list shimmer rows + empty detail skeleton line.
- **Empty** — `notifications_off` / `Henuz bildirim yok` / hint that capture runs on phone.
- **Error** — `cloud_off` / `Bir sorun olustu` / `Tekrar dene`.

## New component callouts
- `NotificationListPane`, `NotificationDetailPane`, `CaptureRunsOnPhoneBanner`, `ReadOnlyDetectedTransactionCard`, `RawPayloadBlock` (desktop variant).
