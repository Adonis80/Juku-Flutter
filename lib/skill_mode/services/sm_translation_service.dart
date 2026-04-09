import '../../core/supabase_config.dart';
import '../models/sm_translation.dart';

/// Service for community translations — CRUD, voting, trust scores, verification.
class SmTranslationService {
  // ── Fetch translations ──

  /// Get all translations for a card, ordered by net_score desc.
  Future<List<SmTranslation>> getCardTranslations({
    required String cardId,
    String targetLanguage = 'en',
  }) async {
    final data = await supabase
        .from('skill_mode_translations')
        .select('*, profiles!translator_id(username, photo_url)')
        .eq('card_id', cardId)
        .eq('target_language', targetLanguage)
        .order('net_score', ascending: false);

    return (data as List).map((e) => SmTranslation.fromJson(e)).toList();
  }

  /// Get all translations for a song lyric line.
  Future<List<SmTranslation>> getLyricTranslations({
    required String songId,
    required int lineIndex,
    String targetLanguage = 'en',
  }) async {
    final data = await supabase
        .from('skill_mode_translations')
        .select('*, profiles!translator_id(username, photo_url)')
        .eq('song_id', songId)
        .eq('lyric_line_index', lineIndex)
        .eq('target_language', targetLanguage)
        .order('net_score', ascending: false);

    return (data as List).map((e) => SmTranslation.fromJson(e)).toList();
  }

