import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

/// Deck detail screen — cover, creator, stats, leaderboard, play button (SM-2.5.4).
class SmDeckDetailScreen extends ConsumerStatefulWidget {
  final String deckId;
  const SmDeckDetailScreen({super.key, required this.deckId});

  @override
  ConsumerState<SmDeckDetailScreen> createState() =>
      _SmDeckDetailScreenState();
}

class _SmDeckDetailScreenState extends ConsumerState<SmDeckDetailScreen> {
  Map<String, dynamic>? _deck;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  Future<void> _loadDeck() async {
    try {
      final deckData = await supabase
          .from('skill_mode_decks')
          .select()
          .eq('id', widget.deckId)
          .single();

      // Load leaderboard.
      final lbData = await supabase
          .from('skill_mode_deck_plays')
          .select('player_id, score_pct')
          .eq('deck_id', widget.deckId)
          .order('score_pct', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _deck = deckData;
          _leaderboard = List<Map<String, dynamic>>.from(lbData);
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
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final deck = _deck;
    if (deck == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Deck not found')),
      );
    }

    final title = deck['title'] as String? ?? 'Untitled';
    final description = deck['description'] as String?;
    final difficulty = deck['difficulty'] as String? ?? 'beginner';
    final playCount = deck['play_count'] as int? ?? 0;
    final targetScore = deck['creator_target_score'] as int?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header.
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primary.withAlpha(100),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Description.
                if (description != null && description.isNotEmpty) ...[
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stats row.
                Row(
                  children: [
                    _statChip(Icons.play_arrow, '$playCount plays', theme),
                    const SizedBox(width: 12),
                    _statChip(Icons.signal_cellular_alt,
                        difficulty.toUpperCase(), theme),
                    if (targetScore != null) ...[
                      const SizedBox(width: 12),
                      _statChip(
                          Icons.sports_mma, 'Beat $targetScore%', theme),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Beat the Creator card.
                if (targetScore != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_mma,
                            color: Color(0xFFF59E0B), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Beat the Creator',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              Text(
                                'Can you score above $targetScore%?',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Leaderboard.
                Text(
                  'Leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (_leaderboard.isEmpty)
                  Text(
                    'No plays yet — be the first!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ...List.generate(_leaderboard.length, (i) {
                    final entry = _leaderboard[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: i < 3
                            ? [
                                const Color(0xFFFFD700),
                                const Color(0xFFC0C0C0),
                                const Color(0xFFCD7F32),
                              ][i]
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i < 3
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      title: Text('Player'),
                      trailing: Text(
                        '${entry['score_pct'] ?? 0}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Tip jar visual.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.coffee, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tip Jar',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${deck['creator_juice_earned'] ?? 0} Juice received',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () {
              // Navigate to session with this deck's cards.
              context.push('/skill-mode/deck');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
