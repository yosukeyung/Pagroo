import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/trip_record.dart';
import '../models/signal_loss_log.dart';
import '../providers/history_provider.dart';
import '../../../core/services/map_service.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' as vmt;
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import '../../../core/utils/currency_formatter.dart';

class TripDetailScreen extends StatefulWidget {
  final TripRecord trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final MapService _mapService = MapService();
  MbTiles? _mbTiles;
  vtr.Theme? _theme;
  List<LatLng> _route = [];
  Future<List<SignalLossLog>>? _logsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.trip.hadSignalLoss == 1 && widget.trip.id != null) {
      _logsFuture = context.read<HistoryProvider>().getLogsForTrip(widget.trip.id!);
    }
    if (widget.trip.trackingType == 'distance') {
      _initMap();
      if (widget.trip.routeJson != null && widget.trip.routeJson!.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(widget.trip.routeJson!);
          _route = decoded.map((e) => LatLng(e['lat'], e['lng'])).toList();
        } catch (_) {}
      }
    }
  }

  Future<void> _initMap() async {
    final mbTiles = await _mapService.openTileStore();
    
    vtr.Theme? loadedTheme;
    try {
      final themeStr = await rootBundle.loadString('assets/style.json');
      final themeData = jsonDecode(themeStr) as Map<String, dynamic>;
      loadedTheme = vtr.ThemeReader().read(themeData);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _mbTiles = mbTiles;
        _theme = loadedTheme;
      });
    }
  }

  @override
  void dispose() {
    _mbTiles?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${twoDigits(d.hour)}:${twoDigits(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDistance = widget.trip.trackingType == 'distance';
    final date = DateTime.parse(widget.trip.date);
    
    // Calculate End Time based on duration if it's Time mode. For Distance, we just show Start Time.
    final endTime = isDistance ? null : date.add(Duration(minutes: widget.trip.totalMetric.toInt()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Trip?'),
                  content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await context.read<HistoryProvider>().deleteTrip(widget.trip.id!);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isDistance)
              SizedBox(
                height: 250,
                child: _mbTiles != null && _theme != null
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: _route.isNotEmpty ? _route.first : const LatLng(-6.2088, 106.8456), // Jakarta default
                          initialZoom: 14.0,
                          minZoom: 5.0,
                          maxZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none, // Static map
                          ),
                        ),
                        children: [
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
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _route,
                                color: theme.colorScheme.primary,
                                strokeWidth: 4.0,
                              ),
                            ],
                          ),
                          if (_route.isNotEmpty)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _route.first,
                                  child: const Icon(Icons.location_history, color: Colors.green),
                                ),
                                Marker(
                                  point: _route.last,
                                  child: const Icon(Icons.location_on, color: Colors.red),
                                ),
                              ],
                            ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Summary',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildStatRow('Start Time', _formatDate(date), theme),
                  if (endTime != null) ...[
                    const Divider(),
                    _buildStatRow('End Time', _formatDate(endTime), theme),
                  ],
                  const Divider(),
                  _buildStatRow(
                    isDistance ? 'Total Distance' : 'Total Minutes',
                    isDistance ? '${widget.trip.totalMetric.toStringAsFixed(2)} km' : '${widget.trip.totalMetric.toStringAsFixed(0)} min',
                    theme,
                  ),
                  const Divider(),
                  _buildStatRow(
                    'Total Earnings',
                    formatCurrency(widget.trip.totalEarnings),
                    theme,
                    isHighlight: true,
                  ),

                  if (widget.trip.hadSignalLoss == 1) ...[
                    const SizedBox(height: 16),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        initiallyExpanded: false,
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          'Signal Loss Transparency Logs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FutureBuilder<List<SignalLossLog>>(
                              future: _logsFuture ?? context.read<HistoryProvider>().getLogsForTrip(widget.trip.id!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Text('No detailed logs found.');
                                }
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: snapshot.data!.map((log) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        '• ${log.durationSeconds}s lost  →  Covered ${log.straightLineKm.toStringAsFixed(2)} km.',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
