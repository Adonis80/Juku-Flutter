import '../../core/supabase_config.dart';

/// Streak system for Skill Mode (SM-3.3).
///
/// Rules:
/// - 10+ cards reviewed in a session = streak day counts
/// - 48-hour grace period (not 24) before streak resets
/// - Auto-consume streak_freezes if streak would break
/// - Milestones at 7, 30, 100, 365 days
class SmStreakService {
  SmStreakService._();
  static final instance = SmStreakService._();

  static const _minCardsForStreak = 10;
  static const _gracePeriodHours = 48;
  static const _milestones = [7, 30, 100, 365];

  /// Called on session end. Updates streak if enough cards were reviewed.
  ///
  /// Returns the current streak state and any milestone hit.
  Future<SmStreakResult> onSessionEnd({
    required String userId,
    required String language,
    required int cardsReviewed,
  }) async {
    if (cardsReviewed < _minCardsForStreak) {
      return const SmStreakResult(streakDays: 0, milestoneHit: null);
    }

    try {
      // Fetch current user language progress.
      final data = await supabase
          .from('skill_mode_user_languages')
          .select()
          .eq('user_id', userId)
          .eq('language', language)
          .maybeSingle();

      if (data == null) {
        // First session — create entry with streak = 1.
        await supabase.from('skill_mode_user_languages').insert({
          'user_id': userId,
          'language': language,
          'streak_days': 1,
          'last_session_at': DateTime.now().toIso8601String(),
          'total_cards_seen': cardsReviewed,
        });
        return const SmStreakResult(streakDays: 1, milestoneHit: null);
      }

      final lastSessionAt = data['last_session_at'] as String?;
      var streakDays = data['streak_days'] as int? ?? 0;
      final streakFreezes = data['streak_freezes'] as int? ?? 0;

      if (lastSessionAt != null) {
        final lastSession = DateTime.parse(lastSessionAt);
        final hoursSince = DateTime.now().difference(lastSession).inHours;

        if (hoursSince <= _gracePeriodHours) {
          // Within grace period — check if it's a new calendar day.
          final lastDate = DateTime(
            lastSession.year,
            lastSession.month,
            lastSession.day,
          );
          final today = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          );
          if (today.isAfter(lastDate)) {
            streakDays++;
          }
          // Same day = streak stays the same (already counted).
        } else {
          // Streak would break — try to use a freeze.
          final daysMissed =
              (hoursSince / 24).ceil() - 1; // days missed beyond grace
          if (streakFreezes > 0 && daysMissed <= streakFreezes) {
            // Consume freezes for missed days.
            await supabase
                .from('skill_mode_user_languages')
                .update({'streak_freezes': streakFreezes - daysMissed})
                .eq('user_id', userId)
                .eq('language', language);
            streakDays++;
          } else {
            // Streak resets.
            streakDays = 1;
          }
        }
      } else {
        streakDays = 1;
      }

      // Update.
      final totalCardsSeen =
          (data['total_cards_seen'] as int? ?? 0) + cardsReviewed;
      await supabase
          .from('skill_mode_user_languages')
          .update({
            'streak_days': streakDays,
            'last_session_at': DateTime.now().toIso8601String(),
            'total_cards_seen': totalCardsSeen,
          })
          .eq('user_id', userId)
          .eq('language', language);

      // Check for milestone.
      int? milestone;
      for (final m in _milestones) {
        if (streakDays == m) {
          milestone = m;
          break;
        }
      }

      return SmStreakResult(streakDays: streakDays, milestoneHit: milestone);
    } catch (_) {
      return const SmStreakResult(streakDays: 0, milestoneHit: null);
    }
  }

  /// Get current streak for a user + language.
  Future<int> getStreak({
    required String userId,
    required String language,
  }) async {
    try {
      final data = await supabase
          .from('skill_mode_user_languages')
          .select('streak_days, last_session_at')
          .eq('user_id', userId)
          .eq('language', language)
          .maybeSingle();

      if (data == null) return 0;

      final lastSessionAt = data['last_session_at'] as String?;
      if (lastSessionAt == null) return 0;

      // Check if streak is still alive.
      final hoursSince = DateTime.now()
          .difference(DateTime.parse(lastSessionAt))
          .inHours;
      if (hoursSince > _gracePeriodHours) return 0;

      return data['streak_days'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

/// Result from streak update.
class SmStreakResult {
  final int streakDays;
  final int? milestoneHit;

  const SmStreakResult({required this.streakDays, this.milestoneHit});
}
