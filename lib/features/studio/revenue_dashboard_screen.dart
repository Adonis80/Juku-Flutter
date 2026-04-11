import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/supabase_config.dart';

/// Creator revenue dashboard — shows Juice earned from module plays, tips, etc.
class RevenueDashboardScreen extends StatefulWidget {
  const RevenueDashboardScreen({super.key});

  @override
  State<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends State<RevenueDashboardScreen> {
  bool _loading = true;
  int _totalEarned = 0;
  int _thisWeek = 0;
  int _thisMonth = 0;
  List<Map<String, dynamic>> _moduleBreakdown = [];
  List<Map<String, dynamic>> _recentTips = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Get total tips received
    final tipsData = await supabase
        .from('juice_transactions')
        .select('amount, created_at, reference')
        .eq('user_id', user.id)
        .eq('type', 'purchase')
        .like('reference', '%tip%')
        .order('created_at', ascending: false)
        .limit(50);

    final tips = List<Map<String, dynamic>>.from(tipsData);

    final now = DateTime.now().toUtc();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime.utc(now.year, now.month, 1);

    int total = 0;
    int week = 0;
    int month = 0;

    for (final tx in tips) {
      final amount = tx['amount'] as int? ?? 0;
      total += amount;

      final createdAt = DateTime.tryParse(tx['created_at'] as String? ?? '');
      if (createdAt != null) {
        if (createdAt.isAfter(weekStart)) week += amount;
        if (createdAt.isAfter(monthStart)) month += amount;
      }
    }

    // Get module play counts
    final modulesData = await supabase
        .from('skill_mode_sessions')
        .select('module_id, skill_mode_modules(title)')
        .eq('skill_mode_modules.user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);

    final modulePlays = <String, Map<String, dynamic>>{};
    for (final s in modulesData) {
      final moduleId = s['module_id'] as String? ?? '';
      final title =
          (s['skill_mode_modules'] as Map<String, dynamic>?)?['title']
              as String? ??
          'Unknown';

      if (modulePlays.containsKey(moduleId)) {
        modulePlays[moduleId]!['plays'] =
            (modulePlays[moduleId]!['plays'] as int) + 1;
      } else {
        modulePlays[moduleId] = {'title': title, 'plays': 1};
      }
    }

    final breakdown = modulePlays.values.toList()
      ..sort((a, b) => (b['plays'] as int).compareTo(a['plays'] as int));

    // Get live gift earnings
    final liveGifts = await supabase
        .from('live_gifts')
        .select('juice_amount, created_at')
        .eq('host_id', user.id)
        .order('created_at', ascending: false)
        .limit(20);

    for (final g in liveGifts) {
      final amount = g['juice_amount'] as int? ?? 0;
      total += amount;

      final createdAt = DateTime.tryParse(g['created_at'] as String? ?? '');
      if (createdAt != null) {
        if (createdAt.isAfter(weekStart)) week += amount;
        if (createdAt.isAfter(monthStart)) month += amount;
      }
    }

    if (mounted) {
      setState(() {
        _totalEarned = total;
        _thisWeek = week;
        _thisMonth = month;
        _moduleBreakdown = breakdown;
        _recentTips = tips.take(10).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Creator Revenue')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'This Week',
                          value: '$_thisWeek',
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: 'This Month',
                          value: '$_thisMonth',
                          icon: Icons.date_range,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryCard(
                          label: 'All Time',
                          value: '$_totalEarned',
                          icon: Icons.bar_chart,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Module breakdown
                  if (_moduleBreakdown.isNotEmpty) ...[
                    Text(
                      'Module Plays',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._moduleBreakdown.take(5).map((m) {
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.play_circle,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(m['title'] as String? ?? 'Module'),
                          trailing: Text(
                            '${m['plays']} plays',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Recent tips
                  Text(
                    'Recent Earnings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_recentTips.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No earnings yet — create content to start earning!',
                            style: TextStyle(color: theme.colorScheme.outline),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentTips.map((tx) {
                      final amount = tx['amount'] as int? ?? 0;
                      final ref = tx['reference'] as String? ?? '';

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          title: Text(
                            ref.contains('live_gift')
                                ? 'Live Gift'
                                : ref.contains('tip')
                                ? 'Tip Received'
                                : 'Earning',
                          ),
                          trailing: Text(
                            '+$amount Juice',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const Text('Juice', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
