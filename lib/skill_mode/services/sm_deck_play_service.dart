import '../../core/supabase_config.dart';
import 'sm_creator_service.dart';
import 'sm_xp_engine.dart';

/// Deck play tracking — First Master detection, score recording (SM-3.5.3–5).
class SmDeckPlayService {
  SmDeckPlayService._();
  static final instance = SmDeckPlayService._();

  /// Record a deck play and check for First Master.
  Future<SmDeckPlayResult> recordPlay({
    required String deckId,
    required String playerId,
    required String creatorId,
    required int scorePct,
    required int cardsCompleted,
    required bool fullyMastered,
  }) async {
    try {
      // Check if there's already a First Master.
      bool isFirstMaster = false;
      if (fullyMastered) {
        final existing = await supabase
            .from('skill_mode_deck_plays')
            .select('id')
            .eq('deck_id', deckId)
            .eq('fully_mastered', true)
            .limit(1);

        isFirstMaster = (existing as List).isEmpty;
      }

      // Insert play record.
      await supabase.from('skill_mode_deck_plays').insert({
        'deck_id': deckId,
        'player_id': playerId,
        'score_pct': scorePct,
        'cards_completed': cardsCompleted,
        'fully_mastered': fullyMastered,
        'is_first_master': isFirstMaster,
      });

      // Award creator XP for play.
      await SmCreatorService.instance.recordDeckPlay(
        creatorId: creatorId,
        deckId: deckId,
      );

      // Award creator XP for completion.
      if (fullyMastered) {
        await SmCreatorService.instance.awardCreatorXp(
          userId: creatorId,
          amount: 10,
        );
      }

      // First Master: extra XP for both player and creator.
      if (isFirstMaster) {
        await SmXpEngine.instance.awardXp(
          userId: playerId,
          baseAmount: 50,
          reason: 'first_master',
          currentCombo: 0,
        );
        await SmCreatorService.instance.awardCreatorXp(
          userId: creatorId,
          amount: 100,
        );
      }

      return SmDeckPlayResult(
        isFirstMaster: isFirstMaster,
        scorePct: scorePct,
        fullyMastered: fullyMastered,
      );
    } catch (e) {
      return SmDeckPlayResult(
        isFirstMaster: false,
        scorePct: scorePct,
        fullyMastered: fullyMastered,
      );
    }
  }

  /// Get daily deck for today.
  Future<Map<String, dynamic>?> getDailyDeck() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final data = await supabase
          .from('skill_mode_daily_challenges')
          .select('deck_id, total_plays, top_score')
          .eq('challenge_date', today.toIso8601String().split('T').first)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Get active Deck Wars.
  Future<List<Map<String, dynamic>>> getActiveWars() async {
    try {
      final now = DateTime.now().toIso8601String();
      final data = await supabase
          .from('skill_mode_deck_wars')
          .select()
          .gte('ends_at', now)
          .lte('starts_at', now)
          .order('starts_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }
}

/// Result of recording a deck play.
class SmDeckPlayResult {
  final bool isFirstMaster;
  final int scorePct;
  final bool fullyMastered;

  const SmDeckPlayResult({
    required this.isFirstMaster,
    required this.scorePct,
    required this.fullyMastered,
  });
}
