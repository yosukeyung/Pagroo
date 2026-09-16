# Architecture Document
**Project Name:** Custom Offline Taximeter App (Argo App)  
**Framework:** Flutter (Dart) · **Target:** Android  
**State Management:** Provider · **Database:** SQLite (`sqflite`)  
**Map Engine:** `flutter_map` + `.mbtiles` · **GPS:** `geolocator` + `latlong2`  
**Screen Wake:** `wakelock_plus` · **Orientation:** Portrait-only (`SystemChrome`)

---

## 1. Directory Structure (Feature-First)

```
lib/
├── main.dart                         # App entry, Provider setup, route config
│
├── core/                             # Shared, feature-agnostic code
│   ├── constants/
│   │   └── app_constants.dart        # Default pricing, GPS thresholds, intervals
│   ├── utils/
│   │   └── haversine.dart            # Haversine distance calc using latlong2
│   └── services/
│       ├── database_service.dart     # SQLite singleton (init, CRUD, migrations)
│       ├── location_service.dart     # Geolocator wrapper (stream, permissions)
│       └── map_service.dart          # MBTiles loading, file path resolution
│
├── features/
│   ├── onboarding/                   # Mandatory map download gate
│   │   ├── screens/
│   │   │   └── onboarding_screen.dart
│   │   └── providers/
│   │       └── download_provider.dart
│   │
│   ├── tracking/                     # Active trip (distance + time meters)
│   │   ├── screens/
│   │   │   └── tracking_screen.dart  # Map view, live KM/time, fare display
│   │   ├── providers/
│   │   │   ├── distance_provider.dart
│   │   │   └── timer_provider.dart
│   │   └── widgets/
│   │       ├── fare_display.dart
│   │       ├── signal_indicator.dart
│   │       └── map_view.dart
│   │
│   ├── settings/                     # Custom pricing config
│   │   ├── screens/
│   │   │   └── settings_screen.dart
│   │   └── providers/
│   │       └── settings_provider.dart
│   │
│   └── history/                      # Trip history + transparency logs
│       ├── screens/
│       │   ├── history_list_screen.dart
│       │   └── history_detail_screen.dart
│       ├── providers/
│       │   └── history_provider.dart
│       └── models/
│           ├── trip_record.dart
│           └── signal_loss_log.dart
│
└── models/                           # Shared data models (if cross-feature)
    └── coordinates.dart
```

> **Map file storage:** The downloaded `east_java.mbtiles` is saved to the
> **Application Documents Directory** resolved at runtime via `path_provider`
> (e.g. `/data/data/com.example.argo/app_flutter/maps/east_java.mbtiles`).
> Flutter's `assets/` folder is read-only and bundled at compile time—it
> cannot be used for files downloaded after installation.

> **Rationale:** Feature-first keeps each screen, its state, and its widgets co-located. A beginner can work inside one folder without touching unrelated code. `core/` holds truly shared utilities.

---

## 2. State Management Strategy (Provider)

### 2.1 Design Principle: Strict UI ↔ Logic Separation

Every computation (GPS polling, Haversine math, timer ticks) lives inside a `ChangeNotifier` subclass. The UI never performs calculations—it only reads exposed getters and calls action methods.

