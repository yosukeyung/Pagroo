import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/foreground_service_manager.dart';
import '../../../core/utils/haversine.dart';
import '../../history/models/signal_loss_log.dart';
import '../../history/models/trip_record.dart';
import '../../../core/utils/currency_formatter.dart';

enum SignalStatus { searching, locked, degraded, lost }

class DistanceProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final DatabaseService _db = DatabaseService();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _watchdogTimer;

  List<LatLng> _coordinates = [];
  List<SignalLossLog> _logs = [];
  
  double _totalKm = 0.0;
  SignalStatus _signalStatus = SignalStatus.searching;
  
  Position? _lastGoodPosition;
  DateTime? _signalLossStart;
  bool _isTracking = false;
  double _pricePerKm = 0.0;

  double get totalKm => _totalKm;
  double get totalFare => _totalKm * _pricePerKm;
  SignalStatus get signalStatus => _signalStatus;
  List<LatLng> get coordinates => _coordinates;
  List<SignalLossLog> get logs => _logs;
  bool get isTracking => _isTracking;

  void setPricePerKm(double price) {
    _pricePerKm = price;
  }

  Future<void> loadInitialLocation() async {
    bool hasPermission = await _locationService.checkAndRequestPermission();
    if (!hasPermission) return;
    
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _lastGoodPosition = pos;
    if (_coordinates.isEmpty) {
      _coordinates.add(LatLng(pos.latitude, pos.longitude));
      notifyListeners();
    }
  }

  Future<void> startTracking() async {
    bool hasPermission = await _locationService.checkAndRequestPermission();
    if (!hasPermission) return;

    _totalKm = 0.0;
    _coordinates.clear();
    _logs.clear();
    _lastGoodPosition = null;
    _signalLossStart = null;
    _signalStatus = SignalStatus.searching;
    _isTracking = true;
    notifyListeners();

    _positionSubscription = _locationService.startTracking().listen((Position position) {
      _handlePositionUpdate(position);
    });

    _startWatchdog();
  }

  void _handlePositionUpdate(Position position) {
    _resetWatchdog();

    bool isAccurate = _locationService.isSignalAccurate(position);

    if (isAccurate) {
      if (_signalStatus == SignalStatus.lost || _signalStatus == SignalStatus.degraded) {
        // Recovered
        if (_lastGoodPosition != null && _signalLossStart != null) {
          double straightLineKm = haversineKm(
            _lastGoodPosition!.latitude, _lastGoodPosition!.longitude,
            position.latitude, position.longitude
          );
          
          _totalKm += straightLineKm;
          
          _logs.add(SignalLossLog(
            lossStart: _signalLossStart!.toIso8601String(),
            lossEnd: DateTime.now().toIso8601String(),
            lastLat: _lastGoodPosition!.latitude,
            lastLng: _lastGoodPosition!.longitude,
            recoveryLat: position.latitude,
            recoveryLng: position.longitude,
            straightLineKm: straightLineKm,
            durationSeconds: DateTime.now().difference(_signalLossStart!).inSeconds,
          ));
        }
      }

      if (_lastGoodPosition != null && _signalStatus == SignalStatus.locked) {
        _totalKm += haversineKm(
          _lastGoodPosition!.latitude, _lastGoodPosition!.longitude,
          position.latitude, position.longitude
        );
      }

      _lastGoodPosition = position;
      _signalStatus = SignalStatus.locked;
      _signalLossStart = null;
      _coordinates.add(LatLng(position.latitude, position.longitude));
    } else {
      // Inaccurate
      if (_signalStatus == SignalStatus.locked) {
        _signalStatus = SignalStatus.degraded;
        _signalLossStart ??= DateTime.now();
      }
    }
    
    _updateForegroundNotification();
    notifyListeners();
  }

  void _updateForegroundNotification() {
    if (_isTracking) {
      ForegroundServiceManager.updateNotification(
        'Pagroo',
        'Distance: ${_totalKm.toStringAsFixed(2)} km | ${formatCurrency(totalFare)}',
      );
    }
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_signalStatus == SignalStatus.locked || _signalStatus == SignalStatus.searching) {
        _signalStatus = SignalStatus.lost;
        _signalLossStart ??= DateTime.now();
        _updateForegroundNotification();
        notifyListeners();
      }
    });
  }

  void _resetWatchdog() {
    _startWatchdog();
  }

  Future<void> endTrip() async {
    _watchdogTimer?.cancel();
    await _positionSubscription?.cancel();
    _isTracking = false;
    notifyListeners();

    String? routeJson;
    if (_coordinates.isNotEmpty) {
      final List<Map<String, double>> latLngs = _coordinates.map((c) => {'lat': c.latitude, 'lng': c.longitude}).toList();
      routeJson = jsonEncode(latLngs);
    }

    TripRecord trip = TripRecord(
      date: DateTime.now().toIso8601String(),
      trackingType: 'distance',
      totalMetric: _totalKm,
      totalEarnings: totalFare,
      pricePerUnit: _pricePerKm,
      hadSignalLoss: _logs.isNotEmpty ? 1 : 0,
      routeJson: routeJson,
    );

    int tripId = await _db.insertTrip(trip);
    for (var log in _logs) {
      log.tripId = tripId;
      await _db.insertSignalLossLog(log);
    }

    resetTripState();
  }

  /// Clears the route polyline, resets total distance to 0.0 and total earnings to 0.
  void resetTripState() {
    _totalKm = 0.0;
    _coordinates.clear();
    _logs.clear();
    _lastGoodPosition = null;
    _signalLossStart = null;
    _signalStatus = SignalStatus.searching;
    notifyListeners();
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
