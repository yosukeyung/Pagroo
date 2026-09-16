import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../models/trip_record.dart';
import 'trip_detail_screen.dart';
import '../../../core/utils/currency_formatter.dart';

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyProv = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        centerTitle: true,
      ),
      body: historyProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // StatHeader
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        label: 'Total Trips',
                        value: formatNumber(historyProv.trips.length),
                      ),
                      _StatItem(
                        label: 'Total Earnings',
                        value: formatCurrency(historyProv.totalEarnings),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: historyProv.trips.length,
                    itemBuilder: (context, index) {
                      final trip = historyProv.trips[index];
                      return _TripCard(trip: trip);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripRecord trip;

  const _TripCard({required this.trip});

  String _formatDate(DateTime d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${twoDigits(d.day)} ${months[d.month - 1]} ${d.year}, ${twoDigits(d.hour)}:${twoDigits(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDistance = trip.trackingType == 'distance';
    final date = DateTime.parse(trip.date);
    final formattedDate = _formatDate(date);
    final metricLabel = isDistance ? '${trip.totalMetric.toStringAsFixed(2)} km' : '${trip.totalMetric.toStringAsFixed(0)} min';
    final icon = isDistance ? Icons.location_on_rounded : Icons.timer_rounded;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripDetailScreen(trip: trip),
          ));
        },
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(formattedDate),
          subtitle: Text('$metricLabel  ·  ${formatCurrency(trip.pricePerUnit)}/${isDistance ? 'km' : 'min'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(trip.totalEarnings),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
