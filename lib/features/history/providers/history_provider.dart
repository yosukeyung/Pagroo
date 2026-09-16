import 'package:flutter/material.dart';

import '../../../core/services/database_service.dart';
import '../models/trip_record.dart';
import '../models/signal_loss_log.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<TripRecord> _trips = [];
  bool _isLoading = false;

  List<TripRecord> get trips => _trips;
  bool get isLoading => _isLoading;

  double get totalKm => _trips
      .where((t) => t.trackingType == 'distance')
      .fold(0.0, (sum, t) => sum + t.totalMetric);

  double get totalEarnings =>
      _trips.fold(0.0, (sum, t) => sum + t.totalEarnings);

  int get totalTrips => _trips.length;

  HistoryProvider() {
    refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    _trips = await _db.getTrips();

    _isLoading = false;
    notifyListeners();
  }

  Future<List<SignalLossLog>> getLogsForTrip(int tripId) async {
    return await _db.getSignalLossLogsForTrip(tripId);
  }

  Future<void> deleteTrip(int tripId) async {
    await _db.deleteTrip(tripId);
    await refresh();
  }
}
