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
  bool _isTracking = false;
  double _pricePerMinute = 0.0;

  bool get isTracking => _isTracking;
  DateTime? get startTime => _startTime;
  
  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  double get totalMinutes => elapsed.inSeconds / 60.0;
  double get totalFare => totalMinutes * _pricePerMinute;

  void setPricePerMinute(double price) {
    _pricePerMinute = price;
  }

  void startTracking() {
    _startTime = DateTime.now();
    _isTracking = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();
      ForegroundServiceManager.updateNotification(
        'Pagroo',
        'Time Meter: ${formatCurrency(totalFare)}',
      );
    });
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
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
