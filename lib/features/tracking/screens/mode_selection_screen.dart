import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/providers/settings_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../../history/screens/history_list_screen.dart';
import '../providers/distance_provider.dart';
import '../providers/timer_provider.dart';
import 'distance_tracking_screen.dart';
import 'time_tracking_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String _formatClock(DateTime d) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} • ${twoDigits(d.hour)}:${twoDigits(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final isDistanceActive = context.watch<DistanceProvider>().isTracking;
    final isTimeActive = context.watch<TimerProvider>().isTracking;
    
    final bool anyActive = isDistanceActive || isTimeActive;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
        title: const Text('Pagroo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryListScreen()));
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Clock
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              _formatClock(_currentTime),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Current Rates Banner
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Rates: ${formatCurrency(settings.pricePerKm)}/km | ${formatCurrency(settings.pricePerMinute)}/min',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Select Tracking Mode',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'Distance Meter',
                  subtitle: 'Track fare by GPS distance',
                  icon: Icons.location_on_rounded,
                  rateText: 'Rp/km →',
                  isDisabled: isTimeActive,
                  isActive: isDistanceActive,
                  onTap: () {
                    if (isTimeActive) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DistanceTrackingScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  title: 'Time Meter',
                  subtitle: 'Track fare by elapsed time',
                  icon: Icons.timer_rounded,
                  rateText: 'Rp/min →',
                  isDisabled: isDistanceActive,
                  isActive: isTimeActive,
                  onTap: () {
                    if (isDistanceActive) return;
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimeTrackingScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: anyActive ? _ActiveTripBanner(
        isDistance: isDistanceActive,
        onTap: () {
          if (isDistanceActive) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DistanceTrackingScreen()));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TimeTrackingScreen()));
          }
        },
      ) : null,
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  final bool isDistance;
  final VoidCallback onTap;

  const _ActiveTripBanner({required this.isDistance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Row(
            children: [
              Icon(
                isDistance ? Icons.location_on_rounded : Icons.timer_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip in Progress',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tap to return to ${isDistance ? 'Distance' : 'Time'} Meter',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String rateText;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isActive;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rateText,
    required this.onTap,
    this.isDisabled = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: isDisabled ? 0 : 2,
      color: isDisabled ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive 
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDisabled 
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isDisabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDisabled ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                rateText,
                style: TextStyle(
                  color: isDisabled ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
