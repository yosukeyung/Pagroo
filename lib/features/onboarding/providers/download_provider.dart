import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../../core/services/map_service.dart';

class DownloadProvider extends ChangeNotifier {
  final MapService _mapService = MapService();

  // Per-city state keyed by fileName
  final Map<String, bool> _downloaded = {};
  final Map<String, bool> _downloading = {};
  final Map<String, double> _progress = {};
  final Map<String, String?> _error = {};

  // ── Top-level getters (onboarding compat) ────────────────────────────────

  /// True if at least one city map is fully downloaded.
  bool get isComplete => _downloaded.values.any((v) => v);

  /// True if any download is in progress.
  bool get isDownloading => _downloading.values.any((v) => v);

  /// First non-null error across all cities (for onboarding screen).
  String? get errorMessage {
    for (final e in _error.values) {
      if (e != null) return e;
    }
    return null;
  }

  /// Progress of the Jakarta download (for onboarding progress bar).
  double get progress =>
      _progress[MapService.cities.first.fileName] ?? 0.0;

  // ── Per-city accessors (Settings UI) ─────────────────────────────────────

  bool isDownloadedFor(String fileName) => _downloaded[fileName] ?? false;
  bool isDownloadingFor(String fileName) => _downloading[fileName] ?? false;
  double progressFor(String fileName) => _progress[fileName] ?? 0.0;
  String? errorFor(String fileName) => _error[fileName];

  DownloadProvider() {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    for (final city in MapService.cities) {
      _downloaded[city.fileName] =
          await _mapService.isMapDownloaded(city.fileName);
      if (_downloaded[city.fileName] == true) {
        _progress[city.fileName] = 1.0;
      }
    }
    notifyListeners();
  }

  // ── Download ──────────────────────────────────────────────────────────────

  /// Shim kept for onboarding screen backward compat.
  Future<void> startDownload() => downloadMap(MapService.cities.first);

  /// Downloads the given [city] map with progress tracking and validation.
  Future<void> downloadMap(CityMap city) async {
    final fileName = city.fileName;
    if (_downloading[fileName] == true || _downloaded[fileName] == true) return;
    if (city.downloadUrl == null) return; // Coming Soon — no-op

    _downloading[fileName] = true;
    _progress[fileName] = 0.0;
    _error[fileName] = null;
    notifyListeners();

    try {
      final folderPath = await _mapService.mbtilesFolderPath;
      final destFile = File(p.join(folderPath, fileName));
      final tempFile = File('${destFile.path}.tmp');

      final request = http.Request('GET', Uri.parse(city.downloadUrl!))
        ..headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ..followRedirects = true
        ..maxRedirects = 10;
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          _progress[fileName] = receivedBytes / totalBytes;
          notifyListeners();
        }
      });
      await sink.flush();
      await sink.close();

      // Validate: must be a valid SQLite/MBTiles file
      final headerBytes =
          await tempFile.openRead(0, 6).expand((x) => x).toList();
      const sqliteMagic = [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65];
      final valid = headerBytes.length >= 6 &&
          List.generate(6, (i) => headerBytes[i] == sqliteMagic[i])
              .every((v) => v);

      if (!valid) {
        await tempFile.delete();
        throw Exception('Downloaded file is not a valid SQLite/MBTiles database.');
      }

      await tempFile.rename(destFile.path);

      _progress[fileName] = 1.0;
      _downloaded[fileName] = true;
    } catch (e) {
      _error[fileName] = e.toString();
      _progress[fileName] = 0.0;
      _downloaded[fileName] = false;
    } finally {
      _downloading[fileName] = false;
      notifyListeners();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteMap(String fileName) async {
    await _mapService.deleteMap(fileName);
    _downloaded[fileName] = false;
    _progress[fileName] = 0.0;
    _error[fileName] = null;
    notifyListeners();
  }
}

