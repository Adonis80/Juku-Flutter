import '../../core/supabase_config.dart';
import '../models/sm_competition.dart';

/// Service for song translation competitions (SM-13).
class SmCompetitionService {
  /// Fetch competitions by status, with song join.
  Future<List<SmCompetition>> fetchCompetitions({
    List<String> statuses = const ['active', 'voting', 'upcoming'],
  }) async {
    final data = await supabase
        .from('skill_mode_translation_competitions')
        .select('*, skill_mode_songs(title, artist, cover_url, language)')
        .inFilter('status', statuses)
        .order('starts_at', ascending: false);

    return (data as List).map((j) => SmCompetition.fromJson(j)).toList();
  }

  /// Fetch a single competition by ID.
  Future<SmCompetition> fetchCompetition(String id) async {
    final data = await supabase
        .from('skill_mode_translation_competitions')
        .select('*, skill_mode_songs(title, artist, cover_url, language)')
        .eq('id', id)
        .single();

    return SmCompetition.fromJson(data);
  }

  /// Fetch entries for a competition, ranked by quality score.
  Future<List<SmCompetitionEntry>> fetchEntries(String competitionId) async {
    final data = await supabase
        .from('skill_mode_competition_entries')
        .select('*, profiles(username, photo_url)')
        .eq('competition_id', competitionId)
        .order('quality_score', ascending: false);

    return (data as List).map((j) => SmCompetitionEntry.fromJson(j)).toList();
  }

  /// Fetch the current user's entry for a competition (null if none).
  Future<SmCompetitionEntry?> fetchMyEntry(String competitionId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await supabase
        .from('skill_mode_competition_entries')
        .select('*, profiles(username, photo_url)')
        .eq('competition_id', competitionId)
        .eq('translator_id', userId)
        .maybeSingle();

    return data != null ? SmCompetitionEntry.fromJson(data) : null;
  }

  /// Submit or update an entry.
  Future<SmCompetitionEntry> submitEntry({
    required String competitionId,
    required List<SmEntryLine> translations,
    String? styleNote,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('skill_mode_competition_entries')
        .upsert({
          'competition_id': competitionId,
          'translator_id': userId,
          'translations': translations.map((t) => t.toJson()).toList(),
          'style_note': styleNote,
          'submitted_at': DateTime.now().toIso8601String(),
        }, onConflict: 'competition_id,translator_id')
        .select('*, profiles(username, photo_url)')
        .single();

    // Increment entry count on competition.
    await supabase
        .rpc(
          'increment_field',
          params: {
            'table_name': 'skill_mode_translation_competitions',
            'row_id': competitionId,
            'field_name': 'entry_count',
          },
        )
        .catchError((_) {
          // RPC may not exist yet — competition entry count updated via trigger.
        });

    return SmCompetitionEntry.fromJson(data);
  }

  /// Cast a vote on an entry (1–5 stars). Upserts.
  Future<void> vote({
    required String competitionId,
    required String entryId,
    required int score,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('skill_mode_competition_votes').upsert({
      'competition_id': competitionId,
      'entry_id': entryId,
      'voter_id': userId,
      'score': score,
      'voted_at': DateTime.now().toIso8601String(),
    }, onConflict: 'entry_id,voter_id');

    // Recompute quality score for the entry.
    final votes = await supabase
        .from('skill_mode_competition_votes')
        .select('score')
        .eq('entry_id', entryId);

    final voteList = votes as List;
    if (voteList.isNotEmpty) {
      final total = voteList.fold<int>(
        0,
        (sum, v) => sum + (v['score'] as int),
      );
      final avg = total / voteList.length;

      await supabase
          .from('skill_mode_competition_entries')
          .update({'total_votes': voteList.length, 'quality_score': avg})
          .eq('id', entryId);
    }
  }

  /// Fetch votes the current user has cast in a competition.
  Future<Map<String, int>> fetchMyVotes(String competitionId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final data = await supabase
        .from('skill_mode_competition_votes')
        .select('entry_id, score')
        .eq('competition_id', competitionId)
        .eq('voter_id', userId);

    final map = <String, int>{};
    for (final v in data as List) {
      map[v['entry_id'] as String] = v['score'] as int;
    }
    return map;
  }

  /// Create a new competition (creator action).
  Future<SmCompetition> createCompetition({
    required String songId,
    required String title,
    String? description,
    String targetLanguage = 'en',
    required DateTime startsAt,
    required DateTime submissionDeadline,
    required DateTime votingDeadline,
    required DateTime endsAt,
    int prizePoolJuice = 100,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('skill_mode_translation_competitions')
        .insert({
          'song_id': songId,
          'title': title,
          'description': description,
          'target_language': targetLanguage,
          'starts_at': startsAt.toIso8601String(),
          'submission_deadline': submissionDeadline.toIso8601String(),
          'voting_deadline': votingDeadline.toIso8601String(),
          'ends_at': endsAt.toIso8601String(),
          'prize_pool_juice': prizePoolJuice,
          'created_by': userId,
        })
        .select('*, skill_mode_songs(title, artist, cover_url, language)')
        .single();

    return SmCompetition.fromJson(data);
  }

  /// Fetch song lyrics for a given song (for the entry editor).
  Future<List<Map<String, dynamic>>> fetchSongLyrics(String songId) async {
    final data = await supabase
        .from('skill_mode_lyrics')
        .select()
        .eq('song_id', songId)
        .order('timestamp_ms');

    return (data as List).cast<Map<String, dynamic>>();
  }
}
