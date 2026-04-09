/// Community translation model (SM-6).
class SmTranslation {
  final String id;
  final String? cardId;
  final String? songId;
  final int? lyricLineIndex;
  final String sourceText;
  final String translatedText;
  final String targetLanguage;
  final String? notes;
  final String translatorId;
  final bool isFirstTranslator;
  final bool isAiDraft;
  final String status; // 'pending' | 'verified' | 'rejected' | 'expert_verified'
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final int upvotes;
  final int downvotes;
  final int netScore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined fields (from profiles table)
  final String? translatorUsername;
  final String? translatorPhotoUrl;

  const SmTranslation({
    required this.id,
    this.cardId,
    this.songId,
    this.lyricLineIndex,
    required this.sourceText,
    required this.translatedText,
    this.targetLanguage = 'en',
    this.notes,
    required this.translatorId,
    this.isFirstTranslator = false,
    this.isAiDraft = false,
    this.status = 'pending',
    this.verifiedBy,
    this.verifiedAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.netScore = 0,
    required this.createdAt,
    this.updatedAt,
    this.translatorUsername,
    this.translatorPhotoUrl,
  });

  factory SmTranslation.fromJson(Map<String, dynamic> json) {
    // Handle joined profile data
    final profile = json['profiles'] as Map<String, dynamic>?;

    return SmTranslation(
      id: json['id'] as String,
      cardId: json['card_id'] as String?,
      songId: json['song_id'] as String?,
      lyricLineIndex: json['lyric_line_index'] as int?,
      sourceText: json['source_text'] as String? ?? '',
      translatedText: json['translated_text'] as String? ?? '',
      targetLanguage: json['target_language'] as String? ?? 'en',
      notes: json['notes'] as String?,
      translatorId: json['translator_id'] as String,
      isFirstTranslator: json['is_first_translator'] as bool? ?? false,
      isAiDraft: json['is_ai_draft'] as bool? ?? false,
      status: json['status'] as String? ?? 'pending',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      netScore: json['net_score'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      translatorUsername: profile?['username'] as String?,
      translatorPhotoUrl: profile?['photo_url'] as String?,
    );
  }

  bool get isVerified => status == 'verified' || status == 'expert_verified';
  bool get isExpertVerified => status == 'expert_verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

/// Translator stats / trust score model.
class SmTranslatorStats {
  final String id;
  final String userId;
  final String targetLanguage;
  final double trustScore;
  final int totalSubmissions;
  final int verifiedCount;
  final int rejectedCount;
  final int totalNetVotes;
  final String tier; // 'newcomer' | 'contributor' | 'trusted' | 'expert'
  final bool isNativeSpeaker;
  final DateTime? firstTranslationAt;

  const SmTranslatorStats({
    required this.id,
    required this.userId,
    this.targetLanguage = 'en',
    this.trustScore = 0,
    this.totalSubmissions = 0,
    this.verifiedCount = 0,
    this.rejectedCount = 0,
    this.totalNetVotes = 0,
    this.tier = 'newcomer',
    this.isNativeSpeaker = false,
    this.firstTranslationAt,
  });

  factory SmTranslatorStats.fromJson(Map<String, dynamic> json) {
    return SmTranslatorStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetLanguage: json['target_language'] as String? ?? 'en',
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0,
      totalSubmissions: json['total_submissions'] as int? ?? 0,
      verifiedCount: json['verified_count'] as int? ?? 0,
      rejectedCount: json['rejected_count'] as int? ?? 0,
      totalNetVotes: json['total_net_votes'] as int? ?? 0,
      tier: json['tier'] as String? ?? 'newcomer',
      isNativeSpeaker: json['is_native_speaker'] as bool? ?? false,
      firstTranslationAt: json['first_translation_at'] != null
          ? DateTime.parse(json['first_translation_at'] as String)
          : null,
    );
  }

  String get tierEmoji {
    switch (tier) {
      case 'expert':
        return '\u{1F451}'; // crown
      case 'trusted':
        return '\u{2B50}'; // star
      case 'contributor':
        return '\u{1F4DD}'; // memo
      default:
        return '\u{1F331}'; // seedling
    }
  }

  String get tierLabel {
    switch (tier) {
      case 'expert':
        return 'Expert Translator';
      case 'trusted':
        return 'Trusted Translator';
      case 'contributor':
        return 'Contributor';
      default:
        return 'Newcomer';
    }
  }
}
