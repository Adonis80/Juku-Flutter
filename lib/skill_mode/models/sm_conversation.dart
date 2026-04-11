// Models for AI Conversation Partner (GL-3).

class ConversationScenario {
  final String id;
  final String title;
  final String description;
  final String language;
  final String difficulty;
  final String iconName;
  final int sortOrder;

  const ConversationScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.difficulty,
    required this.iconName,
    required this.sortOrder,
  });

  factory ConversationScenario.fromJson(Map<String, dynamic> json) {
    return ConversationScenario(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      language: (json['language'] as String?) ?? 'de',
      difficulty: (json['difficulty'] as String?) ?? 'beginner',
      iconName: (json['icon_name'] as String?) ?? 'chat',
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }
}

class AiConversation {
  final String id;
  final String userId;
  final String? scenarioId;
  final String language;
  final String status;
  final int? fluencyScore;
  final int? vocabularyScore;
  final int? grammarScore;
  final int? overallScore;
  final int xpAwarded;
  final int turnCount;
  final int? durationSeconds;
  final DateTime createdAt;
  final DateTime? completedAt;
  final ConversationScenario? scenario;

  const AiConversation({
    required this.id,
    required this.userId,
    this.scenarioId,
    required this.language,
    required this.status,
    this.fluencyScore,
    this.vocabularyScore,
    this.grammarScore,
    this.overallScore,
    required this.xpAwarded,
    required this.turnCount,
    this.durationSeconds,
    required this.createdAt,
    this.completedAt,
    this.scenario,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scenarioId: json['scenario_id'] as String?,
      language: (json['language'] as String?) ?? 'de',
      status: (json['status'] as String?) ?? 'active',
      fluencyScore: json['fluency_score'] as int?,
      vocabularyScore: json['vocabulary_score'] as int?,
      grammarScore: json['grammar_score'] as int?,
      overallScore: json['overall_score'] as int?,
      xpAwarded: (json['xp_awarded'] as int?) ?? 0,
      turnCount: (json['turn_count'] as int?) ?? 0,
      durationSeconds: json['duration_seconds'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      scenario: json['ai_conversation_scenarios'] != null
          ? ConversationScenario.fromJson(
              json['ai_conversation_scenarios'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ConversationMessage {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final String? audioUrl;
  final String? transcription;
  final int? durationMs;
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.audioUrl,
    this.transcription,
    this.durationMs,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      audioUrl: json['audio_url'] as String?,
      transcription: json['transcription'] as String?,
      durationMs: json['duration_ms'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ConversationScores {
  final int fluency;
  final int vocabulary;
  final int grammar;
  final List<String> corrections;

  const ConversationScores({
    required this.fluency,
    required this.vocabulary,
    required this.grammar,
    required this.corrections,
  });

  int get overall => ((fluency + vocabulary + grammar) / 3).round();

  factory ConversationScores.fromJson(Map<String, dynamic> json) {
    return ConversationScores(
      fluency: (json['fluency'] as int?) ?? 0,
      vocabulary: (json['vocabulary'] as int?) ?? 0,
      grammar: (json['grammar'] as int?) ?? 0,
      corrections:
          (json['corrections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class AiApiKey {
  final String id;
  final String userId;
  final String provider;
  final bool isValid;
  final DateTime createdAt;

  const AiApiKey({
    required this.id,
    required this.userId,
    required this.provider,
    required this.isValid,
    required this.createdAt,
  });

  factory AiApiKey.fromJson(Map<String, dynamic> json) {
    return AiApiKey(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      provider: json['provider'] as String,
      isValid: (json['is_valid'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
