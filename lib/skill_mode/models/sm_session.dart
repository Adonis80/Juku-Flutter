/// Active Skill Mode session state.
class SmSession {
  final String id;
  final String userId;
  final String language;
  int cardsReviewed;
  int xpEarned;
  int comboPeak;
  final DateTime startedAt;
  DateTime? endedAt;

  SmSession({
    required this.id,
    required this.userId,
    required this.language,
    this.cardsReviewed = 0,
    this.xpEarned = 0,
    this.comboPeak = 0,
    DateTime? startedAt,
    this.endedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  factory SmSession.fromJson(Map<String, dynamic> json) {
    return SmSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      language: json['language'] as String,
      cardsReviewed: json['cards_reviewed'] as int? ?? 0,
      xpEarned: json['xp_earned'] as int? ?? 0,
      comboPeak: json['combo_peak'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
    );
  }
}
