# Product Requirements Document (PRD)
**Project Name:** Custom Offline Taximeter App (Argo App)
**Target Platform:** Android (Mobile)
**Target Audience:** Rideshare / Online Taxi Driver (Personal Use)

## 1. Product Overview
The objective is to build a mobile application that functions as a customizable taximeter. The app is specifically designed for a rideshare driver to independently track trip fares based on either distance (kilometers) or time. The application must operate 100% offline without requiring cellular data during the trip, utilizing the device's native GPS and offline map data targeting the East Java region (specifically covering Surabaya and Sidoarjo).

## 2. Tech Stack Recommendations
*   **Framework:** Flutter (Dart) - Chosen for beginner friendliness and excellent offline package support.
*   **Local Database:** SQLite (via `sqflite` package) - For robust, 100% offline history storage.
*   **Map Engine:** `flutter_map` using OpenStreetMap (OSM) tile data in `.mbtiles` format.
*   **Location Services:** `geolocator` package for background GPS tracking.

## 3. Core Features & Requirements

### 3.1. Mandatory Offline Map Onboarding
*   **Concept:** The application cannot be used until the base map data is downloaded.
*   **Scope:** Download a pre-packaged map of the East Java region (ensuring comprehensive coverage of Surabaya and Sidoarjo without false-positive clipping errors). The file size must be kept well under 1 GB (target: 200MB - 400MB).
*   **Flow:** On initial launch, prompt the user to download the map package via Wi-Fi. Lock the main tracking features until the download is 100% complete.

### 3.2. Distance Tracking (Kilometer-Based Meter)
*   **Concept:** Tracks distance using native device GPS coordinates independently from the time tracker.
*   **Custom Pricing:** The user must be able to set a custom price per kilometer.
*   **Signal Loss Handling & Recovery:** 
    *   Implement "Straight-Line Recovery" (Haversine formula) to calculate the distance between the last known coordinate and the reconnected coordinate.
    *   Provide visual/audio alerts if the GPS accuracy drops significantly or signal is lost for more than 5 seconds.

### 3.3. Time Tracking (Time-Based Meter)
*   **Concept:** A background timer that tracks trip duration independently from distance.
*   **Custom Pricing:** The user must be able to set a custom price per minute/hour.

### 3.4. Advanced Trip History & Transparency
*   **Concept:** A local logging system to store past trips using SQLite.
*   **Base Data Stored:** Date, type of tracking (Distance or Time), total metric (KM or Minutes), and total earnings.
*   **GPS Transparency Log:** If the signal is lost during a distance-tracked trip, the history log must specifically record this incident. It must display how much distance was calculated using the "Straight-Line" fallback method during the blackout, providing full transparency on the fare calculation.

## 4. Out of Scope (For Now)
*   Cloud database synchronization (Firebase, AWS, etc.).
*   Live traffic updates (requires internet).