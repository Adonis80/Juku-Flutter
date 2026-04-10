import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../models/sm_duo_battle.dart';

/// Service for Duo Battle matchmaking, realtime state, and scoring (SM-8).
class SmDuoBattleService {
  RealtimeChannel? _battleChannel;
  StreamController<SmDuoBattle>? _battleStream;

  // ── Matchmaking ──

  /// Find or create a battle. Returns the battle.
  /// If a waiting battle exists for this language, join it.
  /// Otherwise create a new one and wait.
  Future<SmDuoBattle> findOrCreateBattle({
    required String userId,
    required String language,
    int cardCount = 10,
  }) async {
    // Look for an existing waiting battle in the same language
    final waiting = await supabase
        .from('skill_mode_duo_battles')
        .select()
        .eq('status', 'waiting')
        .eq('language', language)
        .eq('card_count', cardCount)
        .neq('player_a_id', userId)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (waiting != null) {
      // Join existing battle
      return _joinBattle(
        battleId: waiting['id'] as String,
        userId: userId,
      );
    }

    // Create a new battle
    return _createBattle(
      userId: userId,
      language: language,
      cardCount: cardCount,
    );
  }

  Future<SmDuoBattle> _createBattle({
    required String userId,
    required String language,
    int cardCount = 10,
  }) async {
    // Pick random cards for this language
    final cardIds = await _pickRandomCards(
      language: language,
      count: cardCount,
    );

    final data = await supabase.from('skill_mode_duo_battles').insert({
      'player_a_id': userId,
      'language': language,
      'card_count': cardCount,
      'card_ids': cardIds,
      'status': 'waiting',
    }).select().single();

    return SmDuoBattle.fromJson(data);
  }

  Future<SmDuoBattle> _joinBattle({
    required String battleId,
    required String userId,
  }) async {
    final data = await supabase
        .from('skill_mode_duo_battles')
        .update({
          'player_b_id': userId,
          'status': 'matched',
          'matched_at': DateTime.now().toIso8601String(),
        })
        .eq('id', battleId)
        .select()
        .single();

    return SmDuoBattle.fromJson(data);
  }

  // ── Realtime ──

