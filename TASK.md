# Project Checklist: Argo App

## Phase 1: Project Initialization & Routing
- [x] Initialize Flutter project.
- [x] Define directory structure (`core/`, `features/`, `models/`).
- [x] Add dependencies to `pubspec.yaml` (flutter_map, geolocator, sqflite, provider, etc.).
- [x] Configure Android permissions in `AndroidManifest.xml` (location, wake lock, storage, internet).
- [x] Set up app theme in `lib/core/theme/app_theme.dart` (Material 3 Dark).
- [x] Configure portrait lock and provider setup in `main.dart`.

## Phase 2: Core Services (SQLite Database, Location/GPS setup, Map file directory)
- [x] Create `lib/core/utils/haversine.dart` for distance calculations.
- [x] Implement `DatabaseService` (SQLite table creation for trips, logs, settings).
- [x] Implement `LocationService` (Geolocator wrapper, stream, permissions).
- [x] Implement `MapService` (MBTiles file resolution).

## Phase 3: State Management (Settings, Download, Distance, Timer, History Providers)
- [x] Implement `SettingsProvider` (price per km/min).
- [x] Implement `DownloadProvider` (map download progress).
- [x] Implement `DistanceProvider` (GPS subscription, haversine accumulation, signal loss tracking).
- [x] Implement `TimerProvider` (periodic UI refresh, elapsed time).
- [x] Implement `HistoryProvider` (read/write trip history).

## Phase 4: UI Implementation (Onboarding, Mode Selection, Active Tracking screens, Settings, History)
- [x] Build Onboarding Screen (`onboarding_screen.dart`).
- [x] Build Mode Selection Screen (Distance vs Time).
- [x] Build Settings Screen (`settings_screen.dart`).
- [x] Build Tracking Screen - Time Mode (Centered timer, Wakelock).
- [x] Build Tracking Screen - Distance Mode (`flutter_map`, bottom HUD, Signal alerts).
- [x] Build History Screen with Expandable Signal Logs (`history_list_screen.dart`).

## Phase 5: UX Refinements & Background Tracking
- [x] Drop existing SQLite database & Update `DatabaseService` schema (`trip_coordinates`).
- [x] Update `DistanceProvider` & `TimerProvider` (Manual start, DB insertion adjustments).
- [x] Update `ModeSelectionScreen` (Live Clock, Active Trip Banner, disable active checks).
- [x] Update `TimeTrackingScreen` (Manual Start button, Center alignment, PopScope).
- [x] Update `DistanceTrackingScreen` (Initial map center, Manual Start button, PopScope).
- [x] Update `HistoryListScreen` (Total Trips KPI, InkWell routing).
- [x] Create `TripDetailScreen` (Static map for distance trips, signal logs, stats).

## Phase 6: Refinements & Features
- [x] Android OS App Name (`AndroidManifest.xml`)
- [x] Settings Icon Relocation & Homepage App Name (`mode_selection_screen.dart`)
- [x] Dark/Light Mode Toggle (Theme, Provider, UI, Main)
- [x] Delete Trip Feature (DB, Provider, Trip Detail)
- [x] Action Confirmations (Start/End trip dialogs)

## Phase 7: Foreground Service & Persistent Notifications
- [x] Add `flutter_foreground_task` and configure `AndroidManifest.xml` (Permissions & Service Types)
- [x] Create `ForegroundServiceManager` (Global TaskHandler, Notification Initialization)
- [x] Update `main.dart` (Init FlutterForegroundTask)
- [x] Update `DistanceTrackingScreen` (Start/Stop service, dynamic notification updates)
- [x] Update `TimeTrackingScreen` (Start/Stop service, dynamic notification updates)
