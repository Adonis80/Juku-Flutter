import '../../core/constants.dart';
import '../../core/supabase_config.dart';

/// XP Engine for Skill Mode (SM-3.2).
///
/// Handles XP awarding with combo multipliers, level-up detection,
/// and writes to the shared `xp_events` table.
///
/// XP Sources:
/// - Card reveal: 5 XP
/// - Shuffle puzzle correct: 10 XP
/// - Conjugation dial lock: 5 XP
/// - Pronunciation ≥90%: 15 XP
/// - Pronunciation 70–89%: 10 XP
/// - Pronunciation 50–69%: 5 XP
/// - Session complete (10+ cards): 20 XP
/// - Perfect session (no wrong): 30 XP bonus
///
/// Combo multiplier: 3x = 1.5×, 5x = 2.0×, 10x = 3.0×.
class SmXpEngine {
  SmXpEngine._();
  static final instance = SmXpEngine._();

  /// Award XP for a Skill Mode action.
  ///
  /// Returns the adjusted XP (after combo multiplier) and whether
  /// a level-up occurred.
  Future<SmXpResult> awardXp({
    required String userId,
    required int baseAmount,
    required String reason,
    required int currentCombo,
  }) async {
    final multiplier = _comboMultiplier(currentCombo);
    final adjusted = (baseAmount * multiplier).round();

    // Insert into shared xp_events table.
    try {
      await supabase.from('xp_events').insert({
        'user_id': userId,
        'amount': adjusted,
        'reason': 'skill_mode_$reason',
      });
    } catch (_) {
      // Non-blocking — offline-first.
    }

    // Check for level-up.
    final levelUp = await _checkLevelUp(userId);

    return SmXpResult(
      awarded: adjusted,
      multiplier: multiplier,
      levelUp: levelUp,
    );
  }

  double _comboMultiplier(int combo) {
    if (combo >= 10) return 3.0;
    if (combo >= 5) return 2.0;
    if (combo >= 3) return 1.5;
    return 1.0;
  }

  /// Check if the user levelled up after the last XP award.
  Future<SmLevelUp?> _checkLevelUp(String userId) async {
    try {
      final profile = await supabase
          .from('profiles')
          .select('xp, level')
          .eq('id', userId)
          .single();

      final totalXp = profile['xp'] as int? ?? 0;
      final currentLevel = profile['level'] as int? ?? 1;
      final newLevel = _calculateLevel(totalXp);

      if (newLevel > currentLevel) {
        // Update profile.
        final newRank = rankForLevel(newLevel);
        await supabase
            .from('profiles')
            .update({'level': newLevel, 'rank': newRank})
            .eq('id', userId);

        return SmLevelUp(
          oldLevel: currentLevel,
          newLevel: newLevel,
          newRank: newRank,
        );
      }
    } catch (_) {
      // Non-blocking.
    }
    return null;
  }

  /// Calculate level from total XP.
  int _calculateLevel(int totalXp) {
    var xpRemaining = totalXp;
    var level = 1;
    while (xpRemaining >= xpForLevel(level)) {
      xpRemaining -= xpForLevel(level);
      level++;
    }
    return level;
  }
}

/// Result of an XP award.
class SmXpResult {
  final int awarded;
  final double multiplier;
  final SmLevelUp? levelUp;

  const SmXpResult({
    required this.awarded,
    required this.multiplier,
    this.levelUp,
  });
}

/// Level-up event data.
class SmLevelUp {
  final int oldLevel;
  final int newLevel;
  final String newRank;

  const SmLevelUp({
    required this.oldLevel,
    required this.newLevel,
    required this.newRank,
  });
}
