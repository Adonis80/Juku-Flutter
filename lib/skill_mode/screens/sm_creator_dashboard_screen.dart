import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../services/sm_creator_service.dart';

/// Creator Dashboard — personal analytics for deck creators (SM-3.5.7).
///
/// Published decks list with stats, earnings, creator XP bar,
/// learner count, notifications, improvement flags.
class SmCreatorDashboardScreen extends ConsumerStatefulWidget {
  const SmCreatorDashboardScreen({super.key});

  @override
  ConsumerState<SmCreatorDashboardScreen> createState() =>
      _SmCreatorDashboardScreenState();
}

class _SmCreatorDashboardScreenState
    extends ConsumerState<SmCreatorDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final stats = await SmCreatorService.instance.getCreatorStats(user.id);

      final decks = await supabase
          .from('skill_mode_decks')
          .select(
            'id, title, language, difficulty, play_count, completion_count, creator_juice_earned, creator_target_score, card_skin',
          )
          .eq('creator_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _stats = stats;
          _decks = List<Map<String, dynamic>>.from(decks);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Decks')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final creatorXp = _stats?['creator_xp'] as int? ?? 0;
    final creatorRank = _stats?['creator_rank'] as String? ?? 'apprentice';
    final totalTips = _stats?['total_tips_received'] as int? ?? 0;
    final totalLearners = _stats?['total_learners'] as int? ?? 0;
    final rankBadge = SmCreatorService.rankBadges[creatorRank] ?? '🪨';
    final rankLabel = SmCreatorService.rankLabels[creatorRank] ?? 'Apprentice';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/skill-mode/create-deck'),
            tooltip: 'Create deck',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Creator rank card.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(rankBadge, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rankLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (creatorXp % 500) / 500,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$creatorXp XP',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats row.
          Row(
            children: [
              Expanded(
                child: _statCard(
                  '$totalLearners',
                  'Learners',
                  Icons.people,
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  '$totalTips',
                  'Juice Earned',
                  Icons.water_drop,
                  theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  '${_decks.length}',
                  'Decks',
                  Icons.style,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Deck list.
          Text(
            'Published Decks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          if (_decks.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.style_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No decks yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/skill-mode/create-deck'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Deck'),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_decks.length, (i) {
              final deck = _decks[i];
              final plays = deck['play_count'] as int? ?? 0;
              final completions = deck['completion_count'] as int? ?? 0;
              final completionRate = plays > 0
                  ? (completions / plays * 100).round()
                  : 0;
              final juiceEarned = deck['creator_juice_earned'] as int? ?? 0;
              final needsImprovement = completionRate < 40 && plays > 10;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () =>
                      context.push('/skill-mode/deck-detail/${deck['id']}'),
                  title: Row(
                    children: [
                      if (needsImprovement)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          deck['title'] as String? ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '$plays plays • $completionRate% completion • $juiceEarned Juice',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
