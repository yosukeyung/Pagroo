class SignalLossLog {
  final int? id;
  int? tripId;
  final String lossStart;
  final String lossEnd;
  final double lastLat;
  final double lastLng;
  final double recoveryLat;
  final double recoveryLng;
  final double straightLineKm;
  final int durationSeconds;

  SignalLossLog({
    this.id,
    this.tripId,
    required this.lossStart,
    required this.lossEnd,
    required this.lastLat,
    required this.lastLng,
    required this.recoveryLat,
    required this.recoveryLng,
    required this.straightLineKm,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'loss_start': lossStart,
      'loss_end': lossEnd,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'recovery_lat': recoveryLat,
      'recovery_lng': recoveryLng,
      'straight_line_km': straightLineKm,
      'duration_seconds': durationSeconds,
    };
  }

  factory SignalLossLog.fromMap(Map<String, dynamic> map) {
    return SignalLossLog(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int?,
      lossStart: map['loss_start'] as String,
      lossEnd: map['loss_end'] as String,
      lastLat: (map['last_lat'] as num).toDouble(),
      lastLng: (map['last_lng'] as num).toDouble(),
      recoveryLat: (map['recovery_lat'] as num).toDouble(),
      recoveryLng: (map['recovery_lng'] as num).toDouble(),
      straightLineKm: (map['straight_line_km'] as num).toDouble(),
      durationSeconds: map['duration_seconds'] as int,
    );
  }
}
