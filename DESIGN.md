# Pagroo — Design Document

## 1. Design System

### 1.1 Color Palette

Built on a **Slate** base with **Blue 500** as the primary accent. Material 3 `ColorScheme`.

| Token | Dark Mode | Light Mode | Usage |
|---|---|---|---|
| `primary` | `#3B82F6` | `#3B82F6` | Accent, buttons, active states, fare text |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text on primary |
| `secondary` | `#334155` | `#94A3B8` | Pause button, secondary elements |
| `surface` | `#1E293B` | `#FFFFFF` | Cards, HUD panel |
| `scaffold` | `#0F172A` | `#F8FAFC` | Page background |
| `error` | `#EF4444` | `#EF4444` | End Trip button, delete actions, signal loss |
| `onSurface` | `#FFFFFF` | `#0F172A` | Primary text |

### 1.2 Typography

- **Font Family**: Inter (system fallback)
- **Display Large**: 56px / w700 — Fare display (Time Meter)
- **Display Medium**: 32px / w600 — Fare display (Distance HUD)
- **Headline Medium**: 20px / w600 — Section headers
- **Body Large**: 16px / w400 — Body text
- **Label Large**: 14px / w500 — Captions, labels (Slate 400/500)

### 1.3 Shape & Elevation

- Cards: `borderRadius: 16`, elevation 0 (dark) / 2 (light)
- Buttons: `borderRadius: 16`
- HUD panel: `BorderRadius.vertical(top: Radius.circular(24))`

## 2. Screen Designs

### 2.1 Mode Selection Screen (Home)

```
┌────────────────────────────┐
│ ⚙️  Pagroo          📋    │  AppBar: Settings (left), History (right)
├────────────────────────────┤
│ 17 Sep 2026 • 16:54        │  Live clock (1s refresh)
├────────────────────────────┤
│ ℹ️ Current Rates:          │  Rates banner
│ Rp 4.000/km | Rp 500/min  │
├────────────────────────────┤
│ Select Tracking Mode       │
│                            │
│ ┌────────────────────────┐ │
│ │ 📍 Distance Meter      │ │  Mode card (blue circle icon)
│ │    Track fare by GPS   │ │  Rp/km → label
│ └────────────────────────┘ │
│ ┌────────────────────────┐ │
│ │ ⏱️ Time Meter          │ │  Mode card
│ │    Track fare by time  │ │  Rp/min → label
│ └────────────────────────┘ │
│                            │
├────────────────────────────┤  (Only when trip active)
│ 📍 Trip in Progress        │  Active Trip Banner
│ Tap to return to Distance  │  GestureDetector → navigate
└────────────────────────────┘
```

**States**:
- If Distance is active → Time card is disabled (dimmed, non-tappable).
- If Time is active → Distance card is disabled.
- Active mode card gets a blue border highlight.

### 2.2 Distance Tracking Screen

```
┌────────────────────────────┐
│ ←  Distance Meter          │  AppBar
├────────────────────────────┤
│                            │
│     [ Vector Tile Map ]    │  Full-screen FlutterMap
│     ────── polyline ───    │  Blue polyline + dot marker
│               ●            │
│                            │
│                      📍    │  My Location FAB (bottom-right)
│                            │
│ ╭──────────────────────────╮
│ │       Rp 12.000          │  HUD Panel (surface, rounded top)
│ │        3.21 km           │
│ │                          │
│ │  [■ END TRIP          ]  │  or [▶ START TRIP]
│ ╰──────────────────────────╯
└────────────────────────────┘
```

- Map auto-centers on the active city's coordinates (or last GPS position).
- If no MBTiles downloaded → blank canvas, polyline + marker still work.
- HUD uses `BoxShadow` for depth separation from the map.

### 2.3 Time Tracking Screen

```
┌────────────────────────────┐
│ ←  Time Meter              │
├────────────────────────────┤
│                            │
│          12:45             │  Monospace clock (displayLarge)
│                            │
│        Rp 6.375            │  Fare (headlineLarge, primary)
│                            │
│    Rate: Rp 500/min        │  Subtitle (70% opacity)
│                            │
│ ┌──────────────────┬──────┐│  Active state: Row (flex 3:1)
│ │ ■ END TRIP       │  ⏸   ││  End = error red, Pause = secondary
│ └──────────────────┴──────┘│  Paused: ▶ icon, orange bg
│                            │
│   — OR (before start) —    │
│                            │
│ ┌──────────────────────────┐│
│ │ ▶ START TRIP             ││  Full-width primary button
│ └──────────────────────────┘│
└────────────────────────────┘
```

### 2.4 Settings Screen

