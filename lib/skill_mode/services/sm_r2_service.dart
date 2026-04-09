/// Cloudflare R2 presigned URL helpers for Skill Mode audio.
/// Wired in SM-2.3 when audio integration is built.
class SmR2Service {
  /// Get audio URL for a card.
  String getAudioUrl(String cardId, String language) {
    // TODO(SM-2.3): implement presigned URL generation
    return '';
  }

  /// Upload temp audio for pronunciation scoring.
  Future<String> uploadTempAudio(String localPath) async {
    // TODO(SM-4): implement temp upload for pronunciation
    return '';
  }

  /// Delete temp audio after scoring.
  Future<void> deleteTempAudio(String tempPath) async {
    // TODO(SM-4): implement temp cleanup
  }
}