  /// Subscribe to battle updates. Returns a stream of battle state changes.
  Stream<SmDuoBattle> subscribeToBattle(String battleId) {
    _battleStream?.close();
    _battleStream = StreamController<SmDuoBattle>.broadcast();

    _battleChannel = supabase.channel('duo_battle_$battleId');
    _battleChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'skill_mode_duo_battles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: battleId,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            if (newData.isNotEmpty) {
              _battleStream?.add(SmDuoBattle.fromJson(newData));
            }
          },
        )
        .subscribe();

    return _battleStream!.stream;
  }

  /// Unsubscribe from battle updates.
  Future<void> unsubscribe() async {
    if (_battleChannel != null) {
      await supabase.removeChannel(_battleChannel!);
      _battleChannel = null;
    }
    _battleStream?.close();
    _battleStream = null;
  }

  // ── Battle Actions ──

  /// Start the battle (transition from matched/countdown to active).
  Future<void> startBattle(String battleId) async {
    await supabase.from('skill_mode_duo_battles').update({
      'status': 'active',
      'started_at': DateTime.now().toIso8601String(),
    }).eq('id', battleId);
  }

  /// Submit a round result (one card answered).
  Future<void> submitRound({
    required String battleId,
    required String playerId,
    required String cardId,
    required int roundIndex,
    required bool correct,
    required int timeMs,
  }) async {
    final score = correct ? max(100 - (timeMs ~/ 100), 10) : 0;

    // Insert round
    await supabase.from('skill_mode_duo_rounds').insert({
      'battle_id': battleId,
      'player_id': playerId,
      'card_id': cardId,
      'round_index': roundIndex,
      'correct': correct,
      'time_ms': timeMs,
      'score': score,
    });

    // Fetch current battle to determine which player column to update
    final battle = await supabase
        .from('skill_mode_duo_battles')
        .select()
        .eq('id', battleId)
        .single();

    final isPlayerA = battle['player_a_id'] == playerId;
    final scoreKey = isPlayerA ? 'player_a_score' : 'player_b_score';
    final timeKey = isPlayerA ? 'player_a_time_ms' : 'player_b_time_ms';
    final doneKey = isPlayerA ? 'player_a_cards_done' : 'player_b_cards_done';

    final currentScore = battle[scoreKey] as int? ?? 0;
    final currentTime = battle[timeKey] as int? ?? 0;
    final currentDone = battle[doneKey] as int? ?? 0;

    await supabase.from('skill_mode_duo_battles').update({
      scoreKey: currentScore + score,
      timeKey: currentTime + timeMs,
      doneKey: currentDone + 1,
    }).eq('id', battleId);
  }

  /// Finish the battle — calculate winner.
  Future<SmDuoBattle> finishBattle(String battleId) async {
    final battle = await supabase
        .from('skill_mode_duo_battles')
        .select()
        .eq('id', battleId)
        .single();

    final aScore = battle['player_a_score'] as int? ?? 0;
    final bScore = battle['player_b_score'] as int? ?? 0;
    final aTime = battle['player_a_time_ms'] as int? ?? 0;
    final bTime = battle['player_b_time_ms'] as int? ?? 0;

    String? winnerId;
    bool isDraw = false;

    if (aScore > bScore) {
      winnerId = battle['player_a_id'] as String;
    } else if (bScore > aScore) {
      winnerId = battle['player_b_id'] as String?;
    } else {
      // Same score — fastest time wins
      if (aTime < bTime) {
        winnerId = battle['player_a_id'] as String;
      } else if (bTime < aTime) {
        winnerId = battle['player_b_id'] as String?;
      } else {
        isDraw = true;
      }
    }

    final data = await supabase.from('skill_mode_duo_battles').update({
      'status': 'finished',
      'finished_at': DateTime.now().toIso8601String(),
      'winner_id': winnerId,
      'is_draw': isDraw,
    }).eq('id', battleId).select().single();

    // Update stats for both players
    final playerAId = battle['player_a_id'] as String;
    final playerBId = battle['player_b_id'] as String?;

    if (playerBId != null) {
      await _updateDuoStats(
        userId: playerAId,
        won: winnerId == playerAId,
        isDraw: isDraw,
      );
      await _updateDuoStats(
        userId: playerBId,
        won: winnerId == playerBId,
        isDraw: isDraw,
      );

      // Award XP
      final winnerXp = 50;
      final loserXp = 15;
      final drawXp = 25;

      if (isDraw) {
        await _awardXp(playerAId, drawXp, 'skill_mode_duo_draw');
        await _awardXp(playerBId, drawXp, 'skill_mode_duo_draw');
      } else if (winnerId != null) {
        await _awardXp(winnerId, winnerXp, 'skill_mode_duo_win');
        final loserId = winnerId == playerAId ? playerBId : playerAId;
        await _awardXp(loserId, loserXp, 'skill_mode_duo_loss');
      }
    }

    return SmDuoBattle.fromJson(data);
  }

  /// Abandon a waiting/active battle.
  Future<void> abandonBattle(String battleId) async {
    await supabase.from('skill_mode_duo_battles').update({
      'status': 'abandoned',
      'finished_at': DateTime.now().toIso8601String(),
    }).eq('id', battleId);
  }

  // ── Stats ──

  /// Get user's duo battle stats.
  Future<SmDuoStats?> getStats(String userId) async {
    final data = await supabase
        .from('skill_mode_duo_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return data != null ? SmDuoStats.fromJson(data) : null;
  }

  /// Get recent battles for a user.
  Future<List<SmDuoBattle>> getRecentBattles({
    required String userId,
    int limit = 10,
  }) async {
    final data = await supabase
        .from('skill_mode_duo_battles')
        .select()
        .or('player_a_id.eq.$userId,player_b_id.eq.$userId')
        .eq('status', 'finished')
        .order('finished_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => SmDuoBattle.fromJson(e)).toList();
  }

  // ── Private helpers ──

  Future<List<String>> _pickRandomCards({
    required String language,
    required int count,
  }) async {
    final data = await supabase
        .from('skill_mode_cards')
        .select('id')
        .eq('language', language);

    final allIds = (data as List).map((e) => e['id'] as String).toList();
    allIds.shuffle(Random());
    return allIds.take(count).toList();
  }

  Future<void> _updateDuoStats({
    required String userId,
    required bool won,
    required bool isDraw,
  }) async {
    final existing = await supabase
        .from('skill_mode_duo_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('skill_mode_duo_stats').insert({
        'user_id': userId,
        'total_battles': 1,
        'wins': won ? 1 : 0,
        'losses': (!won && !isDraw) ? 1 : 0,
        'draws': isDraw ? 1 : 0,
        'win_streak': won ? 1 : 0,
        'best_win_streak': won ? 1 : 0,
      });
    } else {
      final currentStreak = existing['win_streak'] as int? ?? 0;
      final bestStreak = existing['best_win_streak'] as int? ?? 0;
      final newStreak = won ? currentStreak + 1 : 0;

      await supabase.from('skill_mode_duo_stats').update({
        'total_battles': (existing['total_battles'] as int? ?? 0) + 1,
        'wins': (existing['wins'] as int? ?? 0) + (won ? 1 : 0),
        'losses': (existing['losses'] as int? ?? 0) + ((!won && !isDraw) ? 1 : 0),
        'draws': (existing['draws'] as int? ?? 0) + (isDraw ? 1 : 0),
        'win_streak': newStreak,
        'best_win_streak': max(newStreak, bestStreak),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    }
  }

  Future<void> _awardXp(String userId, int xp, String reason) async {
    await supabase.from('xp_events').insert({
      'user_id': userId,
      'xp': xp,
      'reason': reason,
    });
  }
}
