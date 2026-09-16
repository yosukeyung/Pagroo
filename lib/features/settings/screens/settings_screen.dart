import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../../onboarding/providers/download_provider.dart';
import '../../../core/services/map_service.dart';
import '../../../core/utils/currency_formatter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _kmController.text = settings.pricePerKm.toInt().toString();
    _minController.text = settings.pricePerMinute.toInt().toString();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _minController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState?.validate() ?? false) {
      final double kmPrice = double.tryParse(_kmController.text) ?? 4000.0;
      final double minPrice = double.tryParse(_minController.text) ?? 500.0;

      context.read<SettingsProvider>().saveSettings(kmPrice, minPrice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('APP THEME', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Toggle between light and dark theme'),
                      value: settings.isDarkMode,
                      onChanged: (value) {
                        settings.toggleTheme(value);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                Text('DISTANCE RATE', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _kmController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: 'Rp  ',
                    suffixText: ' /km',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a valid amount';
                    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Quick set:', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [3000, 4000, 5000, 6000, 7500].map((rate) {
                    return ChoiceChip(
                      label: Text(formatCurrency(rate)),
                      selected: _kmController.text == rate.toString(),
                      onSelected: (selected) {
                        setState(() {
                          _kmController.text = rate.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                Text('TIME RATE', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    prefixText: 'Rp  ',
                    suffixText: ' /min',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a valid amount';
                    if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Quick set:', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [300, 500, 750, 1000].map((rate) {
                    return ChoiceChip(
                      label: Text(formatCurrency(rate)),
                      selected: _minController.text == rate.toString(),
                      onSelected: (selected) {
                        setState(() {
                          _minController.text = rate.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 32),
                Text('MAP MANAGEMENT', style: theme.textTheme.labelLarge),
                const SizedBox(height: 12),
                Consumer<DownloadProvider>(
                  builder: (context, dlProv, _) {
                    return Column(
                      children: MapService.cities.map((city) {
                        return _CityMapCard(city: city, dlProv: dlProv);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── City Map Card ─────────────────────────────────────────────────────────────

class _CityMapCard extends StatelessWidget {
  final CityMap city;
  final DownloadProvider dlProv;

  const _CityMapCard({required this.city, required this.dlProv});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${city.displayName} Map?'),
        content: Text(
          'The offline map will be removed. You will need to re-download it to use Distance Tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<DownloadProvider>().deleteMap(city.fileName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${city.displayName} map deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComingSoon = city.downloadUrl == null;
    final isDownloaded = dlProv.isDownloadedFor(city.fileName);
    final isDownloading = dlProv.isDownloadingFor(city.fileName);
    final progress = dlProv.progressFor(city.fileName);
    final error = dlProv.errorFor(city.fileName);
    final settings = context.watch<SettingsProvider>();
    final isActive = settings.activeMapFileName == city.fileName;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive 
            ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
            : isDownloaded
                ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 1.0)
                : BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: city name + status chip
            Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 20,
                  color: isComingSoon
                      ? theme.colorScheme.onSurface.withOpacity(0.4)
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    city.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isComingSoon
                          ? theme.colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                  ),
                ),
                // Status chip
                if (isComingSoon)
                  _StatusChip(label: 'Coming Soon', color: Colors.grey)
                else if (isActive)
                  _StatusChip(label: 'Active Map', color: theme.colorScheme.primary)
                else if (isDownloaded)
                  _StatusChip(label: 'Downloaded ✓', color: Colors.green)
                else if (isDownloading)
                  _StatusChip(label: 'Downloading…', color: Colors.orange)
                else
                  _StatusChip(label: 'Not Available', color: Colors.grey),
              ],
            ),

            // File size row (only for non-coming-soon)
            if (!isComingSoon) ...[
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: MapService().getMapFileSizeBytes(city.fileName),
                builder: (context, snap) {
                  final sizeStr = _formatBytes(snap.data ?? 0);
                  return Text(
                    'Size: $sizeStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ],

            // Progress bar (while downloading)
            if (isDownloading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall,
              ),
            ],

            // Error text
            if (error != null && !isDownloading) ...[
              const SizedBox(height: 6),
              Text(
                'Error: $error',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action buttons
            if (!isComingSoon) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDownloaded && !isActive) ...[
                    OutlinedButton.icon(
                      onPressed: () => settings.setActiveMap(city.fileName),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Set Active'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (isDownloaded)
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    )
                  else if (!isDownloading)
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<DownloadProvider>().downloadMap(city),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(error != null ? 'Retry' : 'Download'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.9),
        ),
      ),
    );
  }
}
