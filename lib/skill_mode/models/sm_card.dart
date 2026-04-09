/// Skill Mode card model — represents a vocabulary or sentence card.
class SmCard {
  final String id;
  final String language;
  final String foreignText;
  final String nativeText;
  final String? romanization;
  final String? audioUrl;
  final String tileType; // 'standard' | 'ghost' | 'compound' | 'inflected' | 'particle'
  final String cardType; // 'word' | 'sentence'
  final int difficulty;
  final String? partOfSpeech;
  final Map<String, dynamic> grammarMetadata;
  final Map<String, dynamic> tileConfig;
  final List<Map<String, dynamic>>? sentenceTiles;
  final List<int>? nativeWordOrder;
  final List<int>? foreignWordOrder;
  final List<String> tags;
  final String? deckId;

  const SmCard({
    required this.id,
    required this.language,
    required this.foreignText,
    required this.nativeText,
    this.romanization,
    this.audioUrl,
    this.tileType = 'standard',
    this.cardType = 'word',
    this.difficulty = 1,
    this.partOfSpeech,
    this.grammarMetadata = const {},
    this.tileConfig = const {},
    this.sentenceTiles,
    this.nativeWordOrder,
    this.foreignWordOrder,
    this.tags = const [],
    this.deckId,
  });

  factory SmCard.fromJson(Map<String, dynamic> json) {
    return SmCard(
      id: json['id'] as String,
      language: json['language'] as String,
      foreignText: json['foreign_text'] as String,
      nativeText: json['native_text'] as String,
      romanization: json['romanization'] as String?,
      audioUrl: json['audio_url'] as String?,
      tileType: json['tile_type'] as String? ?? 'standard',
      cardType: json['card_type'] as String? ?? 'word',
      difficulty: json['difficulty'] as int? ?? 1,
      partOfSpeech: json['part_of_speech'] as String?,
      grammarMetadata:
          Map<String, dynamic>.from(json['grammar_metadata'] as Map? ?? {}),
      tileConfig:
          Map<String, dynamic>.from(json['tile_config'] as Map? ?? {}),
      sentenceTiles: (json['sentence_tiles'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      nativeWordOrder: (json['native_word_order'] as List?)
          ?.map((e) => e as int)
          .toList(),
      foreignWordOrder: (json['foreign_word_order'] as List?)
          ?.map((e) => e as int)
          .toList(),
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      deckId: json['deck_id'] as String?,
    );
  }
}
