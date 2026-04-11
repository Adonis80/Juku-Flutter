import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tenant_state.dart';
import '../tenant_service.dart';

/// Analytics tab: DAU chart, plays, Juice, signups over 30 days.
class AnalyticsTab extends ConsumerWidget {
  final String tenantId;

  const AnalyticsTab({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(tenantAnalyticsProvider(tenantId));
    final theme = Theme.of(context);

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (snapshots) {
        if (snapshots.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No analytics data yet',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Data appears once your community is active.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final latest = snapshots.last;
        final totals = _aggregate(snapshots);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary cards
            Row(
              children: [
                _StatCard(
                  label: 'DAU (today)',
                  value: '${latest.dau}',
                  icon: Icons.people,
                  color: theme.colorScheme.primary,
                ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'New signups',
                  value: '${totals.newSignups}',
                  icon: Icons.person_add,
                  color: Colors.green,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(
                  label: 'Total plays',
                  value: '${totals.totalPlays}',
                  icon: Icons.play_circle,
                  color: Colors.orange,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Juice flow',
                  value: '${totals.juiceIn.toStringAsFixed(0)} in',
                  icon: Icons.water_drop,
                  color: Colors.purple,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
              ],
            ),

            const SizedBox(height: 24),

            // DAU chart (simple bar chart)
            Text(
              'Daily Active Users (30 days)',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: _BarChart(
                values: snapshots.map((s) => s.dau.toDouble()).toList(),
                color: theme.colorScheme.primary,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Plays chart
            Text('Content Plays (30 days)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: _BarChart(
                values: snapshots.map((s) => s.totalPlays.toDouble()).toList(),
                color: Colors.orange,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // Cards count
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.library_books,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Total content cards'),
                trailing: Text(
                  '${latest.totalCards}',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        );
      },
    );
  }

  TenantAnalytics _aggregate(List<TenantAnalytics> snapshots) {
    int plays = 0, signups = 0;
    double juiceIn = 0, juiceOut = 0;
    for (final s in snapshots) {
      plays += s.totalPlays;
      signups += s.newSignups;
      juiceIn += s.juiceIn;
      juiceOut += s.juiceOut;
    }
    return TenantAnalytics(
      tenantId: snapshots.first.tenantId,
      date: snapshots.last.date,
      dau: snapshots.last.dau,
      totalPlays: plays,
      juiceIn: juiceIn,
      juiceOut: juiceOut,
      newSignups: signups,
      totalCards: snapshots.last.totalCards,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple vertical bar chart using CustomPainter.
class _BarChart extends StatelessWidget {
  final List<double> values;
  final Color color;

  const _BarChart({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(
        values: values,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      size: Size.infinite,
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color backgroundColor;

  _BarChartPainter({
    required this.values,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = (size.width / values.length) - 2;
    final paint = Paint()..color = color;
    final bgPaint = Paint()..color = backgroundColor;

    for (var i = 0; i < values.length; i++) {
      final x = i * (barWidth + 2);
      final barHeight = (values[i] / maxVal) * size.height;

      // Background bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          const Radius.circular(2),
        ),
        bgPaint,
      );

      // Value bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      values != old.values || color != old.color;
}
