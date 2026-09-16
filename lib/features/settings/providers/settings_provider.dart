import 'package:flutter/material.dart';
import '../../../core/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  double _pricePerKm = 4000.0;
  double _pricePerMinute = 500.0;
  bool _isDarkMode = true;
  bool _isLoading = true;
  String? _activeMapFileName;

  double get pricePerKm => _pricePerKm;
  double get pricePerMinute => _pricePerMinute;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  String? get activeMapFileName => _activeMapFileName;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final kmStr = await _db.getSetting('price_per_km');
    final minStr = await _db.getSetting('price_per_minute');

    if (kmStr != null) {
      _pricePerKm = double.tryParse(kmStr) ?? 4000.0;
    }
    if (minStr != null) {
      _pricePerMinute = double.tryParse(minStr) ?? 500.0;
    }
    
    final darkStr = await _db.getSetting('is_dark_mode');
    if (darkStr != null) {
      _isDarkMode = darkStr == 'true';
    }
    
    _activeMapFileName = await _db.getSetting('active_map_file_name');
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveSettings(double kmPrice, double minPrice) async {
    _pricePerKm = kmPrice;
    _pricePerMinute = minPrice;
    notifyListeners();

    await _db.setSetting('price_per_km', kmPrice.toString());
    await _db.setSetting('price_per_minute', minPrice.toString());
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    await _db.setSetting('is_dark_mode', isDark.toString());
  }

  Future<void> setActiveMap(String? fileName) async {
    _activeMapFileName = fileName;
    notifyListeners();
    if (fileName != null) {
      await _db.setSetting('active_map_file_name', fileName);
    } else {
      await _db.setSetting('active_map_file_name', '');
    }
  }
}
