import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/history/models/trip_record.dart';
import '../../features/history/models/signal_loss_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Drop old database by switching to a new file name
    final path = join(docsDir.path, 'argo_app_v2.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        date            TEXT    NOT NULL,
        tracking_type   TEXT    NOT NULL CHECK(tracking_type IN ('distance','time')),
        total_metric    REAL    NOT NULL,
        total_earnings  REAL    NOT NULL,
        price_per_unit  REAL    NOT NULL,
        had_signal_loss INTEGER NOT NULL DEFAULT 0,
        route_json      TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS signal_loss_logs (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id          INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        loss_start       TEXT    NOT NULL,
        loss_end         TEXT    NOT NULL,
        last_lat         REAL    NOT NULL,
        last_lng         REAL    NOT NULL,
        recovery_lat     REAL    NOT NULL,
        recovery_lng     REAL    NOT NULL,
        straight_line_km REAL    NOT NULL,
        duration_seconds INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  // Trips CRUD
  Future<int> insertTrip(TripRecord trip) async {
    final db = await database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<TripRecord>> getTrips() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      orderBy: 'date DESC',
    );
    return maps.map((map) => TripRecord.fromMap(map)).toList();
  }

  Future<void> deleteTrip(int id) async {
    final db = await database;
    await db.delete('signal_loss_logs', where: 'trip_id = ?', whereArgs: [id]);
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // Logs CRUD
  Future<int> insertSignalLossLog(SignalLossLog log) async {
    final db = await database;
    return await db.insert('signal_loss_logs', log.toMap());
  }

  Future<List<SignalLossLog>> getSignalLossLogsForTrip(int tripId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'signal_loss_logs',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return maps.map((map) => SignalLossLog.fromMap(map)).toList();
  }

  // Settings CRUD
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
