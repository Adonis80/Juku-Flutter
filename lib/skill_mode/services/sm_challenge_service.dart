import '../../core/supabase_config.dart';
import '../models/sm_challenge.dart';

/// Service for Challenge Mode — create, accept, complete, compare (SM-9).
class SmChallengeService {
  /// Create a challenge — send a card/deck to a friend with your score.
  Future<String> createChallenge({
    required String challengerId,
    required String challengedId,
    required String language,
    required int challengerScore,
    required int challengerTimeMs,
    String? cardId,
    String? deckId,
    String? tauntMessage,
  }) async {
    final data = await supabase.from('skill_mode_challenges').insert({
      'challenger_id': challengerId,
      'challenged_id': challengedId,
      'card_id': cardId,
      'deck_id': deckId,
      'language': language,
      'challenger_score': challengerScore,
      'challenger_time_ms': challengerTimeMs,
      'taunt_message': tauntMessage,
    }).select('id').single();

    // Award XP for sending a challenge
    await supabase.from('xp_events').insert({
      'user_id': challengerId,
      'xp': 5,
      'reason': 'skill_mode_challenge_sent',
    });

    return data['id'] as String;
  }

  /// Accept a challenge.
  Future<void> acceptChallenge(String challengeId) async {
    await supabase.from('skill_mode_challenges').update({
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', challengeId);
  }

  /// Decline a challenge.
  Future<void> declineChallenge(String challengeId) async {
    await supabase.from('skill_mode_challenges').update({
      'status': 'declined',
    }).eq('id', challengeId);
  }

  /// Complete a challenge — submit the challenged player's score.
  Future<SmChallenge> completeChallenge({
    required String challengeId,
    required int score,
    required int timeMs,
  }) async {
    // Get current challenge
    final existing = await supabase
        .from('skill_mode_challenges')
        .select()
        .eq('id', challengeId)
        .single();

    final challengerScore = existing['challenger_score'] as int;
    final challengerId = existing['challenger_id'] as String;
    final challengedId = existing['challenged_id'] as String;

    // Determine winner
    String? winnerId;
    if (score > challengerScore) {
      winnerId = challengedId;
    } else if (challengerScore > score) {
      winnerId = challengerId;
    }
    // Equal score: compare time
    if (score == challengerScore) {
      final challengerTime = existing['challenger_time_ms'] as int;
      if (timeMs < challengerTime) {
        winnerId = challengedId;
      } else if (challengerTime < timeMs) {
        winnerId = challengerId;
      }
      // Equal score + time = no winner
    }

    final data = await supabase.from('skill_mode_challenges').update({
      'challenged_score': score,
      'challenged_time_ms': timeMs,
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
      'winner_id': winnerId,
    }).eq('id', challengeId).select().single();

    // Award XP
    if (winnerId == challengedId) {
      await supabase.from('xp_events').insert({
        'user_id': challengedId,
        'xp': 30,
        'reason': 'skill_mode_challenge_won',
      });
      await supabase.from('xp_events').insert({
        'user_id': challengerId,
        'xp': 10,
        'reason': 'skill_mode_challenge_lost',
      });
    } else if (winnerId == challengerId) {
      await supabase.from('xp_events').insert({
        'user_id': challengerId,
        'xp': 20,
        'reason': 'skill_mode_challenge_defended',
      });
      await supabase.from('xp_events').insert({
        'user_id': challengedId,
        'xp': 10,
        'reason': 'skill_mode_challenge_lost',
      });
    } else {
      // Draw
      await supabase.from('xp_events').insert({
        'user_id': challengerId,
        'xp': 15,
        'reason': 'skill_mode_challenge_draw',
      });
      await supabase.from('xp_events').insert({
        'user_id': challengedId,
        'xp': 15,
        'reason': 'skill_mode_challenge_draw',
      });
    }

    return SmChallenge.fromJson(data);
  }

  /// Get pending challenges for a user (received).
  Future<List<SmChallenge>> getPendingChallenges(String userId) async {
    final data = await supabase
        .from('skill_mode_challenges')
        .select()
        .eq('challenged_id', userId)
        .eq('status', 'pending')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (data as List).map((e) => SmChallenge.fromJson(e)).toList();
  }

  /// Get sent challenges.
  Future<List<SmChallenge>> getSentChallenges(String userId) async {
    final data = await supabase
        .from('skill_mode_challenges')
        .select()
        .eq('challenger_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return (data as List).map((e) => SmChallenge.fromJson(e)).toList();
  }

  /// Get challenge history (all completed).
  Future<List<SmChallenge>> getChallengeHistory({
    required String userId,
    int limit = 20,
  }) async {
    final data = await supabase
        .from('skill_mode_challenges')
        .select()
        .or('challenger_id.eq.$userId,challenged_id.eq.$userId')
        .eq('status', 'completed')
        .order('completed_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => SmChallenge.fromJson(e)).toList();
  }

  /// Get friends/followers for challenge picker.
  Future<List<Map<String, dynamic>>> getChallengeFriends(
    String userId,
  ) async {
    final data = await supabase
        .from('follows')
        .select('following_id, profiles!follows_following_id_fkey(id, username, photo_url)')
        .eq('follower_id', userId)
        .limit(50);

    return List<Map<String, dynamic>>.from(data as List);
  }
}
