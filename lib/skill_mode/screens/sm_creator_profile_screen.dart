import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../services/sm_creator_service.dart';

/// Creator Profile page (SM-3.5.2).
///
/// Shows creator rank, XP bar, stats, published decks, badges.
class SmCreatorProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const SmCreatorProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<SmCreatorProfileScreen> createState() =>
      _SmCreatorProfileScreenState();
}

class _SmCreatorProfileScreenState
    extends ConsumerState<SmCreatorProfileScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats =
          await SmCreatorService.instance.getCreatorStats(widget.userId);

      final profile = await supabase
          .from('profiles')
          .select('username, display_name, photo_url')
          .eq('id', widget.userId)
          .maybeSingle();

      final decks = await supabase
          .from('skill_mode_decks')
          .select(
              'id, title, language, difficulty, play_count, completion_count, card_skin')
          .eq('creator_id', widget.userId)
          .eq('published', true)
          .order('play_count', ascending: false);

      if (mounted) {
        setState(() {
          _stats = stats;
          _profile = profile;
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
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final username =
        _profile?['display_name'] as String? ??
        _profile?['username'] as String? ??
        'Creator';
    final creatorXp = _stats?['creator_xp'] as int? ?? 0;
    final creatorRank = _stats?['creator_rank'] as String? ?? 'apprentice';
    final totalPlays = _stats?['total_deck_plays'] as int? ?? 0;
    final totalTips = _stats?['total_tips_received'] as int? ?? 0;
    final totalLearners = _stats?['total_learners'] as int? ?? 0;
    final isNativeSpeaker = _stats?['is_native_speaker'] as bool? ?? false;
    final isVerifiedEducator =
        _stats?['is_verified_educator'] as bool? ?? false;

    final rankBadge = SmCreatorService.rankBadges[creatorRank] ?? '🪨';
    final rankLabel = SmCreatorService.rankLabels[creatorRank] ?? 'Apprentice';

    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rank + XP bar.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(rankBadge, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rankLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '$creatorXp Creator XP',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // XP progress bar.
                  LinearProgressIndicator(
                    value: (creatorXp % 500) / 500,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Badges.
          if (isNativeSpeaker || isVerifiedEducator)
            Wrap(
              spacing: 8,
              children: [
                if (isNativeSpeaker)
                  Chip(
                    avatar: const Text('🗣️'),
                    label: const Text('Native Speaker'),
                  ),
                if (isVerifiedEducator)
                  Chip(
                    avatar: const Text('✅'),
                    label: const Text('Verified Educator'),
                  ),
              ],
            ),
          const SizedBox(height: 16),

          // Stats row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statColumn('$totalLearners', 'Learners', theme),
              _statColumn('$totalPlays', 'Plays', theme),
              _statColumn('$totalTips', 'Tips', theme),
            ],
          ),
          const SizedBox(height: 24),

          // Published decks.
          Text(
            'Published Decks',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_decks.isEmpty)
            Text(
              'No published decks yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...List.generate(_decks.length, (i) {
              final deck = _decks[i];
              return ListTile(
                onTap: () =>
                    context.push('/skill-mode/deck-detail/${deck['id']}'),
                title: Text(
                  deck['title'] as String? ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${deck['play_count'] ?? 0} plays • ${deck['difficulty'] ?? 'beginner'}',
                ),
                trailing: const Icon(Icons.chevron_right),
              );
            }),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
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
    );
  }
}
