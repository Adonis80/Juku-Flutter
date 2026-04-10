/// Challenge Mode model — send a card/deck to a friend, beat my score (SM-9).
class SmChallenge {
  final String id;
  final String challengerId;
  final String challengedId;
  final String? cardId;
  final String? deckId;
  final String language;
  final int challengerScore;
  final int challengerTimeMs;
  final int? challengedScore;
  final int? challengedTimeMs;
  final String status; // 'pending' | 'accepted' | 'completed' | 'declined' | 'expired'
  final String? winnerId;
  final String? tauntMessage;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  // Joined profile fields
  final String? challengerUsername;
  final String? challengerPhotoUrl;
  final String? challengedUsername;
  final String? challengedPhotoUrl;

  const SmChallenge({
    required this.id,
    required this.challengerId,
    required this.challengedId,
    this.cardId,
    this.deckId,
    required this.language,
    required this.challengerScore,
    required this.challengerTimeMs,
    this.challengedScore,
    this.challengedTimeMs,
    this.status = 'pending',
    this.winnerId,
    this.tauntMessage,
    this.expiresAt,
    this.acceptedAt,
    this.completedAt,
    required this.createdAt,
    this.challengerUsername,
    this.challengerPhotoUrl,
    this.challengedUsername,
    this.challengedPhotoUrl,
  });

  factory SmChallenge.fromJson(Map<String, dynamic> json) {
    final challengerProfile =
        json['challenger_profile'] as Map<String, dynamic>?;
    final challengedProfile =
        json['challenged_profile'] as Map<String, dynamic>?;

    return SmChallenge(
      id: json['id'] as String,
      challengerId: json['challenger_id'] as String,
      challengedId: json['challenged_id'] as String,
      cardId: json['card_id'] as String?,
      deckId: json['deck_id'] as String?,
      language: json['language'] as String? ?? 'de',
      challengerScore: json['challenger_score'] as int? ?? 0,
      challengerTimeMs: json['challenger_time_ms'] as int? ?? 0,
      challengedScore: json['challenged_score'] as int?,
      challengedTimeMs: json['challenged_time_ms'] as int?,
      status: json['status'] as String? ?? 'pending',
      winnerId: json['winner_id'] as String?,
      tauntMessage: json['taunt_message'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      challengerUsername: challengerProfile?['username'] as String?,
      challengerPhotoUrl: challengerProfile?['photo_url'] as String?,
      challengedUsername: challengedProfile?['username'] as String?,
      challengedPhotoUrl: challengedProfile?['photo_url'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isExpired =>
      status == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));

  bool didChallengerWin() => winnerId == challengerId;
  bool didChallengedWin() => winnerId == challengedId;
}