```
┌────────────────────────────┐
│ ←  Settings                │
├────────────────────────────┤
│ APP THEME                  │  Section label
│ ┌──────────────────────┐   │
│ │ Dark Mode        [●] │   │  SwitchListTile
│ └──────────────────────┘   │
│                            │
│ DISTANCE RATE              │
│ ┌──────────────────────┐   │
│ │ Rp  ________  /km   │   │  TextFormField
│ └──────────────────────┘   │
│ Quick set:                 │
│ [Rp 3.000][Rp 4.000]...   │  ChoiceChips
│                            │
│ TIME RATE                  │
│ ┌──────────────────────┐   │
│ │ Rp  ________  /min   │   │  TextFormField
│ └──────────────────────┘   │
│ Quick set:                 │
│ [Rp 300][Rp 500]...       │  ChoiceChips
│                            │
│ MAP MANAGEMENT             │
│ ┌──────────────────────┐   │
│ │ 🗺️ Jakarta   [Active]│   │  CityMapCard with status chip
│ │ Size: 24.5 MB        │   │
│ │    [Set Active][Delete]│  │
│ └──────────────────────┘   │
│ ┌──────────────────────┐   │
│ │ 🗺️ Surabaya  [✓ Done]│   │
│ │ Size: 38.1 MB        │   │
│ │         [Set Active]  │   │
│ └──────────────────────┘   │
│                            │
│ [💾 Save Settings       ]  │  Primary button
└────────────────────────────┘
```

**Map Card States**:
- **Active Map**: Blue 2px border, "Active Map" chip (primary color).
- **Downloaded**: Thin primary border, "Downloaded ✓" chip (green). Shows "Set Active" + "Delete" buttons.
- **Downloading**: Orange "Downloading…" chip + `LinearProgressIndicator`.
- **Not Available**: Grey chip. Shows "Download" `FilledButton`.
- **Coming Soon**: Grey text + chip, no action buttons.

### 2.5 History List Screen

```
┌────────────────────────────┐
│ ←  Trip History            │
├────────────────────────────┤
│  Total Trips    Total Earn │  Stats header (surfaceContainer)
│      12         Rp 156.000 │
├────────────────────────────┤
│ ┌──────────────────────┐   │
│ │ 📍 17 Sep 2026, 16:00│   │  TripCard → ListTile
│ │   3.21 km · Rp 4.000 │   │  Tap → TripDetailScreen
│ │              Rp 12.840│   │
│ └──────────────────────┘   │
│ ┌──────────────────────┐   │
│ │ ⏱️ 17 Sep 2026, 14:00│   │
│ │   45 min · Rp 500/min│   │
│ │              Rp 22.500│   │
│ └──────────────────────┘   │
└────────────────────────────┘
```

### 2.6 Trip Detail Screen

```
┌────────────────────────────┐
│ ←  Trip Details        🗑️  │  Delete button (red)
├────────────────────────────┤
│ ┌──────────────────────┐   │  Static map (250px, no interaction)
│ │ [Vector Map]         │   │  Polyline + start (green) / end (red) markers
│ └──────────────────────┘   │  (Distance trips only)
│                            │
│ Trip Summary               │
│ Start Time    17 Sep, 16:00│
│ ─────────────────────────  │
│ Total Distance     3.21 km │
│ ─────────────────────────  │
│ Total Earnings   Rp 12.840 │  (highlighted: bold + primary)
│                            │
│ ▼ Signal Loss Logs         │  ExpansionTile (collapsed by default)
│   • 12s lost → 0.15 km    │
│   • 8s lost → 0.09 km     │
└────────────────────────────┘
```

## 3. Interaction Patterns

### 3.1 Confirmation Dialogs

All destructive or state-changing actions use `AlertDialog`:
- **Start Trip**: "Begin tracking distance/time and fare?"
- **End Trip**: "Are you sure you want to stop tracking and finalize this trip?"
- **Delete Trip**: "This action cannot be undone."
- **Delete Map**: "You will need to re-download it."

### 3.2 Feedback

- `SnackBar` for: settings saved, map deleted.
- `CircularProgressIndicator` for: map loading, history loading.
- `LinearProgressIndicator` for: map download progress.

### 3.3 Theme Switching

Instant theme swap via `Consumer<SettingsProvider>` wrapping `MaterialApp`. `ThemeMode.dark`/`ThemeMode.light` based on persisted preference.

## 4. Number Formatting

All monetary values use the `intl` package:

```dart
NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
// 4000 → "Rp 4.000"
// 30000 → "Rp 30.000"

NumberFormat.decimalPattern('id')
// 12 → "12"
// 1500 → "1.500"
```

Applied globally via `formatCurrency()` and `formatNumber()` utility functions.
