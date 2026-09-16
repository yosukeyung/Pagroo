import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double _accuracyThreshold = 20.0;

  /// Checks and requests location permissions.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Returns a stream of continuous location updates.
  Stream<Position> startTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  /// Determines if the given GPS coordinate is highly accurate.
  bool isSignalAccurate(Position p) {
    return p.accuracy <= _accuracyThreshold;
  }
}
