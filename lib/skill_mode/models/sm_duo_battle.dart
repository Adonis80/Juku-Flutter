/// Duo Battle model — real-time race between two players (SM-8).
class SmDuoBattle {
  final String id;
  final String playerAId;
  final String? playerBId;
  final String language;
  final int cardCount;
  final String? deckId;
  final String status; // 'waiting' | 'matched' | 'countdown' | 'active' | 'finished' | 'abandoned'
  final int playerAScore;
  final int playerBScore;
  final int playerATimeMs;
  final int playerBTimeMs;
  final int playerACardsDone;
  final int playerBCardsDone;
  final String? winnerId;
  final bool isDraw;
  final List<String> cardIds;
  final DateTime? matchedAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const SmDuoBattle({
    required this.id,
    required this.playerAId,
    this.playerBId,
    required this.language,
    this.cardCount = 10,
    this.deckId,
    this.status = 'waiting',
    this.playerAScore = 0,
    this.playerBScore = 0,
    this.playerATimeMs = 0,
    this.playerBTimeMs = 0,
    this.playerACardsDone = 0,
    this.playerBCardsDone = 0,
    this.winnerId,
    this.isDraw = false,
    this.cardIds = const [],
    this.matchedAt,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
    this.expiresAt,
  });

  factory SmDuoBattle.fromJson(Map<String, dynamic> json) {
    return SmDuoBattle(
      id: json['id'] as String,
      playerAId: json['player_a_id'] as String,
      playerBId: json['player_b_id'] as String?,
      language: json['language'] as String? ?? 'de',
      cardCount: json['card_count'] as int? ?? 10,
      deckId: json['deck_id'] as String?,
      status: json['status'] as String? ?? 'waiting',
      playerAScore: json['player_a_score'] as int? ?? 0,
      playerBScore: json['player_b_score'] as int? ?? 0,
      playerATimeMs: json['player_a_time_ms'] as int? ?? 0,
      playerBTimeMs: json['player_b_time_ms'] as int? ?? 0,
      playerACardsDone: json['player_a_cards_done'] as int? ?? 0,
      playerBCardsDone: json['player_b_cards_done'] as int? ?? 0,
      winnerId: json['winner_id'] as String?,
      isDraw: json['is_draw'] as bool? ?? false,
      cardIds: (json['card_ids'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  bool get isFinished => status == 'finished';

  bool isPlayerA(String userId) => playerAId == userId;

  int myScore(String userId) =>
      isPlayerA(userId) ? playerAScore : playerBScore;

  int opponentScore(String userId) =>
      isPlayerA(userId) ? playerBScore : playerAScore;

  int myCardsDone(String userId) =>
      isPlayerA(userId) ? playerACardsDone : playerBCardsDone;

  int opponentCardsDone(String userId) =>
      isPlayerA(userId) ? playerBCardsDone : playerACardsDone;
}

/// Per-card result in a duo battle.
class SmDuoRound {
  final String id;
  final String battleId;
  final String playerId;
  final String cardId;
  final int roundIndex;
  final bool correct;
  final int timeMs;
  final int score;

  const SmDuoRound({
    required this.id,
    required this.battleId,
    required this.playerId,
    required this.cardId,
    required this.roundIndex,
    this.correct = false,
    required this.timeMs,
    this.score = 0,
  });

  factory SmDuoRound.fromJson(Map<String, dynamic> json) {
    return SmDuoRound(
      id: json['id'] as String,
      battleId: json['battle_id'] as String,
      playerId: json['player_id'] as String,
      cardId: json['card_id'] as String,
      roundIndex: json['round_index'] as int? ?? 0,
      correct: json['correct'] as bool? ?? false,
      timeMs: json['time_ms'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
    );
  }
}

/// User's duo battle stats.
class SmDuoStats {
  final String id;
  final String userId;
  final int totalBattles;
  final int wins;
  final int losses;
  final int draws;
  final int winStreak;
  final int bestWinStreak;
  final int totalXpEarned;
  final int eloRating;

  const SmDuoStats({
    required this.id,
    required this.userId,
    this.totalBattles = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.winStreak = 0,
    this.bestWinStreak = 0,
    this.totalXpEarned = 0,
    this.eloRating = 1000,
  });

  factory SmDuoStats.fromJson(Map<String, dynamic> json) {
    return SmDuoStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalBattles: json['total_battles'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      winStreak: json['win_streak'] as int? ?? 0,
      bestWinStreak: json['best_win_streak'] as int? ?? 0,
      totalXpEarned: json['total_xp_earned'] as int? ?? 0,
      eloRating: json['elo_rating'] as int? ?? 1000,
    );
  }

  double get winRate =>
      totalBattles > 0 ? wins / totalBattles : 0;
}
