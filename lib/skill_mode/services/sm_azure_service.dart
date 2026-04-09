/// Azure Pronunciation Assessment — calls Supabase Edge Function.
/// Server-side only. Wired in SM-4.
class SmAzureService {
  /// Score pronunciation via Edge Function.
  /// Returns phoneme-level scores mapped to tile indices.
  Future<SmPronunciationResult> scorePronunciation({
    required String tempAudioPath,
    required String referenceText,
    required String language,
  }) async {
    // TODO(SM-4): call score-pronunciation Edge Function
    return SmPronunciationResult(
      overallScore: 0,
      grade: 'pending',
      phonemes: [],
    );
  }
}

class SmPronunciationResult {
  final int overallScore;
  final String grade;
  final List<SmPhonemeScore> phonemes;

  const SmPronunciationResult({
    required this.overallScore,
    required this.grade,
    required this.phonemes,
  });
}

class SmPhonemeScore {
  final String phoneme;
  final int score;
  final int tileIndex;

  const SmPhonemeScore({
    required this.phoneme,
    required this.score,
    required this.tileIndex,
  });
}
