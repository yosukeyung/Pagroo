# Pagroo — Task History

Complete chronological record of all development tasks, from initial build through field-tested refinements.

## Phase 1: Foundation

### ✅ T-01 — Project Setup & Core Architecture
- Created Flutter project (`argo_app`).
- Established feature-based directory structure: `core/`, `features/tracking|settings|history|onboarding/`.
- Set up `MultiProvider` in `main.dart` with all 5 providers.
- Configured Material 3 dark/light themes (Slate palette, Blue 500 accent).
- Locked orientation to portrait-only.

### ✅ T-02 — SQLite Database Layer
- Implemented `DatabaseService` (singleton pattern).
- Created schema: `trips`, `signal_loss_logs`, `settings` tables.
- Full CRUD for trips, signal loss logs, and key-value settings.
- Database file: `argo_app_v2.db`.

### ✅ T-03 — GPS Location Service
- Created `LocationService` with permission check/request flow.
- Configured `Geolocator` high-accuracy stream (`distanceFilter: 5m`).
- Implemented accuracy threshold (`20m`) for signal quality filtering.

### ✅ T-04 — Distance Tracking Provider
- Built `DistanceProvider` with full GPS stream processing.
- Implemented Haversine distance accumulation between consecutive fixes.
- Created 4-state signal machine: `searching → locked → degraded → lost`.
- 5-second watchdog timer detects signal loss.
- On signal recovery: straight-line distance added + `SignalLossLog` created.
- Route stored as JSON array of `{lat, lng}` objects.

### ✅ T-05 — Time Tracking Provider
- Built `TimerProvider` with 1-second `Timer.periodic`.
- Fare calculated as `elapsed_minutes × pricePerMinute`.
- Trip saved on end with `trackingType: 'time'`.

### ✅ T-06 — Mode Selection Screen (Home)
- Implemented dual mode cards (Distance / Time) with mutual exclusion.
- Live clock display with 1-second refresh.
- Current rates banner showing Rp/km and Rp/min.
- Active Trip Banner at bottom for returning to in-progress trips.

### ✅ T-07 — Distance Tracking Screen
- Full-screen `FlutterMap` with offline vector tiles.
- Blue polyline route rendering from `DistanceProvider.coordinates`.
- Blue dot marker at current position.
- Bottom HUD panel with fare + distance display.
- Start/End Trip buttons with confirmation dialogs.
- "My Location" FAB for re-centering.

### ✅ T-08 — Time Tracking Screen
- Centered monospace clock display.
- Live fare and rate display.
- Start/End Trip with confirmation dialogs.

### ✅ T-09 — Settings Screen
- Distance rate (Rp/km) and Time rate (Rp/min) configuration.
- Quick-set `ChoiceChip` presets for common rates.
- Dark/Light theme toggle via `SwitchListTile`.
- Form validation (must be > 0).
- Save button persists to SQLite.

### ✅ T-10 — History Screens
- `HistoryListScreen`: Trip list sorted by date DESC, stats header (total trips + earnings).
- `TripDetailScreen`: Summary stats, static route map, start/end markers.
- Trip deletion with confirmation dialog.

## Phase 2: Offline Maps

### ✅ T-11 — MBTiles Integration
- Added `flutter_map`, `vector_map_tiles`, `vector_map_tiles_mbtiles`, `mbtiles` packages.
- Created `MapService` with `CityMap` model (id, displayName, fileName, centerLat, centerLng, downloadUrl).
- Implemented SQLite magic-byte validation for downloaded `.mbtiles` files.
- Created `assets/style.json` for OpenMapTiles vector tile theme.

### ✅ T-12 — SQLite Native Library Fix
- Added `sqlite3_flutter_libs` to bundle `libsqlite3.so` for Android.
- Resolved `dlopen failed` crash on physical devices.

### ✅ T-13 — Map Download System
- Built `DownloadProvider` with HTTP streaming download + progress tracking.
- Per-city state management (downloaded, downloading, progress, error).
- Post-download validation (SQLite header check).
- Temp file pattern (`.tmp` → rename on success).
- Download, retry, and delete functionality.