  /// Get the best (highest net_score verified) translation for a card.
  Future<SmTranslation?> getBestCardTranslation({
    required String cardId,
    String targetLanguage = 'en',
  }) async {
    final data = await supabase
        .from('skill_mode_translations')
        .select('*, profiles!translator_id(username, photo_url)')
        .eq('card_id', cardId)
        .eq('target_language', targetLanguage)
        .inFilter('status', ['verified', 'expert_verified'])
        .order('net_score', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? SmTranslation.fromJson(data) : null;
  }

  /// Get all translations submitted by a user.
  Future<List<SmTranslation>> getUserTranslations({
    required String userId,
    int limit = 50,
  }) async {
    final data = await supabase
        .from('skill_mode_translations')
        .select('*, profiles!translator_id(username, photo_url)')
        .eq('translator_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => SmTranslation.fromJson(e)).toList();
  }

  // ── Submit / Edit ──

  /// Submit a new translation. Returns the created translation ID.
  Future<String> submitTranslation({
    required String translatorId,
    required String sourceText,
    required String translatedText,
    String? cardId,
    String? songId,
    int? lyricLineIndex,
    String targetLanguage = 'en',
    String? notes,
    bool isAiDraft = false,
  }) async {
    // Check if this is the first translation for this target
    final isFirst = await _isFirstTranslation(
      cardId: cardId,
      songId: songId,
      lyricLineIndex: lyricLineIndex,
      targetLanguage: targetLanguage,
    );

    final data = await supabase.from('skill_mode_translations').insert({
      'translator_id': translatorId,
      'source_text': sourceText,
      'translated_text': translatedText,
      'card_id': cardId,
      'song_id': songId,
      'lyric_line_index': lyricLineIndex,
      'target_language': targetLanguage,
      'notes': notes,
      'is_ai_draft': isAiDraft,
      'is_first_translator': isFirst,
    }).select('id').single();

    // Update translator stats
    await _updateTranslatorStats(
      userId: translatorId,
      targetLanguage: targetLanguage,
    );

    // Award XP: +10 for first translation, +5 for subsequent
    await _awardTranslationXp(
      userId: translatorId,
      xp: isFirst ? 10 : 5,
      reason: isFirst ? 'skill_mode_first_translation' : 'skill_mode_translation',
    );

    return data['id'] as String;
  }

  /// Edit an existing pending translation (own only, enforced by RLS).
  Future<void> editTranslation({
    required String translationId,
    required String translatedText,
    String? notes,
  }) async {
    await supabase.from('skill_mode_translations').update({
      'translated_text': translatedText,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', translationId);
  }

  /// Delete own translation.
  Future<void> deleteTranslation({required String translationId}) async {
    await supabase
        .from('skill_mode_translations')
        .delete()
        .eq('id', translationId);
  }

  // ── Voting ──

  /// Cast a vote on a translation (toggle: same vote removes it).
  Future<void> castVote({
    required String translationId,
    required String voterId,
    required int vote, // 1 or -1
  }) async {
    await supabase.rpc('cast_translation_vote', params: {
      'p_translation_id': translationId,
      'p_voter_id': voterId,
      'p_vote': vote,
    });
  }

  /// Get the current user's vote on a translation (null if no vote).
  Future<int?> getUserVote({
    required String translationId,
    required String userId,
  }) async {
    final data = await supabase
        .from('skill_mode_translation_votes')
        .select('vote')
        .eq('translation_id', translationId)
        .eq('voter_id', userId)
        .maybeSingle();

    return data?['vote'] as int?;
  }

  /// Get all user votes for a list of translation IDs (batch).
  Future<Map<String, int>> getUserVotesBatch({
    required List<String> translationIds,
    required String userId,
  }) async {
    if (translationIds.isEmpty) return {};

    final data = await supabase
        .from('skill_mode_translation_votes')
        .select('translation_id, vote')
        .inFilter('translation_id', translationIds)
        .eq('voter_id', userId);

    final result = <String, int>{};
    for (final row in data as List) {
      result[row['translation_id'] as String] = row['vote'] as int;
    }
    return result;
  }

  // ── Trust Score + Verification ──

  /// Get translator stats for a user.
  Future<SmTranslatorStats?> getTranslatorStats({
    required String userId,
    String targetLanguage = 'en',
  }) async {
    final data = await supabase
        .from('skill_mode_translator_stats')
        .select()
        .eq('user_id', userId)
        .eq('target_language', targetLanguage)
        .maybeSingle();

    return data != null ? SmTranslatorStats.fromJson(data) : null;
  }

  /// Expert verify a translation (only expert-tier translators can do this).
  Future<void> expertVerify({
    required String translationId,
    required String verifierId,
  }) async {
    await supabase.from('skill_mode_translations').update({
      'status': 'expert_verified',
      'verified_by': verifierId,
      'verified_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', translationId);

    // Award verifier XP
    await _awardTranslationXp(
      userId: verifierId,
      xp: 3,
      reason: 'skill_mode_expert_verify',
    );
  }

  /// Reject a translation (expert-tier only).
  Future<void> rejectTranslation({
    required String translationId,
    required String rejectorId,
  }) async {
    await supabase.from('skill_mode_translations').update({
      'status': 'rejected',
      'verified_by': rejectorId,
      'verified_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', translationId);
  }

  // ── Leaderboard ──

  /// Get top translators by trust score.
  Future<List<SmTranslatorStats>> getTopTranslators({
    String targetLanguage = 'en',
    int limit = 20,
  }) async {
    final data = await supabase
        .from('skill_mode_translator_stats')
        .select()
        .eq('target_language', targetLanguage)
        .order('trust_score', ascending: false)
        .limit(limit);

    return (data as List).map((e) => SmTranslatorStats.fromJson(e)).toList();
  }

  // ── Private helpers ──

  Future<bool> _isFirstTranslation({
    String? cardId,
    String? songId,
    int? lyricLineIndex,
    required String targetLanguage,
  }) async {
    var query = supabase
        .from('skill_mode_translations')
        .select('id')
        .eq('target_language', targetLanguage);

    if (cardId != null) {
      query = query.eq('card_id', cardId);
    } else if (songId != null) {
      query = query.eq('song_id', songId);
      if (lyricLineIndex != null) {
        query = query.eq('lyric_line_index', lyricLineIndex);
      }
    }

    final data = await query.limit(1);
    return (data as List).isEmpty;
  }

  Future<void> _updateTranslatorStats({
    required String userId,
    required String targetLanguage,
  }) async {
    // Get current stats
    final existing = await supabase
        .from('skill_mode_translator_stats')
        .select()
        .eq('user_id', userId)
        .eq('target_language', targetLanguage)
        .maybeSingle();

    if (existing == null) {
      // Create new stats row
      await supabase.from('skill_mode_translator_stats').insert({
        'user_id': userId,
        'target_language': targetLanguage,
        'total_submissions': 1,
        'first_translation_at': DateTime.now().toIso8601String(),
        'tier': 'newcomer',
      });
    } else {
      final submissions = (existing['total_submissions'] as int? ?? 0) + 1;
      final verified = existing['verified_count'] as int? ?? 0;
      final netVotes = existing['total_net_votes'] as int? ?? 0;

      // Calculate trust score
      final trustScore = submissions > 0
          ? (verified * 10 + netVotes) / submissions
          : 0.0;

      // Determine tier
      String tier = 'newcomer';
      if (trustScore >= 50 && verified >= 20) {
        tier = 'expert';
      } else if (trustScore >= 20 && verified >= 10) {
        tier = 'trusted';
      } else if (submissions >= 5 && verified >= 2) {
        tier = 'contributor';
      }

      await supabase.from('skill_mode_translator_stats').update({
        'total_submissions': submissions,
        'trust_score': trustScore,
        'tier': tier,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id'] as String);
    }
  }

  Future<void> _awardTranslationXp({
    required String userId,
    required int xp,
    required String reason,
  }) async {
    await supabase.from('xp_events').insert({
      'user_id': userId,
      'xp': xp,
      'reason': reason,
    });
  }
}
