# Environment Setup Guide
**Project Name:** Custom Offline Taximeter App (Argo App)
**Framework:** Flutter
**Target Platform:** Android

This document outlines the required development environment, dependencies, and configurations needed to build and run the Custom Offline Taximeter application. This guide is specifically optimized for an AI agent or a beginner developer.

## 1. Prerequisites

Before setting up the project, ensure the following software is installed on the host machine:
*   **Operating System:** Windows, macOS, or Linux.
*   **Git:** Version control system.
*   **IDE (Integrated Development Environment):** 
    *   **Visual Studio Code (VS Code)** is highly recommended for beginners and AI pair programming.
    *   **Android Studio** is mandatory for the Android toolchain, SDKs, and emulator setup.

## 2. Flutter & Android Setup

1.  **Flutter SDK:**
    *   Download and install the latest stable Flutter SDK from the [official Flutter website](https://docs.flutter.dev/get-started/install).
    *   Add the `flutter/bin` directory to the system's PATH variable.
2.  **Android Toolchain:**
    *   Install **Android Studio**.
    *   Open Android Studio and navigate to `SDK Manager` -> `SDK Tools`.
    *   Ensure the following are installed: **Android SDK Build-Tools**, **Android Emulator**, and **Android SDK Platform-Tools**.
    *   Set up an Android Virtual Device (AVD) to test the app (or prepare to connect a physical Android device via USB debugging).
3.  **Verification:**
    *   Run `flutter doctor` in the terminal to verify that all necessary components are installed correctly. Resolve any issues marked with an `X`.

## 3. Project Dependencies (`pubspec.yaml`)

To implement the offline features specified in the PRD, add the following packages to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Map & Offline Tiles (Semi-Offline Implementation)
  flutter_map: ^6.1.0 # For rendering the map view
  flutter_map_mbtiles: ^1.0.0 # For loading .mbtiles local map data
  latlong2: ^0.9.0 # For coordinate math (Haversine calculations)

  # Geolocation & GPS
  geolocator: ^11.0.0 # For background and foreground location tracking

  # Local Database (Trip History)
  sqflite: ^2.3.0 # SQLite database manager
  path_provider: ^2.1.2 # To locate correct local paths for DB and Maps
  path: ^1.8.3 # Path manipulation

  # UI & State Management 
  provider: ^6.1.1 # Simple state management for handling timer and distance logic
```
(Note: Instruct the AI agent to verify pub.dev for the latest compatible package versions).

## 4. Android Configuration (AndroidManifest.xml)
Since the app requires background GPS tracking and initial internet access to download the map map data for East Java, configure the following permissions in android/app/src/main/AndroidManifest.xml:
```xml
<manifest xmlns:android="[http://schemas.android.com/apk/res/android](http://schemas.android.com/apk/res/android)">
    <!-- Internet permission for the mandatory initial map download -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <!-- Location permissions for offline GPS tracking -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Required for background location tracking while screen is off (Android 10+) -->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Permission to write/read the downloaded map data to storage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- Wake lock to keep the timer/GPS running while screen is off -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application ...>
        ...
    </application>
</manifest>
```

## 5. Development & Testing Workflow Recommendations
- Testing GPS on Emulator: You can simulate GPS movement (driving a route) using the extended controls (... menu) in the Android Studio Emulator by loading a GPX or KML route file. This is crucial for testing the offline distance calculation and "Straight-Line Recovery" without actually driving.

- State Separation: Keep the UI code entirely separated from the timer and distance calculation logic using Provider to ensure the app doesn't freeze when calculating GPS coordinates.