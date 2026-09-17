# Pagroo — Product Requirements Document (PRD)

## 1. Overview

**Pagroo** is an Android fare-tracking app for Indonesian ride-hailing drivers ("ojol").  
It calculates and displays real-time fare earnings based on either **GPS distance** or **elapsed time**, using configurable per-km and per-minute rates set by the driver.

The app runs fully offline with locally-stored vector maps (MBTiles) and persists all trip history in a local SQLite database.

## 2. Target User

Indonesian motorcycle taxi (ojek online) drivers who need a transparent, independent fare meter separate from their platform's app.

## 3. Core Features

### 3.1 Dual Tracking Modes

| Mode | Metric | Rate Unit | GPS Required |
|---|---|---|---|
| **Distance Meter** | Cumulative km (Haversine) | Rp/km | Yes |
| **Time Meter** | Elapsed minutes | Rp/min | No |

- Only one mode can be active at a time. The inactive mode card is visually disabled.
- An **Active Trip Banner** at the bottom of the home screen lets the driver return to an in-progress trip.

### 3.2 Distance Meter

- Real-time GPS tracking via `Geolocator` high-accuracy stream (`distanceFilter: 5m`).
- Blue polyline route drawn on an offline vector map (`flutter_map` + MBTiles).
- Blue dot marker follows the driver's current position.
- Bottom HUD panel: live fare (Rp) and distance (km).
- Signal Loss Handling: 5-second watchdog detects GPS drops; upon recovery, straight-line (Haversine) distance is added and a `SignalLossLog` is recorded.
- "My Location" FAB re-centers the map on the current GPS fix.

### 3.3 Time Meter

- 1-second `Timer.periodic` drives the clock and fare display.
- **Pause/Resume**: While a trip is active, the driver can pause the timer (stops fare accumulation) and resume it. The UI shows a split button row — End Trip (flex: 3) + Pause/Resume icon (flex: 1).
- Accumulated duration is precisely tracked across pause/resume cycles using `_accumulatedDuration` and `_resumeTime`.

### 3.4 Trip History

- All completed trips (distance and time) are saved to local SQLite.
- **History List**: Shows total trips, total earnings, per-trip cards with date/metric/earnings.
- **Trip Detail**: Summary stats, static route map replay (distance trips), and collapsible Signal Loss Transparency Logs (`ExpansionTile`).
- Trips can be individually deleted with confirmation.

### 3.5 Offline Vector Maps

- **Supported Regions**: Jakarta, Surabaya & Sidoarjo.
- MBTiles files hosted on Internet Archive, downloaded via HTTP with progress tracking.
- SQLite magic-byte validation ensures file integrity post-download.
- **Active Map Selection**: The driver explicitly sets which downloaded map to use via `SettingsProvider.setActiveMap()`. The active map is persisted across app restarts.
- Map is optional — the Distance Meter works on a blank canvas if no map is downloaded.

### 3.6 Settings

- **Distance Rate** (Rp/km): Configurable with quick-set chips (3000–7500).
- **Time Rate** (Rp/min): Configurable with quick-set chips (300–1000).
- **Dark/Light Theme Toggle**.
- **Map Management**: Download, Set Active, Delete per city. Shows file size and download progress.

### 3.7 Foreground Service

- Android Foreground Service (`flutter_foreground_task`) keeps the app alive during trips.
- Persistent notification displays live fare in the notification shade.
- Wakelock prevents the screen from sleeping during active tracking.

### 3.8 Localization & Formatting

- All currency displayed in Indonesian Rupiah with dot thousand separators: `Rp 4.000` (via `intl` package, `id_ID` locale).

## 4. Non-Functional Requirements

- **Offline-First**: Zero network dependency during tracking. Internet only needed for map downloads.
- **Portrait Lock**: Orientation locked to prevent accidental rotations mid-trip.
- **State Reset**: Trip data (polyline, distance, fare) is fully cleared after each trip ends and before a new trip starts.
- **Graceful Degradation**: Missing map files result in a blank canvas, not a crash.

## 5. Out of Scope (v1)

- Multi-language support (Indonesian UI strings).
- Cloud sync / backup.
- Earnings analytics and charts.
- iOS build.