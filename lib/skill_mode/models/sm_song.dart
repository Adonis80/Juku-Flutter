/// Music Mode song model (SM-5).
class SmSong {
  final String id;
  final String? uploaderId;
  final String title;
  final String artist;
  final String language;
  final String? genre;
  final String? difficulty;
  final int? durationSecs;
  final String? audioUrl;
  final String? vocalsUrl;
  final String? instrumentalUrl;
  final String? coverUrl;
  final int playCount;
  final int lineCount;
  final List<String> tags;
  final DateTime? createdAt;

  const SmSong({
    required this.id,
    this.uploaderId,
    required this.title,
    required this.artist,
    required this.language,
    this.genre,
    this.difficulty,
    this.durationSecs,
    this.audioUrl,
    this.vocalsUrl,
    this.instrumentalUrl,
    this.coverUrl,
    this.playCount = 0,
    this.lineCount = 0,
    this.tags = const [],
    this.createdAt,
  });

  factory SmSong.fromJson(Map<String, dynamic> json) {
    return SmSong(
      id: json['id'] as String,
      uploaderId: json['uploaded_by'] as String?,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      language: json['language'] as String? ?? 'de',
      genre: json['genre'] as String?,
      difficulty: json['difficulty'] as String?,
      durationSecs: json['duration_secs'] as int?,
      audioUrl: json['audio_url'] as String?,
      vocalsUrl: json['vocals_url'] as String?,
      instrumentalUrl: json['instrumental_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      playCount: json['play_count'] as int? ?? 0,
      lineCount: json['line_count'] as int? ?? 0,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
