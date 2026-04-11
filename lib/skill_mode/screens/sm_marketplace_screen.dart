import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';

/// Marketplace — discover community decks (SM-2.5.3).
///
/// Sections: Daily Deck, Trending, Rising, From Follows, Browse All.
class SmMarketplaceScreen extends ConsumerStatefulWidget {
  const SmMarketplaceScreen({super.key});

  @override
  ConsumerState<SmMarketplaceScreen> createState() =>
      _SmMarketplaceScreenState();
}

class _SmMarketplaceScreenState extends ConsumerState<SmMarketplaceScreen> {
  List<Map<String, dynamic>> _dailyDeck = [];
  List<Map<String, dynamic>> _trending = [];
  List<Map<String, dynamic>> _rising = [];
  List<Map<String, dynamic>> _fromFollows = [];
  List<Map<String, dynamic>> _allDecks = [];
  bool _loading = true;

  // Filters.
  String? _filterDifficulty;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Daily deck.
      final dailyData = await supabase
          .from('skill_mode_decks')
          .select(
            'id, title, description, language, difficulty, play_count, card_skin, creator_id, creator_target_score',
          )
          .eq('published', true)
          .eq('is_daily_deck', true)
          .gte('daily_deck_date', today.toIso8601String())
          .limit(1);
      _dailyDeck = List<Map<String, dynamic>>.from(dailyData);

      // Trending (most plays).
      final trendingData = await supabase
          .from('skill_mode_decks')
          .select(
            'id, title, description, language, difficulty, play_count, card_skin, creator_id, creator_target_score',
          )
          .eq('published', true)
          .order('play_count', ascending: false)
          .limit(10);
      _trending = List<Map<String, dynamic>>.from(trendingData);

      // Rising (newest with plays).
      final risingData = await supabase
          .from('skill_mode_decks')
          .select(
            'id, title, description, language, difficulty, play_count, card_skin, creator_id, creator_target_score',
          )
          .eq('published', true)
          .gt('play_count', 0)
          .order('created_at', ascending: false)
          .limit(10);
      _rising = List<Map<String, dynamic>>.from(risingData);

      // From follows.
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final follows = await supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', user.id);
        final followIds = (follows as List)
            .map((f) => f['following_id'] as String)
            .toList();
        if (followIds.isNotEmpty) {
          final followData = await supabase
              .from('skill_mode_decks')
              .select(
                'id, title, description, language, difficulty, play_count, card_skin, creator_id, creator_target_score',
              )
              .eq('published', true)
              .inFilter('creator_id', followIds)
              .order('created_at', ascending: false)
              .limit(10);
          _fromFollows = List<Map<String, dynamic>>.from(followData);
        }
      }

      // All decks.
      var query = supabase
          .from('skill_mode_decks')
          .select(
            'id, title, description, language, difficulty, play_count, card_skin, creator_id, creator_target_score',
          )
          .eq('published', true);

      if (_filterDifficulty != null) {
        query = query.eq('difficulty', _filterDifficulty!);
      }

      final allData = await query
          .order('play_count', ascending: false)
          .limit(50);
      _allDecks = List<Map<String, dynamic>>.from(allData);

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Marketplace')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loading = true);
          await _loadData();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Daily Deck.
            if (_dailyDeck.isNotEmpty) ...[
              _sectionHeader('Daily Deck', theme),
              _buildDailyDeck(_dailyDeck.first, theme),
              const SizedBox(height: 16),
            ],

            // Trending.
            if (_trending.isNotEmpty) ...[
              _sectionHeader('Trending', theme),
              _buildHorizontalList(_trending),
              const SizedBox(height: 16),
            ],

            // Rising.
            if (_rising.isNotEmpty) ...[
              _sectionHeader('Rising', theme),
              _buildHorizontalList(_rising),
              const SizedBox(height: 16),
            ],

            // From follows.
            if (_fromFollows.isNotEmpty) ...[
              _sectionHeader('From Creators You Follow', theme),
              _buildHorizontalList(_fromFollows),
              const SizedBox(height: 16),
            ],

            // Browse all.
            _sectionHeader('Browse All', theme),
            ..._allDecks.map((d) => _buildDeckListTile(d, theme)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDailyDeck(Map<String, dynamic> deck, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/skill-mode/deck-detail/${deck['id']}'),
        child:
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha(100),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DAILY DECK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    deck['title'] as String? ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _difficultyChip(
                        deck['difficulty'] as String? ?? 'beginner',
                        theme,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${deck['play_count'] ?? 0} plays',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().shimmer(
              duration: const Duration(milliseconds: 2000),
              color: const Color(0xFFF59E0B).withAlpha(30),
            ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> decks) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: decks.length,
        itemBuilder: (_, i) {
          final deck = decks[i];
          return Padding(
            padding: EdgeInsets.only(right: i < decks.length - 1 ? 12 : 0),
            child: _buildDeckCard(deck),
          );
        },
      ),
    );
  }

  Widget _buildDeckCard(Map<String, dynamic> deck) {
    final theme = Theme.of(context);
    final skinColor = _skinAccentColor(deck['card_skin'] as String?);

    return GestureDetector(
      onTap: () => context.push('/skill-mode/deck-detail/${deck['id']}'),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: skinColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deck['title'] as String? ?? 'Untitled',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            _difficultyChip(deck['difficulty'] as String? ?? 'beginner', theme),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.play_arrow,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${deck['play_count'] ?? 0}',
                  style: theme.textTheme.labelSmall,
                ),
                if (deck['creator_target_score'] != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.sports_mma,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckListTile(Map<String, dynamic> deck, ThemeData theme) {
    return ListTile(
      onTap: () => context.push('/skill-mode/deck-detail/${deck['id']}'),
      title: Text(
        deck['title'] as String? ?? 'Untitled',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${deck['difficulty'] ?? 'beginner'} • ${deck['play_count'] ?? 0} plays',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _difficultyChip(String difficulty, ThemeData theme) {
    final color = switch (difficulty) {
      'beginner' => const Color(0xFF10B981),
      'intermediate' => const Color(0xFFF59E0B),
      'advanced' => const Color(0xFFEF4444),
      _ => const Color(0xFF6B7280),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _skinAccentColor(String? skin) {
    return switch (skin) {
      'dark_academia' => const Color(0xFFD4A574),
      'neon_city' => const Color(0xFF8B5CF6),
      'nature' => const Color(0xFF10B981),
      'minimal' => const Color(0xFF6B7280),
      _ => const Color(0xFF3B82F6),
    };
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Beginner'),
                    selected: _filterDifficulty == 'beginner',
                    onSelected: (v) {
                      setState(() => _filterDifficulty = v ? 'beginner' : null);
                      Navigator.pop(ctx);
                      _loadData();
                    },
                  ),
                  FilterChip(
                    label: const Text('Intermediate'),
                    selected: _filterDifficulty == 'intermediate',
                    onSelected: (v) {
                      setState(
                        () => _filterDifficulty = v ? 'intermediate' : null,
                      );
                      Navigator.pop(ctx);
                      _loadData();
                    },
                  ),
                  FilterChip(
                    label: const Text('Advanced'),
                    selected: _filterDifficulty == 'advanced',
                    onSelected: (v) {
                      setState(() => _filterDifficulty = v ? 'advanced' : null);
                      Navigator.pop(ctx);
                      _loadData();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
