# PersonalHub — Claude Design Brief

> **Purpose of this document.** It is a self-contained brief handed to **Claude Design** to
> produce UI mockups. It describes the whole product, the visual system, every screen, and the
> exact deliverables. Read it top to bottom; everything you need to design is here. The output is
> returned to the engineering side and implemented in Flutter (Material 3), so designs must be
> realizable with standard Material 3 components.

---

## 0. What we need from you (deliverables)

Produce **6 design sets** — one per (app x form factor):

| # | App | Form factor | Notes |
|---|-----|-------------|-------|
| 1 | Wallet | **Phone** (compact, ~390x844) | Primary daily-use surface |
| 2 | Wallet | **Desktop / Web** (~1280x800) | Same features, wider layout |
| 3 | Notification Archiver | **Phone** | Full: live capture + browse + search |
| 4 | Notification Archiver | **Desktop / Web** | Read-only archive browse + search |
| 5 | Media Cleaner | **Phone** | Full: swipe-to-sort + batch delete |
| 6 | Media Cleaner | **Desktop / Web** | Companion view (capture not possible — see §6) |

For **each** set, deliver:
1. **High-fidelity mockups** of every screen listed for that app (light theme **and** dark theme).
2. A short **spec per screen**: layout structure, spacing (use our scale, §3.2), color roles
   (use Material 3 color-scheme role names, §3.3), typography roles (§3.4), and the
   **loading / empty / error** state for any data-driven screen.
3. **Component callouts** for anything new (a card, a chip, a list row) so it can be built once
   and reused.

**Preferred output format:** annotated mockup images **plus** a per-screen written spec (Markdown).
Self-contained HTML/CSS mockups are also welcome since they implement cleanly into Flutter widgets.
Avoid bespoke iconography — map to **Material Symbols** names where possible.

---

## 1. Product overview

PersonalHub is a personal "app-in-app" suite for one user across many devices (two Android phones
+ computer/browser). All data syncs through Supabase. A single shell hosts **three mini-apps**:

1. **Wallet** — manual + (later) auto-detected income/expense tracking. *Built (v1).*
2. **Notification Archiver** — captures every Android notification; later auto-detects bank
   transaction notifications. *Not built yet — design ahead.*
3. **Media Cleaner** — scans device photos/videos, Tinder-style swipe to keep or delete.
   *Not built yet — design ahead.*

Single user, personal scale. No onboarding funnels, no marketing surfaces, no multi-tenant
concerns. Optimize for **speed of daily use, clarity, and low cognitive load.**

---

## 2. Platform model & per-app constraints

The same Flutter codebase ships to **Android, iOS, and Web**. Capabilities differ by platform, and
this **directly shapes the desktop designs** — do not just stretch the phone layout.

| App | Phone (Android primary) | Desktop / Web |
|-----|--------------------------|----------------|
| **Wallet** | Full read/write | **Full read/write** — identical features, wider layout |
| **Notification Archiver** | Full: captures notifications in background + browse/search | **Read-only** archive: browse + search + filter. No capture (browser/desktop cannot intercept Android notifications) |
| **Media Cleaner** | Full: scans device media, swipe-sort, delete | **Not functional** — a browser cannot access device files. Design a **companion screen**: cleanup history/stats + "run this on your phone" guidance (see §6.2) |

**Navigation chrome (shared):**
- **Phone:** bottom navigation bar, 3 destinations — `Cuzdan` (Wallet), `Bildirimler`
  (Notifications), `Medya` (Media). Each app may push sub-screens on top.
- **Desktop/Web:** a **left navigation rail / sidebar** with the same 3 destinations; content area
  to the right. Consider a persistent two-pane layout where it helps (list + detail).

---

## 3. Visual system

The product runs **Material 3** with the **Inter** typeface today. You may refine the palette and
spacing, but stay within Material 3 primitives so it implements 1:1. State the final tokens in your
spec.

