// Song Translation Competition models (SM-13).

class SmCompetition {
  final String id;
  final String songId;
  final String title;
  final String? description;
  final String targetLanguage;
  final String status; // 'upcoming' | 'active' | 'voting' | 'completed'
  final DateTime startsAt;
  final DateTime submissionDeadline;
  final DateTime votingDeadline;
  final DateTime endsAt;
  final int maxEntries;
  final int entryCount;
  final int voteCount;
  final int prizePoolJuice;
  final int xpFirst;
  final int xpSecond;
  final int xpThird;
  final int xpParticipation;
  final String? createdBy;
  final String? winnerEntryId;
  final DateTime? createdAt;

  // Joined fields
  final String? songTitle;
  final String? songArtist;
  final String? songCoverUrl;
  final String? songLanguage;

  const SmCompetition({
    required this.id,
    required this.songId,
    required this.title,
    this.description,
    this.targetLanguage = 'en',
    this.status = 'upcoming',
    required this.startsAt,
    required this.submissionDeadline,
    required this.votingDeadline,
    required this.endsAt,
    this.maxEntries = 50,
    this.entryCount = 0,
    this.voteCount = 0,
    this.prizePoolJuice = 100,
    this.xpFirst = 200,
    this.xpSecond = 100,
    this.xpThird = 50,
    this.xpParticipation = 15,
    this.createdBy,
    this.winnerEntryId,
    this.createdAt,
    this.songTitle,
    this.songArtist,
    this.songCoverUrl,
    this.songLanguage,
  });

  factory SmCompetition.fromJson(Map<String, dynamic> json) {
    final song = json['skill_mode_songs'] as Map<String, dynamic>?;

    return SmCompetition(
      id: json['id'] as String,
      songId: json['song_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      targetLanguage: json['target_language'] as String? ?? 'en',
      status: json['status'] as String? ?? 'upcoming',
      startsAt: DateTime.parse(json['starts_at'] as String),
      submissionDeadline:
          DateTime.parse(json['submission_deadline'] as String),
      votingDeadline: DateTime.parse(json['voting_deadline'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      maxEntries: json['max_entries'] as int? ?? 50,
      entryCount: json['entry_count'] as int? ?? 0,
      voteCount: json['vote_count'] as int? ?? 0,
      prizePoolJuice: json['prize_pool_juice'] as int? ?? 100,
      xpFirst: json['xp_first'] as int? ?? 200,
      xpSecond: json['xp_second'] as int? ?? 100,
      xpThird: json['xp_third'] as int? ?? 50,
      xpParticipation: json['xp_participation'] as int? ?? 15,
      createdBy: json['created_by'] as String?,
      winnerEntryId: json['winner_entry_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      songTitle: song?['title'] as String?,
      songArtist: song?['artist'] as String?,
      songCoverUrl: song?['cover_url'] as String?,
      songLanguage: song?['language'] as String?,
    );
  }

  bool get isUpcoming => status == 'upcoming';
  bool get isActive => status == 'active';
  bool get isVoting => status == 'voting';
  bool get isCompleted => status == 'completed';
  bool get isFull => entryCount >= maxEntries;

  Duration get timeUntilStart => startsAt.difference(DateTime.now());
  Duration get timeUntilSubmissionEnd =>
      submissionDeadline.difference(DateTime.now());
  Duration get timeUntilVotingEnd =>
      votingDeadline.difference(DateTime.now());
}

class SmCompetitionEntry {
  final String id;
  final String competitionId;
  final String translatorId;
  final List<SmEntryLine> translations;
  final String? styleNote;
  final DateTime submittedAt;
  final int totalVotes;
  final double qualityScore;
  final int? rank;
  final int prizeJuice;
  final int prizeXp;

  // Joined fields
  final String? translatorUsername;
  final String? translatorPhotoUrl;

  const SmCompetitionEntry({
    required this.id,
    required this.competitionId,
    required this.translatorId,
    this.translations = const [],
    this.styleNote,
    required this.submittedAt,
    this.totalVotes = 0,
    this.qualityScore = 0,
    this.rank,
    this.prizeJuice = 0,
    this.prizeXp = 0,
    this.translatorUsername,
    this.translatorPhotoUrl,
  });

  factory SmCompetitionEntry.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final rawTranslations = json['translations'] as List? ?? [];

    return SmCompetitionEntry(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      translatorId: json['translator_id'] as String,
      translations: rawTranslations
          .map((t) =>
              SmEntryLine.fromJson(t as Map<String, dynamic>))
          .toList(),
      styleNote: json['style_note'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : DateTime.now(),
      totalVotes: json['total_votes'] as int? ?? 0,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0,
      rank: json['rank'] as int?,
      prizeJuice: json['prize_juice'] as int? ?? 0,
      prizeXp: json['prize_xp'] as int? ?? 0,
      translatorUsername: profile?['username'] as String?,
      translatorPhotoUrl: profile?['photo_url'] as String?,
    );
  }

  bool get isWinner => rank == 1;
  bool get isPodium => rank != null && rank! <= 3;
}

class SmEntryLine {
  final int lineIndex;
  final String sourceText;
  final String translatedText;
  final String? notes;

  const SmEntryLine({
    required this.lineIndex,
    required this.sourceText,
    required this.translatedText,
    this.notes,
  });

  factory SmEntryLine.fromJson(Map<String, dynamic> json) {
    return SmEntryLine(
      lineIndex: json['line_index'] as int? ?? 0,
      sourceText: json['source_text'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'line_index': lineIndex,
        'source_text': sourceText,
        'translated_text': translatedText,
        if (notes != null) 'notes': notes,
      };
}

class SmCompetitionVote {
  final String id;
  final String competitionId;
  final String entryId;
  final String voterId;
  final int score;
  final DateTime votedAt;

  const SmCompetitionVote({
    required this.id,
    required this.competitionId,
    required this.entryId,
    required this.voterId,
    required this.score,
    required this.votedAt,
  });

  factory SmCompetitionVote.fromJson(Map<String, dynamic> json) {
    return SmCompetitionVote(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      entryId: json['entry_id'] as String,
      voterId: json['voter_id'] as String,
      score: json['score'] as int? ?? 3,
      votedAt: json['voted_at'] != null
          ? DateTime.parse(json['voted_at'] as String)
          : DateTime.now(),
    );
  }
}
