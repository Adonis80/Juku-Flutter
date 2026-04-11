import '../../core/supabase_config.dart';

/// Badge system for Skill Mode (SM-3.4).
///
/// 10 launch badges, triggered after each session.
/// Stored in `skill_mode_user_languages.unlocked_badges` as a JSON array.
class SmBadgeService {
  SmBadgeService._();
  static final instance = SmBadgeService._();

  /// All available badges.
  static const badges = <SmBadge>[
    SmBadge(
      id: 'first_steps',
      name: 'First Steps',
      description: 'Complete your first session',
      icon: '👣',
      rarity: SmBadgeRarity.common,
    ),
    SmBadge(
      id: 'perfect_session',
      name: 'Perfect Session',
      description: 'Complete a session with no mistakes',
      icon: '💎',
      rarity: SmBadgeRarity.rare,
    ),
    SmBadge(
      id: 'streak_7',
      name: 'Week Warrior',
      description: '7-day streak',
      icon: '🔥',
      rarity: SmBadgeRarity.common,
    ),
    SmBadge(
      id: 'streak_30',
      name: 'Streak Legend',
      description: '30-day streak',
      icon: '⚡',
      rarity: SmBadgeRarity.legendary,
    ),
    SmBadge(
      id: 'combo_10',
      name: 'Combo King',
      description: 'Reach a 10x combo',
      icon: '👑',
      rarity: SmBadgeRarity.rare,
    ),
    SmBadge(
      id: 'cards_100',
      name: 'Century',
      description: 'Review 100 cards total',
      icon: '📚',
      rarity: SmBadgeRarity.common,
    ),
    SmBadge(
      id: 'cards_500',
      name: 'Scholar',
      description: 'Review 500 cards total',
      icon: '🎓',
      rarity: SmBadgeRarity.rare,
    ),
    SmBadge(
      id: 'shuffle_master',
      name: 'Shuffle Master',
      description: 'Solve 50 shuffle puzzles',
      icon: '🧩',
      rarity: SmBadgeRarity.common,
    ),
    SmBadge(
      id: 'perfect_ear',
      name: 'Perfect Ear',
      description: 'Score 95%+ on pronunciation 10 times',
      icon: '👂',
      rarity: SmBadgeRarity.legendary,
    ),
    SmBadge(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete a session between midnight and 5am',
      icon: '🦉',
      rarity: SmBadgeRarity.common,
    ),
  ];

  /// Check and award badges after a session.
  ///
  /// Returns list of newly unlocked badges.
  Future<List<SmBadge>> checkBadges({
    required String userId,
    required String language,
    required int cardsReviewed,
    required int comboPeak,
    required int streakDays,
    required bool perfectSession,
  }) async {
    try {
      final data = await supabase
          .from('skill_mode_user_languages')
          .select('unlocked_badges, total_cards_seen')
          .eq('user_id', userId)
          .eq('language', language)
          .maybeSingle();

      if (data == null) return [];

      final existing = List<String>.from(
        (data['unlocked_badges'] as List?) ?? [],
      );
      final totalCards = data['total_cards_seen'] as int? ?? 0;
      final newBadges = <SmBadge>[];

      // Check each badge trigger.
      void tryUnlock(String id, bool condition) {
        if (!existing.contains(id) && condition) {
          existing.add(id);
          final badge = badges.firstWhere((b) => b.id == id);
          newBadges.add(badge);
        }
      }

      tryUnlock('first_steps', true); // Always true if session completed.
      tryUnlock('perfect_session', perfectSession);
      tryUnlock('streak_7', streakDays >= 7);
      tryUnlock('streak_30', streakDays >= 30);
      tryUnlock('combo_10', comboPeak >= 10);
      tryUnlock('cards_100', totalCards >= 100);
      tryUnlock('cards_500', totalCards >= 500);

      // Night owl: current time between midnight and 5am.
      final hour = DateTime.now().hour;
      tryUnlock('night_owl', hour >= 0 && hour < 5);

      // Shuffle master and perfect ear need cumulative tracking
      // that will be wired when those features track counts.

      if (newBadges.isNotEmpty) {
        await supabase
            .from('skill_mode_user_languages')
            .update({'unlocked_badges': existing})
            .eq('user_id', userId)
            .eq('language', language);
      }

      return newBadges;
    } catch (_) {
      return [];
    }
  }

  /// Get all unlocked badge IDs for a user.
  Future<List<String>> getUnlockedBadges({
    required String userId,
    required String language,
  }) async {
    try {
      final data = await supabase
          .from('skill_mode_user_languages')
          .select('unlocked_badges')
          .eq('user_id', userId)
          .eq('language', language)
          .maybeSingle();

      if (data == null) return [];
      return List<String>.from((data['unlocked_badges'] as List?) ?? []);
    } catch (_) {
      return [];
    }
  }
}

/// Badge definition.
class SmBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final SmBadgeRarity rarity;

  const SmBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
  });
}

/// Badge rarity — affects visual treatment.
enum SmBadgeRarity {
  common, // Standard shimmer
  rare, // Enhanced shimmer
  legendary, // Holographic ShaderMask shimmer
}