### 3.1 Brand & tone
- Clean, calm, modern. Generous whitespace. Content-first.
- Personal-finance trust signals without feeling "corporate banking."
- Currency is **AZN** (Azerbaijani manat), single currency for now. Money format: `1.234,56 AZN`
  (Turkish grouping: `.` thousands, `,` decimals).

### 3.2 Spacing scale (tokens already in code — reuse these)
`4 / 8 / 12 / 16 / 20 / 24 / 32`. Screen edge padding is **16** on phone. Use **8** between chips,
**16** between form fields. Desktop may use larger gutters (24–32) and max content widths.

### 3.3 Color (Material 3 color scheme)
- Current seed: **`#6750A4`** (purple). You may propose a different seed, but deliver a full M3
  scheme (light + dark) and reference roles by name: `primary`, `onPrimary`, `surface`,
  `surfaceContainerHighest`, `onSurfaceVariant`, `outline`, `error`, `errorContainer`,
  `onErrorContainer`, etc.
- **Semantic money colors:** income = green; expense = `error` red. Keep these consistent across
  Wallet balance card, transaction rows, and charts.
- **Dark theme is required** for every screen — it is shipped, not optional.

### 3.4 Typography (Material 3 roles, Inter)
Use role names so they map directly: `headlineMedium` (balance), `titleLarge` / `titleMedium` /
`titleSmall` (section headers), `labelLarge` (field labels, day headers), `bodyLarge` (amounts in
rows), `bodyMedium` / `bodySmall` (secondary text).

### 3.5 Language / copy rules (important)
- All UI text is **Turkish**, but the app currently renders **ASCII-only Turkish (no diacritics)** —
  e.g. `Cuzdan`, `Ozet`, `Henuz islem yok`. **Match this in mockups** (diacritic-correct Turkish is
  a future i18n task, out of scope here). A copy glossary is in §7.
- Keep copy short and direct.

### 3.6 Reusable components already defined (design refined versions of these)
- **Skeleton loaders** — pulsing grey blocks shaped like the real content (avatar + lines + trailing).
- **Empty state** — centered icon (56px, `outline` color) + title + one-line hint + optional action.
- **Snackbar feedback** — floating; success (check icon) and error (error-container colored).

---

## 4. App 1 — Wallet (BUILT; redesign/polish)

Cross-platform, full read/write everywhere. This app already exists; you are elevating its visual
quality and producing the phone + desktop layouts.

### 4.1 Screens

**A. Wallet home (`Cuzdan`)**
- **Balance card** (top): label `Bakiye`, large balance amount, and two summary items
  `Bu ay gelir` (month income, green, down-arrow) and `Bu ay gider` (month expense, red, up-arrow).
- **Transaction list**, grouped by day with headers: `Bugun`, `Dun`, then dated headers
  (`6 Haziran 2025`). Newest first.
  - **Row:** leading category avatar (colored icon on tinted circle), category name as title,
    `description . date` as subtitle (1 line, ellipsis), signed amount on the right
    (`+1.000,00 AZN` green / `-50,00 AZN` red).
  - **Delete:** swipe row right-to-left reveals a red delete background; also long-press. Both
    trigger a confirm dialog, then a success snackbar.
- **FAB:** extended, `Islem Ekle` (add transaction).
- **App bar actions:** `Ozet` (chart icon -> dashboard), `Kategoriler` (category icon), `Cikis` (logout).
- **States:** loading = skeleton (balance card + ~4 rows); empty = friendly empty state
  (`Henuz islem yok`, hint to add first one); error = `Bir sorun olustu` + message.
- **Desktop:** consider a two-column layout — left: balance + summary widgets / quick add; right:
  the grouped transaction list. Or a master-detail with a side "add transaction" panel instead of a
  pushed screen.

