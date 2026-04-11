import '../../core/supabase_config.dart';

/// Model for a daily challenge.
class DailyChallenge {
  DailyChallenge({
    required this.id,
    required this.date,
    required this.language,
    required this.cardData,
    required this.cardType,
    required this.difficulty,
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map) {
    return DailyChallenge(
      id: map['id'] as String,
      date: map['challenge_date'] as String,
      language: map['language'] as String? ?? 'de',
      cardData: map['card_data'] as Map<String, dynamic>? ?? {},
      cardType: map['card_type'] as String? ?? 'text_flash',
      difficulty: map['difficulty'] as int? ?? 1,
    );
  }

  final String id;
  final String date;
  final String language;
  final Map<String, dynamic> cardData;
  final String cardType;
  final int difficulty;
}

/// Result of a challenge attempt.
class ChallengeResult {
  const ChallengeResult({
    required this.streak,
    required this.rank,
    required this.total,
    required this.xpEarned,
    required this.percentile,
  });

  factory ChallengeResult.fromMap(Map<String, dynamic> map) {
    return ChallengeResult(
      streak: map['streak'] as int? ?? 0,
      rank: map['rank'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      xpEarned: map['xp_earned'] as int? ?? 0,
      percentile: map['percentile'] as int? ?? 0,
    );
  }

  final int streak;
  final int rank;
  final int total;
  final int xpEarned;
  final int percentile;
}

/// Service for daily challenges.
class ChallengeService {
  ChallengeService._();
  static final instance = ChallengeService._();

  /// Get today's challenge for a language.
  Future<DailyChallenge?> getTodayChallenge({String language = 'de'}) async {
    final today = DateTime.now().toUtc().toIso8601String().split('T')[0];

    final data = await supabase
        .from('daily_challenges')
        .select()
        .eq('challenge_date', today)
        .eq('language', language)
        .maybeSingle();

    if (data == null) return null;
    return DailyChallenge.fromMap(data);
  }

  /// Check if the user has already attempted today's challenge.
  Future<bool> hasAttemptedToday(String challengeId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final data = await supabase
        .from('challenge_attempts')
        .select('id')
        .eq('user_id', user.id)
        .eq('challenge_id', challengeId)
        .maybeSingle();

    return data != null;
  }

  /// Submit an attempt. Returns the result with rank, streak, XP, etc.
  Future<ChallengeResult?> submitAttempt({
    required String challengeId,
    required int score,
    required int timeMs,
    required bool correct,
    required List<String> answers,
  }) async {
    final result = await supabase.rpc(
      'submit_challenge_attempt',
      params: {
        'p_challenge_id': challengeId,
        'p_score': score,
        'p_time_ms': timeMs,
        'p_correct': correct,
        'p_answers': answers,
      },
    );

    if (result == null) return null;
    final map = result as Map<String, dynamic>;
    if (map.containsKey('error')) return null;
    return ChallengeResult.fromMap(map);
  }

  /// Get the global leaderboard for a challenge.
  Future<List<Map<String, dynamic>>> getLeaderboard(String challengeId) async {
    final data = await supabase
        .from('challenge_attempts')
        .select(
          '*, profiles!challenge_attempts_user_id_fkey(display_name, username)',
        )
        .eq('challenge_id', challengeId)
        .order('score', ascending: false)
        .order('time_ms', ascending: true)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Get the user's current challenge streak.
  Future<int> getCurrentStreak() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;

    final data = await supabase
        .from('challenge_attempts')
        .select('streak_count')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return (data?['streak_count'] as int?) ?? 0;
  }
}
