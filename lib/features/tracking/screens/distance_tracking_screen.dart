import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' as vmt;
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/distance_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/services/map_service.dart';
import '../../../core/services/foreground_service_manager.dart';
import '../../../core/utils/currency_formatter.dart';

class DistanceTrackingScreen extends StatefulWidget {
  const DistanceTrackingScreen({super.key});

  @override
  State<DistanceTrackingScreen> createState() => _DistanceTrackingScreenState();
}

class _DistanceTrackingScreenState extends State<DistanceTrackingScreen> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  MbTiles? _mbTiles;
  CityMap? _activeCity;
  vtr.Theme? _theme;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    
    _initMap();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();
      final distProv = context.read<DistanceProvider>();
      distProv.setPricePerKm(settings.pricePerKm);
      await ForegroundServiceManager.requestPermissions();
      if (!distProv.isTracking) {
        distProv.resetTripState();
        distProv.loadInitialLocation();
      }
    });
  }

  Future<void> _initMap() async {
    final settings = context.read<SettingsProvider>();
    final activeMapName = settings.activeMapFileName;

    MbTiles? mbTiles;
    CityMap? activeCity = await _mapService.getActiveCity(activeMapName);
    
    if (activeCity != null) {
      try {
        mbTiles = await _mapService.openTileStore(fileName: activeCity.fileName);
      } catch (_) {}
    }
    
    vtr.Theme? loadedTheme;
    try {
      final themeStr = await rootBundle.loadString('assets/style.json');
      final themeData = jsonDecode(themeStr) as Map<String, dynamic>;
      loadedTheme = vtr.ThemeReader().read(themeData);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _mbTiles = mbTiles;
        _activeCity = activeCity;
        _theme = loadedTheme;
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _mbTiles?.dispose();
    super.dispose();
  }

  Future<void> _endTrip() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Trip?'),
        content: const Text('Are you sure you want to stop tracking and finalize this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('End Trip', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final distProv = context.read<DistanceProvider>();
      await distProv.endTrip();
      distProv.resetTripState();
      await ForegroundServiceManager.stopService();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _startTrip() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Trip?'),
        content: const Text('Begin tracking distance and fare?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Start', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      context.read<DistanceProvider>().startTracking();
      ForegroundServiceManager.startDistanceTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distProv = context.watch<DistanceProvider>();

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Distance Meter'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Map Layer
            if (_theme != null)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: distProv.coordinates.isNotEmpty
                      ? distProv.coordinates.last
                      : (_activeCity != null 
                          ? LatLng(_activeCity!.centerLat, _activeCity!.centerLng) 
                          : const LatLng(-6.2088, 106.8456)),
                  initialZoom: 13.0,
                  minZoom: 5.0,
                  maxZoom: 15.0,
                ),
                children: [
                  if (_mbTiles != null)
                    vmt.VectorTileLayer(
                      theme: _theme!,
                      tileProviders: vmt.TileProviders({
                        'openmaptiles': MbTilesVectorTileProvider(
                          mbtiles: _mbTiles!,
                          silenceTileNotFound: true,
                        ),
                      }),
                      maximumZoom: 15,
                    ),
                  if (distProv.coordinates.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: distProv.coordinates,
                          color: theme.colorScheme.primary,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  if (distProv.coordinates.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: distProv.coordinates.last,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),


            // My Location FAB
            Positioned(
              right: 16,
              bottom: 200,
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.primary,
                onPressed: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.high,
                      ),
                    );
                    _mapController.move(
                      LatLng(pos.latitude, pos.longitude),
                      14.0,
                    );
                  } catch (_) {}
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),

            // HUD Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCurrency(distProv.totalFare),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${distProv.totalKm.toStringAsFixed(2)} km',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      distProv.isTracking
                          ? SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _endTrip,
                                icon: const Icon(Icons.stop_rounded),
                                label: const Text('END TRIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _startTrip,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('START TRIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