**B. Add transaction (`Islem Ekle`)**
- Segmented toggle `Gider` / `Gelir` (expense / income).
- Amount field (numeric, suffix `AZN`).
- **Category picker:** wrap of choice chips, each with a colored category icon + name. Changing the
  segment swaps the category set.
- Description field (optional, multi-line).
- Date row (opens date picker).
- Save button (`Kaydet`) with inline spinner while saving; success -> snackbar + close.
- **Desktop:** present as a centered modal/dialog or a right-side panel, not a full new page.

**C. Manage categories (`Kategoriler`)**
- Two sections: `Gider Kategorileri` and `Gelir Kategorileri`.
- **Row:** category avatar + name; system presets show `Hazir kategori` and are not deletable;
  custom ones show a delete button (confirm dialog -> snackbar).
- Empty section shows `Henuz kategori yok`.
- **FAB / Add:** `Kategori Ekle` opens a sheet (phone: bottom sheet with drag handle; desktop:
  dialog) containing: kind toggle, name field, **icon picker** (chips), **color picker** (color
  circles, 8-swatch palette), and a **live preview chip** of the category being created.

**D. Dashboard (`Ozet`)**
- **Pie/donut:** `Bu Ay Gider Dagilimi` — current-month expenses by category, with a legend list
  (colored dot + category name + amount).
- **Bar chart:** `Son 6 Ay` — income vs expense per month (6 months). Include a **legend**
  (`Gelir` green / `Gider` red).
- **States:** loading = skeleton (donut circle + bar block); empty = `Henuz veri yok` + hint.
- **Desktop:** place the two charts side by side; larger chart canvas.

### 4.2 Category visuals
Categories carry a Material icon id + hex color. Icon set in use: restaurant, shopping_cart,
directions_car, receipt_long, movie, medical_services, shopping_bag, home, payments, attach_money,
card_giftcard, more_horiz. Palette swatches: `#FF7043 #42A5F5 #66BB6A #AB47BC #EF5350 #26A69A
#FFCA28 #5C6BC0`.

---

## 5. App 2 — Notification Archiver (NOT BUILT; design ahead)

Captures every notification on the Android phone (via a background service) and stores it in
Supabase. Later, bank/payment notifications are parsed into Wallet transaction drafts.

### 5.1 Data shown per notification
App name + app icon/package, title, body, posted time, and an `is_transaction` flag (a notification
detected as a likely money movement). Full raw payload exists but is not shown in the list.

### 5.2 Screens

**A. Archive list (`Bildirimler`)** — phone & desktop
- Scrollable list of notification cards/rows: leading app icon, app name + relative time, title
  (bold), body (1–2 lines, ellipsis). A small badge/marker when `is_transaction` is true (e.g. a
  `payments` icon or an accent dot) with an action hint like `Islem olustur` (create transaction).
- **Search bar** (search title/body/app).
- **Filters:** by app (chips or dropdown) and by date (today / this week / range).
- **Grouping:** by day, like Wallet (`Bugun` / `Dun` / dated).
- **States:** loading skeleton; empty `Henuz bildirim yok`; error.

**B. Notification detail** — phone (pushed) / desktop (right pane)
- Full title + body, app name, exact timestamp, and — if `is_transaction` — a highlighted
  **"create transaction" affordance** that pre-fills amount/category for confirmation.

**C. Permission / setup state (phone only)**
- A first-run / not-yet-granted screen explaining that PersonalHub needs **notification access**,
  with a CTA to open Android settings. Design the "access not granted" empty state too.

### 5.3 Desktop specifics (read-only)
- No capture, no permission flow. Master-detail: notification list on the left, detail on the right.
- Make it clear capture happens on the phone (a subtle banner: capture runs on your Android device).
- Same search + filters; browsing/exporting only.

---

## 6. App 3 — Media Cleaner (NOT BUILT; design ahead)

Scans the device's photos/videos and lets the user quickly decide keep vs delete. Mobile-only by
nature (filesystem access).

