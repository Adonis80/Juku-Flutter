import '../../core/supabase_config.dart';

/// Earnable items service — streak freeze, XP booster (SM-11).
class SmItemsService {
  /// Get user's items by type.
  Future<List<Map<String, dynamic>>> getItems({
    required String userId,
    String? itemType,
  }) async {
    var query = supabase
        .from('skill_mode_items')
        .select()
        .eq('user_id', userId);

    if (itemType != null) {
      query = query.eq('item_type', itemType);
    }

    return List<Map<String, dynamic>>.from(
      await query.order('created_at', ascending: false),
    );
  }

  /// Count available (inactive) items of a type.
  Future<int> countAvailable({
    required String userId,
    required String itemType,
  }) async {
    final data = await supabase
        .from('skill_mode_items')
        .select('id')
        .eq('user_id', userId)
        .eq('item_type', itemType)
        .eq('is_active', false);

    return (data as List).length;
  }

  /// Award an item to a user.
  Future<void> awardItem({
    required String userId,
    required String itemType,
    required String earnedVia,
    int quantity = 1,
    double multiplier = 2.0,
    int durationMins = 60,
  }) async {
    await supabase.from('skill_mode_items').insert({
      'user_id': userId,
      'item_type': itemType,
      'quantity': quantity,
      'multiplier': multiplier,
      'duration_mins': durationMins,
      'earned_via': earnedVia,
    });
  }

  /// Activate an XP Booster — sets is_active, activated_at, expires_at.
  Future<void> activateXpBooster({
    required String itemId,
  }) async {
    final item = await supabase
        .from('skill_mode_items')
        .select()
        .eq('id', itemId)
        .single();

    final durationMins = item['duration_mins'] as int? ?? 60;

    await supabase.from('skill_mode_items').update({
      'is_active': true,
      'activated_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now()
          .add(Duration(minutes: durationMins))
          .toIso8601String(),
    }).eq('id', itemId);
  }

  /// Get active XP booster for a user (if any).
  Future<Map<String, dynamic>?> getActiveBooster(String userId) async {
    return await supabase
        .from('skill_mode_items')
        .select()
        .eq('user_id', userId)
        .eq('item_type', 'xp_booster')
        .eq('is_active', true)
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();
  }

  /// Get active XP multiplier (1.0 if no booster active).
  Future<double> getXpMultiplier(String userId) async {
    final booster = await getActiveBooster(userId);
    if (booster == null) return 1.0;
    return (booster['multiplier'] as num?)?.toDouble() ?? 2.0;
  }

  /// Use a streak freeze (called by streak service when streak would break).
  Future<bool> useStreakFreeze(String userId) async {
    final freezes = await supabase
        .from('skill_mode_items')
        .select()
        .eq('user_id', userId)
        .eq('item_type', 'streak_freeze')
        .eq('is_active', false)
        .order('created_at')
        .limit(1)
        .maybeSingle();

    if (freezes == null) return false;

    await supabase.from('skill_mode_items').update({
      'is_active': true,
      'activated_at': DateTime.now().toIso8601String(),
    }).eq('id', freezes['id'] as String);

    return true;
  }

  /// Award items based on milestones.
  Future<void> checkMilestoneAwards({
    required String userId,
    int? streakDays,
    int? level,
    bool? challengeWon,
  }) async {
    // Streak milestones: freeze at 7, 14, 30, 60, 100 days
    if (streakDays != null) {
      final milestones = [7, 14, 30, 60, 100];
      if (milestones.contains(streakDays)) {
        await awardItem(
          userId: userId,
          itemType: 'streak_freeze',
          earnedVia: 'streak_milestone',
        );
      }
    }

    // Level up: XP booster every 5 levels
    if (level != null && level % 5 == 0) {
      await awardItem(
        userId: userId,
        itemType: 'xp_booster',
        earnedVia: 'level_up',
        durationMins: 60,
      );
    }

    // Challenge wins: streak freeze every 3rd win
    if (challengeWon == true) {
      // Count wins
      final wins = await supabase
          .from('skill_mode_challenges')
          .select('id')
          .eq('winner_id', userId);
      final winCount = (wins as List).length;
      if (winCount > 0 && winCount % 3 == 0) {
        await awardItem(
          userId: userId,
          itemType: 'streak_freeze',
          earnedVia: 'challenge_win',
        );
      }
    }
  }
}
