import '../../core/supabase_config.dart';
import '../models/sm_card.dart';
import '../models/sm_user_card.dart';

/// All Supabase queries for skill_mode_ tables.
class SmSupabaseService {
  /// Fetch cards due for review for this user + language.
  Future<List<SmCard>> fetchDueCards({
    required String userId,
    required String language,
    int limit = 20,
  }) async {
    // Get user_card IDs that are due
    final userCards = await supabase
        .from('skill_mode_user_cards')
        .select('card_id')
        .eq('user_id', userId)
        .lte('next_review_at', DateTime.now().toIso8601String())
        .eq('suspended', false)
        .order('next_review_at')
        .limit(limit);

    final cardIds = (userCards as List)
        .map((uc) => uc['card_id'] as String)
        .toList();

    if (cardIds.isEmpty) {
      // New user — fetch unseen cards
      return _fetchNewCards(userId: userId, language: language, limit: limit);
    }

    final data = await supabase
        .from('skill_mode_cards')
        .select()
        .inFilter('id', cardIds)
        .eq('language', language);

    return (data as List).map((e) => SmCard.fromJson(e)).toList();
  }

  Future<List<SmCard>> _fetchNewCards({
    required String userId,
    required String language,
    int limit = 20,
  }) async {
    final data = await supabase
        .from('skill_mode_cards')
        .select()
        .eq('language', language)
        .order('difficulty')
        .limit(limit);

    return (data as List).map((e) => SmCard.fromJson(e)).toList();
  }

  /// Count cards due today for a user + language.
  Future<int> countDueCards({
    required String userId,
    required String language,
  }) async {
    final data = await supabase
        .from('skill_mode_user_cards')
        .select('id')
        .eq('user_id', userId)
        .lte('next_review_at', DateTime.now().toIso8601String())
        .eq('suspended', false);

    return (data as List).length;
  }

  /// Count total cards for a language.
  Future<int> countTotalCards({required String language}) async {
    final data = await supabase
        .from('skill_mode_cards')
        .select('id')
        .eq('language', language);

    return (data as List).length;
  }

  /// Get user's language progress.
  Future<Map<String, dynamic>?> getUserLanguageProgress({
    required String userId,
    required String language,
  }) async {
    final data = await supabase
        .from('skill_mode_user_languages')
        .select()
        .eq('user_id', userId)
        .eq('language', language)
        .maybeSingle();

    return data;
  }

  /// Upsert a user card SR state.
  Future<void> upsertUserCard(SmUserCard card) async {
    await supabase.from('skill_mode_user_cards').upsert({
      'id': card.id,
      'user_id': card.userId,
      'card_id': card.cardId,
      'ease_factor': card.easeFactor,
      'interval_days': card.intervalDays,
      'repetitions': card.repetitions,
      'next_review_at': card.nextReviewAt.toIso8601String(),
      'last_score_pct': card.lastScorePct,
      'mastery_proven': card.masteryProven,
      'suspended': card.suspended,
    });
  }

  /// Create a new session record.
  Future<String> createSession({
    required String userId,
    required String language,
  }) async {
    final data = await supabase
        .from('skill_mode_sessions')
        .insert({'user_id': userId, 'language': language})
        .select('id')
        .single();

    return data['id'] as String;
  }

  /// End a session.
  Future<void> endSession({
    required String sessionId,
    required int cardsReviewed,
    required int xpEarned,
    required int comboPeak,
  }) async {
    await supabase
        .from('skill_mode_sessions')
        .update({
          'cards_reviewed': cardsReviewed,
          'xp_earned': xpEarned,
          'combo_peak': comboPeak,
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }
}
