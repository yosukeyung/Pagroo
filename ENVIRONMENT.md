# Pagroo — Environment Setup

## 1. Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | ≥ 3.13.2 | Dart SDK ^3.13.2 (from `pubspec.yaml`) |
| Android Studio | Latest | For emulator + SDK management |
| Android SDK | API 21+ | `minSdk = flutter.minSdkVersion` |
| Java / JDK | 17 | Required by Gradle (`JavaVersion.VERSION_17`) |
| Git | Any | Version control |

## 2. Clone & Install

```bash
git clone <repo-url> papi
cd papi
flutter pub get
```

## 3. Dependencies

### Runtime Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_map` | ^7.0.2 | Map widget (OpenStreetMap-compatible tile renderer) |
| `mbtiles` | ^0.4.0 | Read MBTiles SQLite databases |
| `vector_map_tiles` | ^8.0.0 | Vector tile layer for flutter_map |
| `vector_map_tiles_mbtiles` | ^1.2.0 | MBTiles provider for vector_map_tiles |
| `vector_tile_renderer` | ^5.2.1 | Theme reader for vector tile styles |
| `latlong2` | ^0.9.1 | LatLng model + Haversine distance |
| `geolocator` | ^14.0.3 | GPS location stream + permissions |
| `sqflite` | ^2.4.3 | SQLite database (trips, settings) |
| `sqlite3_flutter_libs` | ^0.5.24 | Bundles native `libsqlite3.so` for Android |
| `path_provider` | ^2.1.6 | App documents directory path |
| `path` | ^1.9.1 | File path manipulation |
| `provider` | ^6.1.5+1 | State management (ChangeNotifier) |
| `wakelock_plus` | ^1.8.0 | Prevents screen sleep during tracking |
| `flutter_foreground_task` | ^11.0.3 | Android Foreground Service + notification |
| `http` | ^1.6.0 | HTTP client for map downloads |
| `intl` | ^0.19.0 | Indonesian locale number/currency formatting |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_test` | SDK | Widget & unit testing |
| `flutter_lints` | ^6.0.0 | Static analysis lint rules |

## 4. Android Configuration

### AndroidManifest.xml Permissions

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Foreground Service Declaration

```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="location|specialUse"
    android:exported="false" />
```

### Build Configuration

- **Namespace**: `com.example.argo_app`
- **Compile SDK**: `flutter.compileSdkVersion`
- **Min SDK**: `flutter.minSdkVersion`
- **Java Compatibility**: 17
- **Kotlin JVM Target**: 17

## 5. Assets

```yaml
flutter:
  assets:
    - assets/style.json    # OpenMapTiles vector tile theme
```

The `style.json` file defines the visual styling for the offline vector maps (road colors, labels, land/water fill).

## 6. Running the App

### Debug (Emulator or Physical Device)

```bash
flutter run
```

### Release APK

```bash
flutter build apk --release
```

### Run Tests

```bash
flutter test
```

## 7. Map Files

MBTiles files are downloaded at runtime to `{appDocDir}/maps/`:

| City | File | Source URL |
|---|---|---|
| Jakarta | `jakarta.mbtiles` | `https://archive.org/download/jakarta_202609/...` |
| Surabaya & Sidoarjo | `surabaya_sidoarjo.mbtiles` | `https://archive.org/download/sda-and-sby/...` |

Files are validated post-download by checking the first 6 bytes for the SQLite magic header (`53 51 4C 69 74 65`).

## 8. Local Database

- **File**: `{appDocDir}/argo_app_v2.db`
- **Engine**: SQLite via `sqflite` + `sqlite3_flutter_libs`
- **Tables**: `trips`, `signal_loss_logs`, `settings`
- **Version**: 1 (no migrations)