### ✅ T-14 — Two-City Map Support
- Configured Jakarta and Surabaya & Sidoarjo as download options.
- URLs pointing to Internet Archive hosted MBTiles files.

## Phase 3: Android Services

### ✅ T-15 — Foreground Service
- Integrated `flutter_foreground_task` v11.
- `ForegroundServiceManager`: init, start (distance/time), stop, update notification.
- `MyTaskHandler` isolate with `@pragma('vm:entry-point')`.
- AndroidManifest: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS`.
- Persistent notification shows live fare during trips.

### ✅ T-16 — Wakelock
- Added `wakelock_plus` to prevent screen sleep during active tracking.
- Enabled in `initState`, disabled in `dispose` of both tracking screens.

## Phase 4: Field Testing & Polish

### ✅ T-17 — Distance Calculation Fix
- Fixed frozen distance/fare display: location stream was updating map points but not calculating distance delta.
- Ensured `Geolocator.distanceBetween` (Haversine) is called between consecutive positions.
- Added `notifyListeners()` after every distance + fare update.

### ✅ T-18 — UI Cleanup (Post-Field Test)
- Removed red warning triangle icon from trip history list items.
- Wrapped Signal Loss Transparency Logs in collapsible `ExpansionTile` (collapsed by default).

### ✅ T-19 — GPS Warning Banner Removal
- Completely removed the red "GPS Signal Lost" banner from `DistanceTrackingScreen`.
- Signal loss is now handled silently in the background (watchdog + recovery logging).

### ✅ T-20 — Indonesian Currency Formatting
- Added `intl` package (^0.19.0).
- Created `currency_formatter.dart` with `formatCurrency()` (Rp with dot separator) and `formatNumber()`.
- Applied formatting globally: tracking HUDs, history list, trip details, settings chips.
- Unit tests for formatting in `test/currency_formatter_test.dart`.

### ✅ T-21 — Trip State Reset Fix
- Fixed bug: ending a trip didn't clear polyline/distance/fare for the next trip.
- Added `resetTripState()` to both `DistanceProvider` and `TimerProvider`.
- Called after `endTrip()` and in `initState()` when no trip is active.
- Unit tests in `test/trip_reset_test.dart`.

### ✅ T-22 — Dynamic Map Loading Fix
- Fixed blank map when Surabaya downloaded but Jakarta wasn't.
- Removed hardcoded `mapFileName` alias (always pointed to Jakarta).
- Added `centerLat`/`centerLng` to `CityMap` for per-city map centering.
- `getActiveCity()` now auto-detects the first valid downloaded map.

### ✅ T-23 — Active Map State Management
- Added `activeMapFileName` to `SettingsProvider` (persisted to SQLite).
- `getActiveCity(selectedFileName)` prioritizes the explicitly selected map.
- `openTileStore(fileName)` validates the file exists before opening.
- "Set Active" button + "Active Map" badge in `SettingsScreen` map cards.
- `DistanceTrackingScreen` reads `activeMapFileName` on init.

### ✅ T-24 — Onboarding Screen Removal
- Deleted `OnboardingScreen` (was the initial map download gate).
- App now boots directly into `ModeSelectionScreen`.
- All map management (download/delete/set active) centralized in `SettingsScreen`.

### ✅ T-25 — Time Meter Pause/Resume
- Added `isPaused` state, `_accumulatedDuration`, `_resumeTime` to `TimerProvider`.
- `pauseTracking()`: freezes accumulated duration, skips timer notifications.
- `resumeTracking()`: resets resume checkpoint, re-enables notifications.
- UI: Active state shows Row with End Trip (flex: 3) + Pause/Resume icon button (flex: 1).
- Pause button: `Icons.pause_rounded` (secondary color). Resume button: `Icons.play_arrow_rounded` (orange).

## Test Coverage

| Test File | Coverage |
|---|---|
| `currency_formatter_test.dart` | `formatCurrency()`, `formatNumber()` |
| `trip_reset_test.dart` | `DistanceProvider.resetTripState()`, `TimerProvider.resetTripState()` |
| `widget_test.dart` | Default Flutter smoke test |
