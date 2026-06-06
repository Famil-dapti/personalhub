# PersonalHub — Design Tokens (shared across all 6 sets)

> Material 3, Inter typeface, single currency **AZN** (`1.234,56 AZN`), ASCII Turkish copy.
> Implements 1:1 in Flutter Material 3. Seed proposal: **deep teal/green** (money-forward),
> replacing the original `#6750A4` purple.

## Color scheme (M3 roles)

| Role | Light | Dark |
|---|---|---|
| `primary` | `#0B6E4F` | `#73DBAE` |
| `onPrimary` | `#FFFFFF` | `#003824` |
| `primaryContainer` | `#9FF2CC` | `#005138` |
| `onPrimaryContainer` | `#00210F` | `#8FF7CE` |
| `secondary` | `#4C6358` | `#B2CCBE` |
| `secondaryContainer` | `#CEE9DA` | `#344B40` |
| `onSecondaryContainer` | `#092017` | `#CEE9DA` |
| `tertiary` | `#3D6373` | `#A4CDDF` |
| `tertiaryContainer` | `#C0E9FB` | `#244C5B` |
| `surface` | `#F6FBF6` | `#0F140F` |
| `surfaceContainerLowest` | `#FFFFFF` | `#0A0F0A` |
| `surfaceContainerLow` | `#F0F6F0` | `#171D18` |
| `surfaceContainer` | `#EAF1EB` | `#1B211C` |
| `surfaceContainerHigh` | `#E5EBE5` | `#252B26` |
| `surfaceContainerHighest` | `#DFE5E0` | `#303631` |
| `onSurface` | `#171D19` | `#DEE4DF` |
| `onSurfaceVariant` | `#404943` | `#BFC9C0` |
| `outline` | `#707972` | `#8A938B` |
| `outlineVariant` | `#C0C9C0` | `#404943` |
| `error` | `#BA1A1A` | `#FFB4AB` |
| `errorContainer` | `#FFDAD6` | `#93000A` |
| `onErrorContainer` | `#410002` | `#FFDAD6` |

**Semantic money colors** (consistent on balance card, rows, charts):
- income / `Gelir` = `#2E7D52` (light) · `#7CDBA6` (dark)
- expense / `Gider` = `error` red

## Typography (Material 3 roles, Inter)

| Role | Size / line / weight | Use |
|---|---|---|
| `headlineMedium` | 28 / 34 / 600 | balance amount, dashboard hero |
| `headlineSmall` | 24 / 30 / 600 | empty-state titles, detail titles |
| `titleLarge` | 20 / 26 / 600 | app-bar titles |
| `titleMedium` | 16 / 22 / 600 | card section headers |
| `titleSmall` | 14 / 20 / 600 | row titles, legend values |
| `labelLarge` | 14 / 18 / 600 | buttons, field labels, day headers |
| `labelMedium` | 12 / 16 / 600 | chips, eyebrows |
| `bodyLarge` | 16 / 24 / 400 | amounts in rows, detail body |
| `bodyMedium` | 14 / 20 / 400 | secondary text |
| `bodySmall` | 12 / 16 / 400 | timestamps, hints |

All amounts use `font-variant-numeric: tabular-nums`.

## Spacing scale
`4 / 8 / 12 / 16 / 20 / 24 / 32`. Phone screen edge padding **16**; chips gap **8**; form field
gap **16**. Desktop gutters **24–32**, content max-widths applied.

## Radii & elevation
- Radii: chips 10–12, fields 12, cards 18, sheets/dialog 24–28, balance card 24, avatars/FAB full/18.
- Elevation: `elev1` rows/cards, `elev2` frames, `elev3` FAB/sheet/dialog/snackbar.

## Shared reusable components
- **Skeleton loader** — `surfaceContainer → high` shimmer, shaped like real content (avatar + 2 lines + trailing).
- **Empty state** — centered 84px circular `surfaceContainerHigh` icon (`outline`), title (`headlineSmall`/`titleLarge`), one-line `onSurfaceVariant` hint, optional tonal action.
- **Snackbar** — floating, inverse-surface; success = `check_circle`; error = `errorContainer`.
- **Navigation** — phone bottom nav (3 dests, active pill = `primaryContainer`); desktop 88px left rail (active pill = `secondaryContainer`).

> All icons map to **Material Symbols** (Rounded). No bespoke iconography.
> No custom painters required except the **donut/pie** and **bar chart** on the dashboard
> (Flutter: `fl_chart` or a light `CustomPainter`) — flagged per the brief.
