import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../models/sm_duo_battle.dart';

/// Duo Battle results — winner announcement, XP earned, stats (SM-8).
class SmDuoResultsScreen extends ConsumerStatefulWidget {
  final String battleId;
  const SmDuoResultsScreen({super.key, required this.battleId});

  @override
  ConsumerState<SmDuoResultsScreen> createState() => _SmDuoResultsScreenState();
}

class _SmDuoResultsScreenState extends ConsumerState<SmDuoResultsScreen> {
  SmDuoBattle? _battle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final data = await supabase
          .from('skill_mode_duo_battles')
          .select()
          .eq('id', widget.battleId)
          .single();

      if (mounted) {
        setState(() {
          _battle = SmDuoBattle.fromJson(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final battle = _battle;
    if (battle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('Battle not found')),
      );
    }

    final isWinner = battle.winnerId == userId;
    final isDraw = battle.isDraw;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Result icon
              Icon(
                isDraw
                    ? Icons.handshake
                    : isWinner
                    ? Icons.emoji_events
                    : Icons.sentiment_neutral,
                size: 80,
                color: isDraw
                    ? cs.tertiary
                    : isWinner
                    ? Colors.amber
                    : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              // Result text
              Text(
                isDraw
                    ? 'Draw!'
                    : isWinner
                    ? 'Victory!'
                    : 'Defeat',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDraw
                      ? cs.tertiary
                      : isWinner
                      ? Colors.amber.shade700
                      : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isDraw
                    ? 'Evenly matched!'
                    : isWinner
                    ? '+50 XP'
                    : '+15 XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),

              // Score comparison
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _scoreColumn(
                            'You',
                            battle.myScore(userId),
                            cs.primary,
                            theme,
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: cs.outlineVariant,
                          ),
                          _scoreColumn(
                            'Opponent',
                            battle.opponentScore(userId),
                            cs.error,
                            theme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      // Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _detailColumn(
                            'Cards',
                            '${battle.myCardsDone(userId)}/${battle.cardCount}',
                            theme,
                          ),
                          _detailColumn(
                            'Time',
                            _formatTime(
                              battle.isPlayerA(userId)
                                  ? battle.playerATimeMs
                                  : battle.playerBTimeMs,
                            ),
                            theme,
                          ),
                          _detailColumn(
                            'Avg',
                            battle.myCardsDone(userId) > 0
                                ? '${((battle.isPlayerA(userId) ? battle.playerATimeMs : battle.playerBTimeMs) / battle.myCardsDone(userId) / 1000).toStringAsFixed(1)}s'
                                : '-',
                            theme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/skill-mode'),
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.pushReplacement('/skill-mode/duo'),
                      icon: const Icon(Icons.replay),
                      label: const Text('Rematch'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          'points',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _detailColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatTime(int ms) {
    final secs = ms / 1000;
    if (secs < 60) return '${secs.toStringAsFixed(1)}s';
    final mins = (secs / 60).floor();
    final remainSecs = (secs % 60).toStringAsFixed(0);
    return '$mins:${remainSecs.padLeft(2, '0')}';
  }
}