### 2.2 Provider Tree

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait — driver must not accidentally rotate mid-trip
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),    // pricing
        ChangeNotifierProvider(create: (_) => DownloadProvider()),    // onboarding
        ChangeNotifierProvider(create: (_) => DistanceProvider()),    // GPS + km
        ChangeNotifierProvider(create: (_) => TimerProvider()),       // stopwatch
        ChangeNotifierProvider(create: (_) => HistoryProvider()),     // trip logs
      ],
      child: const ArgoApp(),
    ),
  );
}
```

### 2.3 Provider Responsibilities

| Provider | Owns | Notifies UI of |
|---|---|---|
| `SettingsProvider` | Price-per-km, price-per-minute (persisted in SQLite) | Config changes |
| `DownloadProvider` | Download progress %, completion flag | Progress bar updates |
| `DistanceProvider` | GPS stream subscription, coordinate list, total km, signal status, `List<SignalLossLog>` | Distance & fare updates, signal alerts |
| `TimerProvider` | `DateTime _startTime`, `Timer.periodic` (1 s UI refresh), elapsed via `DateTime.now().difference(_startTime)` | Elapsed time & time-based fare |
| `HistoryProvider` | Read/write to `trips` and `signal_loss_logs` tables | Trip list refresh |

### 2.4 Why This Prevents Freezing

- `DistanceProvider` subscribes to `Geolocator.getPositionStream()` in an async listener. Haversine math is pure Dart arithmetic (sub-microsecond)—no isolate needed, but the GPS stream itself is async and non-blocking.
- `TimerProvider` uses `Timer.periodic` **only to trigger UI refreshes** (1 s interval). The actual elapsed time is always computed as `DateTime.now().difference(_startTime)`, which is immune to Android Doze mode pausing the timer. Even if ticks are delayed or skipped, the displayed duration and fare remain accurate.
- **Wakelock (both screens):** `WakelockPlus.enable()` is called in `initState()` of **both** the Distance Tracking screen and the Time Tracking screen. `WakelockPlus.disable()` fires in `dispose()` when the trip ends or the user navigates away. This keeps the screen awake so the driver can glance at the fare without touching the phone.
- Heavy I/O (`sqflite` writes) is `async`/`await`—never synchronous on the main thread.

---

## 3. Database Schema (SQLite)

### 3.1 Table: `trips`

Stores one row per completed trip.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Unique trip ID |
| `date` | `TEXT` | `NOT NULL` | ISO-8601 timestamp (`DateTime.toIso8601String()`) |
| `tracking_type` | `TEXT` | `NOT NULL`, CHECK `IN ('distance', 'time')` | Which meter was primary |
| `total_metric` | `REAL` | `NOT NULL` | Total KM (distance) or total minutes (time) |
| `total_earnings` | `REAL` | `NOT NULL` | Calculated fare in IDR |
| `price_per_unit` | `REAL` | `NOT NULL` | Rate snapshot at trip time (per-km or per-min) |
| `had_signal_loss` | `INTEGER` | `NOT NULL DEFAULT 0` | Boolean flag (0/1) for quick filtering |

### 3.2 Table: `signal_loss_logs`

GPS transparency sub-log. Only populated for distance-tracked trips that experienced signal loss.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Log entry ID |
| `trip_id` | `INTEGER` | `NOT NULL REFERENCES trips(id) ON DELETE CASCADE` | Parent trip |
| `loss_start` | `TEXT` | `NOT NULL` | ISO-8601 timestamp when signal was lost |
| `loss_end` | `TEXT` | `NOT NULL` | ISO-8601 timestamp when signal recovered |
| `last_lat` | `REAL` | `NOT NULL` | Last known latitude before loss |
| `last_lng` | `REAL` | `NOT NULL` | Last known longitude before loss |
| `recovery_lat` | `REAL` | `NOT NULL` | First latitude after recovery |
| `recovery_lng` | `REAL` | `NOT NULL` | First longitude after recovery |
| `straight_line_km` | `REAL` | `NOT NULL` | Haversine distance applied during blackout |
| `duration_seconds` | `INTEGER` | `NOT NULL` | Blackout duration |

### 3.3 Table: `settings`

Simple key-value store for user preferences (avoids SharedPreferences dependency).

| Column | Type | Constraints | Description |
|---|---|---|---|
| `key` | `TEXT` | `PRIMARY KEY` | e.g. `price_per_km`, `price_per_minute` |
| `value` | `TEXT` | `NOT NULL` | Stored as string, parsed by `SettingsProvider` |

### 3.4 DDL (executed in `DatabaseService.init()`)

```sql
CREATE TABLE IF NOT EXISTS trips (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  date            TEXT    NOT NULL,
  tracking_type   TEXT    NOT NULL CHECK(tracking_type IN ('distance','time')),
  total_metric    REAL    NOT NULL,
  total_earnings  REAL    NOT NULL,
  price_per_unit  REAL    NOT NULL,
  had_signal_loss INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS signal_loss_logs (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  trip_id          INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  loss_start       TEXT    NOT NULL,
  loss_end         TEXT    NOT NULL,
  last_lat         REAL    NOT NULL,
  last_lng         REAL    NOT NULL,
  recovery_lat     REAL    NOT NULL,
  recovery_lng     REAL    NOT NULL,
  straight_line_km REAL    NOT NULL,
  duration_seconds INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

---

## 4. Core Services

### 4.1 `LocationService` — GPS Tracking

```
File: lib/core/services/location_service.dart
Depends on: geolocator
```

| Method | Returns | Purpose |
|---|---|---|
| `checkAndRequestPermission()` | `Future<bool>` | Handles `LocationPermission` flow including background permission |
| `startTracking({int intervalMs})` | `Stream<Position>` | Returns `Geolocator.getPositionStream()` with `LocationSettings(distanceFilter: 5)` to ignore micro-jitter |
| `stopTracking()` | `void` | Cancels the stream subscription |
| `isSignalAccurate(Position p)` | `bool` | Returns `p.accuracy <= ACCURACY_THRESHOLD` (e.g., 20 m) |

**Signal Loss Detection Algorithm (consumed by `DistanceProvider`):**

```
1. On each Position event, check isSignalAccurate().
2. If inaccurate or no event for > 5 seconds:
   a. Record last known good coordinate + timestamp → signalLossStart.
   b. Set state to SIGNAL_LOST, trigger visual/audio alert.
3. On next accurate Position:
   a. Record recovery coordinate + timestamp → signalLossEnd.
   b. Compute Haversine(lastGood, recovery) → straight_line_km.
   c. Add straight_line_km to running total.
   d. Push SignalLossLog entry to in-memory list.
   e. Set state back to TRACKING.
```

### 4.2 `haversine()` — Distance Calculation

```
File: lib/core/utils/haversine.dart
Depends on: latlong2
```

```dart
import 'package:latlong2/latlong.dart';

const Distance _haversine = Distance();

/// Returns distance in kilometers between two coordinates.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  return _haversine.as(
    LengthUnit.Kilometer,
    LatLng(lat1, lng1),
    LatLng(lat2, lng2),
  );
}
```

> `latlong2`'s `Distance` class uses the Haversine formula internally. No manual math needed.

### 4.3 `DatabaseService` — SQLite Singleton

```
File: lib/core/services/database_service.dart
Depends on: sqflite, path_provider, path
```

| Method | Purpose |
|---|---|
| `Future<Database> get database` | Lazy-init singleton, runs DDL on `onCreate` |
| `insertTrip(TripRecord)` | `INSERT` into `trips`, returns generated `id` |
| `insertSignalLossLog(SignalLossLog)` | `INSERT` into `signal_loss_logs` |
| `getTrips()` | `SELECT * FROM trips ORDER BY date DESC` |
| `getTripWithLogs(int tripId)` | `JOIN` query returning trip + associated signal loss entries |
| `getSetting(String key)` / `setSetting(String key, String value)` | Key-value CRUD for settings table |

### 4.4 `MapService` — Offline Map Tiles

```
File: lib/core/services/map_service.dart
Depends on: flutter_map, flutter_map_mbtiles, path_provider
```

| Method | Purpose |
|---|---|
| `Future<String> get mbtilesFolderPath` | Returns `{appDocDir}/maps/` |
| `Future<bool> isMapDownloaded()` | Checks if `east_java.mbtiles` exists at expected path |
| `Future<MbTiles> openTileStore()` | Opens the `.mbtiles` file, returns tile provider for `flutter_map` |

**Widget integration:**

```dart
FlutterMap(
  options: MapOptions(initialCenter: surabayaCenter, initialZoom: 13),
  children: [
    TileLayer(
      tileProvider: MbTilesTileProvider(mbTiles: await mapService.openTileStore()),
    ),
    // Polyline layer for route trace
  ],
)
```

---

## 5. Data Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                        DEVICE HARDWARE                                  │
│  GPS Sensor ──► Geolocator Stream    System Clock ──► DateTime.now()    │
│                                      Timer.periodic (UI refresh only)   │
│                                      WakelockPlus (screen stays awake)  │
└────────┬───────────────────────────────────────────────────┬────────────┘
         │ Position events (async)                           │ 1 s tick
         ▼                                                   ▼
┌─────────────────────┐                       ┌────────────────────────────┐
│  DistanceProvider    │                       │   TimerProvider            │
│  ─────────────────── │                       │  ──────────────────────── │
│  • Accumulates km    │                       │  • _startTime recorded    │
│    via haversineKm() │                       │  • elapsed = now - start  │
│  • Detects signal    │                       │  • Doze-proof accuracy    │
│    loss / recovery   │                       │  • Computes time fare     │
│  • Builds in-memory  │                       │  • notifyListeners()      │
│    SignalLossLog[]   │                       └──────────┬─────────────────┘
│  • notifyListeners() │                                  │
└──────────┬───────────┘                                  │
           │                                              │
           ▼                                              ▼
┌──────────────────────────────────────────────────────────────────┐
│                         UI LAYER (Widgets)                        │
│  Consumer<DistanceProvider>  ·  Consumer<TimerProvider>           │
│  ─────────────────────────────────────────────────────────────── │
│  • Reads totalKm, fare, signalStatus, elapsed from providers     │
│  • Renders map (flutter_map + MBTiles), fare display, alerts     │
│  • NEVER computes—only reads & displays                          │
└──────────────────────────┬───────────────────────────────────────┘
                           │ User taps "End Trip"
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                      DatabaseService (async)                      │
│  ──────────────────────────────────────────────────────────────── │
│  1. insertTrip(TripRecord) → gets trip.id                        │
│  2. For each SignalLossLog in DistanceProvider.logs:              │
│       insertSignalLossLog(log..tripId = trip.id)                 │
│  3. HistoryProvider.refresh() → notifyListeners()                │
└──────────────────────────────────────────────────────────────────┘
```

### Flow Summary

1. **GPS → Provider:** `Geolocator` emits `Position` events. `DistanceProvider` consumes the stream, calculates delta-km with Haversine, accumulates total, and detects signal loss windows.
2. **Clock → Provider:** `TimerProvider` records `_startTime = DateTime.now()` on trip start. A `Timer.periodic(1s)` triggers `notifyListeners()` for UI refresh, but the elapsed duration is always `DateTime.now().difference(_startTime)`—immune to Doze-mode tick skips.
3. **Provider → UI:** Widgets use `Consumer<T>` / `context.watch<T>()` to reactively rebuild only the relevant subtree when `notifyListeners()` fires. No computation in build methods.
4. **UI → DB:** On trip end, the UI calls a method on the provider which delegates to `DatabaseService` (all `async`). The `TripRecord` and any `SignalLossLog` entries are persisted. `HistoryProvider` then refreshes its in-memory list.
5. **DB → UI (History):** `HistoryProvider.getTrips()` loads from SQLite. The history screen consumes this provider to display past trips with transparency logs.

---

## 6. Offline Guarantee Checklist

| Concern | Solution |
|---|---|
| Map tiles | Pre-downloaded `.mbtiles` served locally via `flutter_map_mbtiles` |
| GPS | Device-native sensor, no network-assisted location needed |
| Distance math | Pure Dart (`latlong2`), zero network calls |
| Trip storage | Local SQLite via `sqflite` |
| Settings | SQLite `settings` table, no cloud sync |
| Internet permission | Used **only** during onboarding map download; all tracking features work airplane-mode |
