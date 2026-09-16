class TripRecord {
  final int? id;
  final String date;
  final String trackingType;
  final double totalMetric;
  final double totalEarnings;
  final double pricePerUnit;
  final int hadSignalLoss;
  final String? routeJson;

  TripRecord({
    this.id,
    required this.date,
    required this.trackingType,
    required this.totalMetric,
    required this.totalEarnings,
    required this.pricePerUnit,
    this.hadSignalLoss = 0,
    this.routeJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'tracking_type': trackingType,
      'total_metric': totalMetric,
      'total_earnings': totalEarnings,
      'price_per_unit': pricePerUnit,
      'had_signal_loss': hadSignalLoss,
      'route_json': routeJson,
    };
  }

  factory TripRecord.fromMap(Map<String, dynamic> map) {
    return TripRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      trackingType: map['tracking_type'] as String,
      totalMetric: (map['total_metric'] as num).toDouble(),
      totalEarnings: (map['total_earnings'] as num).toDouble(),
      pricePerUnit: (map['price_per_unit'] as num).toDouble(),
      hadSignalLoss: map['had_signal_loss'] as int,
      routeJson: map['route_json'] as String?,
    );
  }
}
