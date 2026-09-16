import 'package:latlong2/latlong.dart';

const Distance _haversine = Distance();

/// Returns distance in kilometers between two coordinates.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  return _haversine.distance(
    LatLng(lat1, lng1),
    LatLng(lat2, lng2),
  ) / 1000.0;
}
