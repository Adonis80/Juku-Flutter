/// Per-user spaced repetition state for a card.
class SmUserCard {
  final String id;
  final String userId;
  final String cardId;
  double easeFactor;
  int intervalDays;
  int repetitions;
  DateTime nextReviewAt;
  int? lastScorePct;
  DateTime? hintUsedAt;
  DateTime? transformUsedAt;
  bool masteryProven;
  bool suspended;
  DateTime? suspendedAt;

  SmUserCard({
    required this.id,
    required this.userId,
    required this.cardId,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    DateTime? nextReviewAt,
    this.lastScorePct,
    this.hintUsedAt,
    this.transformUsedAt,
    this.masteryProven = false,
    this.suspended = false,
    this.suspendedAt,
  }) : nextReviewAt = nextReviewAt ?? DateTime.now();

  factory SmUserCard.fromJson(Map<String, dynamic> json) {
    return SmUserCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardId: json['card_id'] as String,
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['interval_days'] as int? ?? 1,
      repetitions: json['repetitions'] as int? ?? 0,
      nextReviewAt: DateTime.parse(json['next_review_at'] as String),
      lastScorePct: json['last_score_pct'] as int?,
      masteryProven: json['mastery_proven'] as bool? ?? false,
      suspended: json['suspended'] as bool? ?? false,
    );
  }
}
