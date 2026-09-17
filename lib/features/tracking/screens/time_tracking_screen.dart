import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/timer_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/services/foreground_service_manager.dart';
import '../../../core/utils/currency_formatter.dart';

class TimeTrackingScreen extends StatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  State<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsProvider>();
      final timerProv = context.read<TimerProvider>();
      timerProv.setPricePerMinute(settings.pricePerMinute);
      await ForegroundServiceManager.requestPermissions();
      if (!timerProv.isTracking) {
        timerProv.resetTripState();
      }
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _endTrip(BuildContext context) async {
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
      final timerProv = context.read<TimerProvider>();
      await timerProv.endTrip();
      timerProv.resetTripState();
      await ForegroundServiceManager.stopService();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _startTrip(BuildContext context) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Trip?'),
        content: const Text('Begin tracking time and fare?'),
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
      // Start local timer immediately so UI updates without delay,
      // then spin up the foreground service in parallel.
      context.read<TimerProvider>().startTracking();
      ForegroundServiceManager.startTimeTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerProv = context.watch<TimerProvider>();
    final settings = context.watch<SettingsProvider>();

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Time Meter'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  _formatDuration(timerProv.elapsed),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  formatCurrency(timerProv.totalFare),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rate: ${formatCurrency(settings.pricePerMinute)}/min',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: timerProv.isTracking
                      ? SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  onPressed: () => _endTrip(context),
                                  icon: const Icon(Icons.stop_rounded),
                                  label: const Text('END TRIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (timerProv.isPaused) {
                                      timerProv.resumeTracking();
                                    } else {
                                      timerProv.pauseTracking();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: timerProv.isPaused ? Colors.orange : theme.colorScheme.secondary,
                                    foregroundColor: timerProv.isPaused ? Colors.white : theme.colorScheme.onSecondary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    minimumSize: const Size.fromHeight(56),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Icon(
                                    timerProv.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _startTrip(context),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('START TRIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
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
