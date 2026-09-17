import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/foreground_service_manager.dart';
import '../../history/models/trip_record.dart';
import '../../../core/utils/currency_formatter.dart';

class TimerProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _resumeTime;
  Duration _accumulatedDuration = Duration.zero;
  bool _isTracking = false;
  bool _isPaused = false;
  double _pricePerMinute = 0.0;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  DateTime? get startTime => _startTime;
  
  Duration get elapsed {
    if (!_isTracking) return Duration.zero;
    if (_isPaused) return _accumulatedDuration;
    if (_resumeTime == null) return Duration.zero;
    return _accumulatedDuration + DateTime.now().difference(_resumeTime!);
  }

  double get totalMinutes => elapsed.inSeconds / 60.0;
  double get totalFare => totalMinutes * _pricePerMinute;

  void setPricePerMinute(double price) {
    _pricePerMinute = price;
  }

  void startTracking() {
    _startTime = DateTime.now();
    _resumeTime = DateTime.now();
    _accumulatedDuration = Duration.zero;
    _isTracking = true;
    _isPaused = false;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        notifyListeners();
        ForegroundServiceManager.updateNotification(
          'Pagroo',
          'Time Meter: ${formatCurrency(totalFare)}',
        );
      }
    });
  }

  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    _isPaused = true;
    _accumulatedDuration += DateTime.now().difference(_resumeTime!);
    notifyListeners();
  }

  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    _isPaused = false;
    _resumeTime = DateTime.now();
    notifyListeners();
  }

  Future<void> endTrip() async {
    _timer?.cancel();
    _isTracking = false;
    notifyListeners();

    TripRecord trip = TripRecord(
      date: _startTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      trackingType: 'time',
      totalMetric: totalMinutes,
      totalEarnings: totalFare,
      pricePerUnit: _pricePerMinute,
      hadSignalLoss: 0,
    );

    await _db.insertTrip(trip);
    resetTripState();
  }

  /// Resets timer state and earnings to zero.
  void resetTripState() {
    _startTime = null;
    _resumeTime = null;
    _accumulatedDuration = Duration.zero;
    _isTracking = false;
    _isPaused = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