### 6.1 Phone screens (full feature)

**A. Swipe deck (`Medya`)**
- A **card stack** showing one photo/video at a time (Tinder-style).
- **Swipe right = keep**, **swipe left = delete** (moves to a trash queue, not deleted yet).
- Visible affordances: keep/delete buttons under the card for non-swipe use; an **undo** for the
  last action.
- **Top bar:** progress (`120 / 540`), and a **filter** (`Fotograflar` / `Videolar` / `Tumu`).
- **Freed-space estimate** running total (`~1,2 GB`).

**B. Trash review / batch confirm**
- Grid of items marked for deletion with thumbnails + total reclaimable space.
- **Confirm delete** (`Sil`) with a clear, irreversible-action warning; per-item un-mark.
- Success summary (`X dosya silindi, ~Y GB bosaldi`).

**C. Filters & stats**
- Filter photos / videos / all. Simple stats: scanned count, kept, deleted, space freed.
- **States:** scanning (progress/skeleton), empty (`Taranacak medya yok`), permission-not-granted.

### 6.2 Desktop / Web (companion — capture not possible)
A browser cannot read device media, so the desktop build is a **companion / dashboard**, not the
swipe tool. Design:
- A clear hero stating this runs on the phone (`Medya temizligi telefonda calisir`), with the same
  brand styling — not a dead "not supported" page.
- **Cleanup history & stats** synced from the phone (from `media_decisions`): total files reviewed,
  kept vs deleted, estimated space freed over time (a simple chart), recent sessions.
- Optional QR / hint to open on the phone.

---

## 7. Turkish copy glossary (ASCII, match the app)

| Context | Turkish (ASCII) |
|---|---|
| Wallet tab / title | Cuzdan |
| Notifications tab | Bildirimler |
| Media tab | Medya |
| Balance | Bakiye |
| Month income / expense | Bu ay gelir / Bu ay gider |
| Add transaction | Islem Ekle |
| Expense / Income | Gider / Gelir |
| Amount | Tutar |
| Category | Kategori |
| Description (optional) | Aciklama (istege bagli) |
| Date | Tarih |
| Save | Kaydet |
| Categories | Kategoriler |
| Expense/Income categories | Gider Kategorileri / Gelir Kategorileri |
| System category | Hazir kategori |
| Add category | Kategori Ekle |
| New category / name | Yeni Kategori / Kategori adi |
| Icon / Color | Ikon / Renk |
| Summary (dashboard) | Ozet |
| This month expense breakdown | Bu Ay Gider Dagilimi |
| Last 6 months | Son 6 Ay |
| Today / Yesterday | Bugun / Dun |
| Delete / Cancel | Sil / Vazgec |
| Logout | Cikis |
| Empty: no transactions | Henuz islem yok |
| Empty: no data | Henuz veri yok |
| Empty: no notifications | Henuz bildirim yok |
| Create transaction (from notif) | Islem olustur |
| Photos / Videos / All | Fotograflar / Videolar / Tumu |
| Generic error | Bir sorun olustu |
| Success: added / deleted | eklendi / silindi |

---

## 8. Accessibility & quality bar
- Sufficient contrast in both themes (WCAG AA for text).
- Tap targets >= 48px on phone.
- Every data screen designs all three of: **loading (skeleton), empty, error**.
- Charts must be legible with a legend; never rely on color alone (pair with labels/amounts).
- Keep it implementable in Flutter Material 3 — flag anything that would need a custom painter.

---

## 9. Summary checklist for your output
- [ ] 6 sets (3 apps x phone/desktop), light **and** dark.
- [ ] Every screen in §4–§6 covered, including loading/empty/error states.
- [ ] Shared chrome: phone bottom nav + desktop side rail.
- [ ] Final design tokens stated (color scheme, type scale, spacing).
- [ ] New components called out for reuse.
- [ ] Turkish copy per §7 (ASCII).
