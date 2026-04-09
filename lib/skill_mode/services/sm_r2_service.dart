/// Cloudflare R2 URL helpers for Skill Mode audio.
///
/// Audio files stored at: {R2_PUBLIC_URL}/cards/{language}/{cardId}.mp3
/// R2 bucket: skill-mode-audio
/// Public URL pattern uses the R2 custom domain or dev endpoint.
class SmR2Service {
  SmR2Service._();
  static final instance = SmR2Service._();

  /// Base public URL for the R2 bucket.
  /// In production this is a custom domain; for now, use the R2 public dev URL.
  /// MANUAL (Dhayan): Set R2 public access or custom domain, then update this.
  static const _baseUrl =
      'https://pub-skill-mode-audio.r2.dev';

  /// Get the public audio URL for a card.
  ///
  /// Path convention: /cards/{language}/{cardId}.mp3
  String getAudioUrl(String cardId, String language) {
    return '$_baseUrl/cards/$language/$cardId.mp3';
  }

  /// Get the cleaned audio URL (from ElevenLabs Voice Isolator).
  String getCleanedAudioUrl(String cardId, String language) {
    return '$_baseUrl/cards/$language/${cardId}_cleaned.mp3';
  }

  /// Get temp upload path for pronunciation scoring (SM-4).
  String getTempUploadPath(String userId, String cardId) {
    return 'temp/$userId/$cardId.wav';
  }

  /// Upload temp audio for pronunciation scoring.
  Future<String> uploadTempAudio(String localPath) async {
    // TODO(SM-4): implement temp upload for pronunciation via Edge Function
    return '';
  }

  /// Delete temp audio after scoring.
  Future<void> deleteTempAudio(String tempPath) async {
    // TODO(SM-4): implement temp cleanup
  }
}
