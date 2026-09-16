import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mbtiles/mbtiles.dart';

/// Describes a supported offline map region.
class CityMap {
  final String id;
  final String displayName;
  final String fileName;
  final double centerLat;
  final double centerLng;

  /// Null means the map is not yet available for download (Coming Soon).
  final String? downloadUrl;

  const CityMap({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.centerLat,
    required this.centerLng,
    this.downloadUrl,
  });
}

class MapService {
  static const String jakartaUrl = "https://archive.org/download/jakarta_202609/planet_106.7471%2C-6.2392_106.8749%2C-6.1517.mbtiles";
  static const String surabayaSidoarjoUrl = "https://archive.org/download/sda-and-sby/planet_112.43%2C-7.513_112.883%2C-7.203.mbtiles";

  /// All supported city maps. Add download URLs when assets become available.
  static const List<CityMap> cities = [
    CityMap(
      id: 'jakarta',
      displayName: 'Jakarta',
      fileName: 'jakarta.mbtiles',
      centerLat: -6.2088,
      centerLng: 106.8456,
      downloadUrl: jakartaUrl,
    ),
    CityMap(
      id: 'surabaya_sidoarjo',
      displayName: 'Surabaya & Sidoarjo',
      fileName: 'surabaya_sidoarjo.mbtiles',
      centerLat: -7.250445,
      centerLng: 112.768845,
      downloadUrl: surabayaSidoarjoUrl,
    ),
  ];

  /// Returns the `{appDocDir}/maps/` directory, creating it if needed.
  Future<String> get mbtilesFolderPath async {
    final docsDir = await getApplicationDocumentsDirectory();
    final mapsDir = Directory(join(docsDir.path, 'maps'));
    if (!await mapsDir.exists()) {
      await mapsDir.create(recursive: true);
    }
    return mapsDir.path;
  }

  /// Strict validation: file must exist, be non-empty, and start with the
  /// SQLite magic bytes (first 6 bytes: 53 51 4C 69 74 65 = "SQLite").
  Future<bool> isMapDownloaded(String fileName) async {
    try {
      final folderPath = await mbtilesFolderPath;
      final file = File(join(folderPath, fileName));
      if (!await file.exists()) return false;
      if (await file.length() == 0) return false;

      final bytes = await file.openRead(0, 6).expand((x) => x).toList();
      const magic = [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65];
      if (bytes.length < 6) return false;
      for (int i = 0; i < 6; i++) {
        if (bytes[i] != magic[i]) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if at least one city map passes strict validation.
  Future<bool> isAnyMapDownloaded([String? selectedFileName]) async {
    return (await getActiveCity(selectedFileName)) != null;
  }

  /// Returns the selected city if valid, otherwise falls back to the first valid downloaded map.
  Future<CityMap?> getActiveCity([String? selectedFileName]) async {
    if (selectedFileName != null) {
      for (final city in cities) {
        if (city.fileName == selectedFileName && await isMapDownloaded(city.fileName)) {
          return city;
        }
      }
    }
    
    for (final city in cities) {
      if (await isMapDownloaded(city.fileName)) return city;
    }
    return null;
  }

  /// Deletes the `.mbtiles` file for the given [fileName].
  Future<void> deleteMap(String fileName) async {
    final folderPath = await mbtilesFolderPath;
    final file = File(join(folderPath, fileName));
    if (await file.exists()) await file.delete();
  }

  /// Returns file size in bytes, or 0 if the file does not exist.
  Future<int> getMapFileSizeBytes(String fileName) async {
    try {
      final folderPath = await mbtilesFolderPath;
      final file = File(join(folderPath, fileName));
      if (!await file.exists()) return 0;
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  /// Opens the MbTiles store. If [fileName] is null, auto-picks the first
  /// city whose map passes strict validation.
  Future<MbTiles> openTileStore({String? fileName}) async {
    final folderPath = await mbtilesFolderPath;

    if (fileName != null && await isMapDownloaded(fileName)) {
      return MbTiles(mbtilesPath: join(folderPath, fileName));
    }

    for (final city in cities) {
      if (await isMapDownloaded(city.fileName)) {
        return MbTiles(mbtilesPath: join(folderPath, city.fileName));
      }
    }
    // Fallback — caller should guard with isAnyMapDownloaded() first.
    return MbTiles(mbtilesPath: join(folderPath, cities.first.fileName));
  }
}
