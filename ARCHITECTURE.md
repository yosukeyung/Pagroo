# Pagroo — System Architecture

## 1. High-Level Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        MSS["ModeSelectionScreen<br/>(Home)"]
        DTS["DistanceTrackingScreen"]
        TTS["TimeTrackingScreen"]
        SS["SettingsScreen"]
        HLS["HistoryListScreen"]
        TDS["TripDetailScreen"]
    end

    subgraph "State Management (Provider)"
        DP["DistanceProvider"]
        TP["TimerProvider"]
        SP["SettingsProvider"]
        HP["HistoryProvider"]
        DLP["DownloadProvider"]
    end

    subgraph "Core Services"
        LS["LocationService"]
        DBS["DatabaseService"]
        MS["MapService"]
        FSM["ForegroundServiceManager"]
    end

    subgraph "Data Layer"
        SQLite["SQLite DB<br/>(argo_app_v2.db)"]
        MBT["MBTiles Files<br/>(maps/*.mbtiles)"]
        IA["Internet Archive<br/>(Map Downloads)"]
    end

    MSS --> DTS
    MSS --> TTS
    MSS --> SS
    MSS --> HLS
    HLS --> TDS

    DTS --> DP
    DTS --> SP
    DTS --> MS
    TTS --> TP
    TTS --> SP
    SS --> SP
    SS --> DLP
    HLS --> HP
    TDS --> HP
    TDS --> MS

    DP --> LS
    DP --> DBS
    DP --> FSM
    TP --> DBS
    TP --> FSM
    SP --> DBS
    HP --> DBS
    DLP --> MS

    DBS --> SQLite
    MS --> MBT
    DLP --> IA
```

## 2. Project Structure

```
lib/
├── main.dart                          # App entry, MultiProvider setup, portrait lock
├── core/
│   ├── constants/                     # (empty — reserved)
│   ├── services/
│   │   ├── database_service.dart      # Singleton SQLite CRUD (trips, signal_loss_logs, settings)
│   │   ├── foreground_service_manager.dart  # Android FGS init, start/stop/update notification
│   │   ├── location_service.dart      # Geolocator permission check + position stream
│   │   └── map_service.dart           # CityMap model, MBTiles validation/open/delete
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 dark/light ThemeData (Slate palette)
│   └── utils/
│       ├── currency_formatter.dart    # Indonesian Rupiah formatting (intl, id_ID locale)
│       └── haversine.dart             # Haversine distance via latlong2
├── features/
│   ├── tracking/
│   │   ├── providers/
│   │   │   ├── distance_provider.dart # GPS stream, distance calc, signal loss, trip save
│   │   │   └── timer_provider.dart    # Timer with pause/resume, fare calc, trip save
│   │   ├── screens/
│   │   │   ├── mode_selection_screen.dart   # Home: mode cards, active trip banner, clock
│   │   │   ├── distance_tracking_screen.dart # Map + HUD + Start/End Trip
│   │   │   └── time_tracking_screen.dart     # Clock + Fare + Start/End/Pause/Resume
│   │   └── widgets/                   # (empty — reserved)
│   ├── settings/
│   │   ├── providers/
│   │   │   └── settings_provider.dart # Rates, theme, active map (persisted)
│   │   └── screens/
│   │       └── settings_screen.dart   # Rate config, theme toggle, map management cards
│   ├── history/
│   │   ├── models/
│   │   │   ├── trip_record.dart       # TripRecord model (toMap/fromMap)
│   │   │   └── signal_loss_log.dart   # SignalLossLog model (toMap/fromMap)
│   │   ├── providers/
│   │   │   └── history_provider.dart  # Trip list, totals, delete, signal loss log fetch
│   │   └── screens/
│   │       ├── history_list_screen.dart # Trip list with stats header
│   │       └── trip_detail_screen.dart  # Detail view, static map, signal loss logs
│   └── onboarding/
│       └── providers/
│           └── download_provider.dart # HTTP download with progress, validation, delete
├── models/                            # (empty — reserved)
├── assets/
│   └── style.json                     # OpenMapTiles vector tile theme
└── test/
    ├── currency_formatter_test.dart   # Formatting unit tests
    ├── trip_reset_test.dart           # Trip state reset unit tests
    └── widget_test.dart               # Default Flutter widget test
```

## 3. Navigation Flow

```mermaid
graph LR
    A["ModeSelectionScreen<br/>(Home)"] -->|"Distance Card"| B["DistanceTrackingScreen"]
    A -->|"Time Card"| C["TimeTrackingScreen"]
    A -->|"Settings ⚙️"| D["SettingsScreen"]
    A -->|"History 📋"| E["HistoryListScreen"]
    E -->|"Tap Trip Card"| F["TripDetailScreen"]
    A -->|"Active Trip Banner"| B
    A -->|"Active Trip Banner"| C
