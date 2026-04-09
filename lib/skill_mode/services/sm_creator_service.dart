import '../../core/supabase_config.dart';

/// Creator economy service (SM-3.5.2).
///
/// Manages creator XP accumulation, rank calculation, and stats.
///
/// Creator XP sources:
/// - Publish deck: 50
/// - Deck play: 2
/// - Deck completion: 10
/// - Tip received: tip_amount × 2
/// - First Master: 100
/// - Daily Deck selected: 500
/// - Deck War win: 300
/// - Beat the Creator triggered: 5
class SmCreatorService {
  SmCreatorService._();
  static final instance = SmCreatorService._();

  /// Creator rank thresholds.
  static const _rankThresholds = <int, String>{
    50000: 'grandmaster',
    10000: 'master',
    2000: 'artisan',
    500: 'craftsman',
    0: 'apprentice',
  };

  static const rankBadges = <String, String>{
    'apprentice': '🪨',
    'craftsman': '🔨',
    'artisan': '⚒️',
    'master': '🏆',
    'grandmaster': '👑',
  };

  static const rankLabels = <String, String>{
    'apprentice': 'Apprentice',
    'craftsman': 'Craftsman',
    'artisan': 'Artisan',
    'master': 'Master',
    'grandmaster': 'Grandmaster',
  };

  /// Award creator XP.
  Future<void> awardCreatorXp({
    required String userId,
    required int amount,
  }) async {
    try {
      // Get or create creator stats.
      final existing = await supabase
          .from('skill_mode_creator_stats')
          .select('creator_xp')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('skill_mode_creator_stats').insert({
          'user_id': userId,
          'creator_xp': amount,
          'creator_level': 1,
          'creator_rank': 'apprentice',
        });
      } else {
        final newXp = (existing['creator_xp'] as int? ?? 0) + amount;
        final newRank = _rankForXp(newXp);
        final newLevel = _levelForXp(newXp);

        await supabase.from('skill_mode_creator_stats').update({
          'creator_xp': newXp,
          'creator_rank': newRank,
          'creator_level': newLevel,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      }
    } catch (_) {}
  }

  /// Get creator stats.
  Future<Map<String, dynamic>?> getCreatorStats(String userId) async {
    try {
      return await supabase
          .from('skill_mode_creator_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  /// Increment deck-level stats.
  Future<void> recordDeckPlay({
    required String creatorId,
    required String deckId,
  }) async {
    // Increment play count on deck.
    try {
      await supabase.rpc('increment_field', params: {
        'table_name': 'skill_mode_decks',
        'field_name': 'play_count',
        'row_id': deckId,
      });
    } catch (_) {
      // Fallback: direct update.
      try {
        final deck = await supabase
            .from('skill_mode_decks')
            .select('play_count')
            .eq('id', deckId)
            .single();
        await supabase.from('skill_mode_decks').update({
          'play_count': (deck['play_count'] as int? ?? 0) + 1,
        }).eq('id', deckId);
      } catch (_) {}
    }

    // Award creator XP for play.
    await awardCreatorXp(userId: creatorId, amount: 2);
  }

  String _rankForXp(int xp) {
    for (final entry in _rankThresholds.entries) {
      if (xp >= entry.key) return entry.value;
    }
    return 'apprentice';
  }

  int _levelForXp(int xp) {
    // 1 level per 100 creator XP, max 50.
    return ((xp / 100).floor() + 1).clamp(1, 50);
  }
}
