/// Replicate API for Demucs v4 vocal isolation.
/// Music Mode only (v0.4+).
class SmDemucsService {
  /// Separate vocals from a song.
  Future<SmDemucsResult> separateVocals(String audioUrl) async {
    // TODO(SM-v0.4): implement Replicate API call
    return SmDemucsResult(vocalsUrl: '', instrumentalUrl: '');
  }
}

class SmDemucsResult {
  final String vocalsUrl;
  final String instrumentalUrl;

  const SmDemucsResult({
    required this.vocalsUrl,
    required this.instrumentalUrl,
  });
}