```

There is no onboarding flow. The app launches directly into `ModeSelectionScreen`.

## 4. State Management

Provider (via `ChangeNotifier` + `MultiProvider`) is the sole state management solution.

| Provider | Scope | Key State |
|---|---|---|
| `SettingsProvider` | Global | `pricePerKm`, `pricePerMinute`, `isDarkMode`, `activeMapFileName` |
| `DistanceProvider` | Global | `totalKm`, `coordinates`, `signalStatus`, `isTracking`, `logs` |
| `TimerProvider` | Global | `elapsed`, `isPaused`, `isTracking`, `totalFare` |
| `HistoryProvider` | Global | `trips`, `totalEarnings`, `isLoading` |
| `DownloadProvider` | Global | Per-city: `downloaded`, `downloading`, `progress`, `error` |

All providers are registered in `main.dart` and live for the app's lifetime.

## 5. Database Schema

```mermaid
erDiagram
    trips {
        INTEGER id PK
        TEXT date "ISO 8601"
        TEXT tracking_type "CHECK('distance','time')"
        REAL total_metric "km or minutes"
        REAL total_earnings
        REAL price_per_unit
        INTEGER had_signal_loss "0 or 1"
        TEXT route_json "JSON array of lat/lng"
    }

    signal_loss_logs {
        INTEGER id PK
        INTEGER trip_id FK
        TEXT loss_start "ISO 8601"
        TEXT loss_end "ISO 8601"
        REAL last_lat
        REAL last_lng
        REAL recovery_lat
        REAL recovery_lng
        REAL straight_line_km
        INTEGER duration_seconds
    }

    settings {
        TEXT key PK
        TEXT value
    }

    trips ||--o{ signal_loss_logs : "has"
```

**Settings Keys**: `price_per_km`, `price_per_minute`, `is_dark_mode`, `active_map_file_name`.

## 6. GPS Signal Loss State Machine

```mermaid
stateDiagram-v2
    [*] --> Searching: App starts
    Searching --> Locked: Accurate fix received
    Locked --> Degraded: Inaccurate fix
    Locked --> Lost: 5s watchdog timeout
    Searching --> Lost: 5s watchdog timeout
    Degraded --> Locked: Accurate fix (recovery)
    Degraded --> Lost: 5s watchdog timeout
    Lost --> Locked: Accurate fix (recovery + log)
```

On recovery from `Lost`/`Degraded`, straight-line Haversine distance is added and a `SignalLossLog` is created.

## 7. Map System Architecture

```mermaid
sequenceDiagram
    participant User
    participant SettingsScreen
    participant DownloadProvider
    participant MapService
    participant InternetArchive
    participant Disk

    User->>SettingsScreen: Tap "Download"
    SettingsScreen->>DownloadProvider: downloadMap(city)
    DownloadProvider->>InternetArchive: HTTP GET (streaming)
    InternetArchive-->>DownloadProvider: chunks (progress updates)
    DownloadProvider->>Disk: Write to .tmp file
    DownloadProvider->>Disk: Validate SQLite magic bytes
    DownloadProvider->>Disk: Rename .tmp → .mbtiles
    DownloadProvider-->>SettingsScreen: downloaded = true
    User->>SettingsScreen: Tap "Set Active"
    SettingsScreen->>SettingsProvider: setActiveMap(fileName)
    Note over SettingsProvider: Persisted to SQLite settings table
```

**Active Map Resolution** (`MapService.getActiveCity`):
1. If `selectedFileName` matches a downloaded city → return it.
2. Else, fall back to the first downloaded city.
3. If nothing downloaded → return `null` (blank canvas).

## 8. Foreground Service

The `flutter_foreground_task` package provides an Android Foreground Service that:
- Prevents the OS from killing the app during active GPS/timer tracking.
- Displays a persistent notification with live fare text.
- Uses a `TaskHandler` isolate (`MyTaskHandler`) — the main isolate pushes updates via `updateService()`.

**Service types declared in AndroidManifest**: `location|specialUse`.

## 9. Timer Pause/Resume Architecture

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Running: startTracking()
    Running --> Paused: pauseTracking()
    Paused --> Running: resumeTracking()
    Running --> Idle: endTrip()
    Paused --> Idle: endTrip()
```

`elapsed` is computed as:
- **Running**: `_accumulatedDuration + (now - _resumeTime)`
- **Paused**: `_accumulatedDuration` (frozen)

The 1-second `Timer.periodic` continues ticking during pause but skips `notifyListeners()` and notification updates.
