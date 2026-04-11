import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/supabase_config.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  int _activeTab = 0; // 0=weekly, 1=monthly, 2=all-time

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      setState(() => _activeTab = _tabCtrl.index);
      _load();
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    List<Map<String, dynamic>> data;

    if (_activeTab == 2) {
      // All-time: use profile XP total
      data = await supabase
          .from('profiles')
          .select('id, username, display_name, xp, level, rank, photo_url')
          .order('xp', ascending: false)
          .limit(20);
    } else {
      // Weekly or monthly: aggregate xp_events
      final days = _activeTab == 0 ? 7 : 30;
      final since = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String();

      // Use RPC or manual aggregation
      // Since we can't do GROUP BY easily via PostgREST, fetch recent events and aggregate client-side
      final events = await supabase
          .from('xp_events')
          .select('user_id, amount')
          .gte('created_at', since)
          .limit(1000);

      final totals = <String, int>{};
      for (final e in List<Map<String, dynamic>>.from(events)) {
        final uid = e['user_id'] as String;
        totals[uid] = (totals[uid] ?? 0) + (e['amount'] as int? ?? 0);
      }

      // Sort and take top 20
      final sorted = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topIds = sorted.take(20).map((e) => e.key).toList();

      if (topIds.isEmpty) {
        if (mounted) {
          setState(() {
            _users = [];
            _loading = false;
          });
        }
        return;
      }

      final profiles = await supabase
          .from('profiles')
          .select('id, username, display_name, xp, level, rank, photo_url')
          .inFilter('id', topIds);

      // Merge XP totals and sort
      data = List<Map<String, dynamic>>.from(profiles);
      for (final p in data) {
        p['period_xp'] = totals[p['id']] ?? 0;
      }
      data.sort(
        (a, b) => (b['period_xp'] as int).compareTo(a['period_xp'] as int),
      );
    }

    if (mounted) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? Center(
              child: Text(
                'No data yet',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final u = _users[index];
                  final username = u['username'] as String? ?? 'unknown';
                  final rank = u['rank'] as String? ?? 'bronze';
                  final xpDisplay = _activeTab == 2
                      ? '${u['xp'] ?? 0} XP'
                      : '${u['period_xp'] ?? 0} XP';

                  return Card(
                    color: index < 3 ? _podiumColor(index, theme) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index < 3
                            ? Colors.white.withValues(alpha: 0.9)
                            : theme.colorScheme.primaryContainer,
                        child: index < 3
                            ? Text(
                                _podiumEmoji(index),
                                style: const TextStyle(fontSize: 20),
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                      ),
                      title: Text(
                        u['display_name'] as String? ?? username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '@$username · ${rankLabels[rank] ?? 'Bronze'} · Level ${u['level'] ?? 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: index < 3
                              ? Colors.white70
                              : theme.colorScheme.outline,
                        ),
                      ),
                      trailing: Text(
                        xpDisplay,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index < 3
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                      onTap: () => context.push('/profile/${u['id']}'),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _podiumColor(int index, ThemeData theme) {
    return switch (index) {
      0 => const Color(0xFFF59E0B), // gold
      1 => const Color(0xFF94A3B8), // silver
      2 => const Color(0xFFCD7F32), // bronze
      _ => theme.colorScheme.surface,
    };
  }

  String _podiumEmoji(int index) {
    return switch (index) {
      0 => '\u{1F947}', // gold medal
      1 => '\u{1F948}', // silver medal
      2 => '\u{1F949}', // bronze medal
      _ => '',
    };
  }
}
