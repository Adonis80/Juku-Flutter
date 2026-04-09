/// Music Mode song model (v0.4+ stub).
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
  });
}
