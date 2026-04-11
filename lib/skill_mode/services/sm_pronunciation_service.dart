import 'package:flutter/foundation.dart';

import '../../core/supabase_config.dart';

/// Client-side pronunciation scoring service (SM-4.1).
///
/// Uploads WAV to R2 temp path, calls score-pronunciation Edge Function,
/// returns phoneme-level scores.
///
/// Azure key is server-side only — never in client code.
class SmPronunciationService {
  SmPronunciationService._();
  static final instance = SmPronunciationService._();

  /// Score a pronunciation attempt.
  ///
  /// [wavPath] — local file path to the recorded WAV.
  /// [referenceText] — the text the user was supposed to say.
  /// [language] — BCP-47 code, e.g. 'de-DE'.
  ///
  /// Returns [SmPronunciationResult] or null on failure.
  Future<SmPronunciationResult?> score({
    required String wavPath,
    required String referenceText,
    required String language,
    required String userId,
    required String cardId,
  }) async {
    try {
      // 1. Upload WAV to R2 temp path via Edge Function.
      final tempPath = 'temp/$userId/$cardId.wav';

      // TODO(SM-4): Implement actual R2 upload via Edge Function.
      // For now, we pass the temp path and assume upload happened.

      // 2. Call score-pronunciation Edge Function.
      final response = await supabase.functions.invoke(
        'score-pronunciation',
        body: {
          'tempAudioPath': tempPath,
          'referenceText': referenceText,
          'language': language,
        },
      );

      if (response.status != 200) {
        debugPrint(
          'SmPronunciationService: Edge Function returned ${response.status}',
        );
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      return SmPronunciationResult.fromJson(data);
    } catch (e) {
      debugPrint('SmPronunciationService: scoring failed — $e');
      return null;
    }
  }
}

/// Pronunciation scoring result.
class SmPronunciationResult {
  final int overallScore;
  final String grade; // 'perfect' | 'good' | 'almost' | 'try_again'
  final List<SmPhonemeScore> phonemes;

  const SmPronunciationResult({
    required this.overallScore,
    required this.grade,
    required this.phonemes,
  });

  factory SmPronunciationResult.fromJson(Map<String, dynamic> json) {
    return SmPronunciationResult(
      overallScore: json['overallScore'] as int? ?? 0,
      grade: json['grade'] as String? ?? 'try_again',
      phonemes:
          (json['phonemes'] as List?)
              ?.map((p) => SmPhonemeScore.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get tile indices with weak pronunciation (score < 60).
  List<int> get weakTileIndices {
    final weakTiles = <int>{};
    for (final p in phonemes) {
      if (p.score < 60) {
        weakTiles.add(p.tileIndex);
      }
    }
    return weakTiles.toList()..sort();
  }

  /// XP tier based on score.
  int get xpReward {
    if (overallScore >= 90) return 15;
    if (overallScore >= 70) return 10;
    if (overallScore >= 50) return 5;
    return 0;
  }
}

/// Individual phoneme score.
class SmPhonemeScore {
  final String phoneme;
  final int score;
  final int tileIndex;

  const SmPhonemeScore({
    required this.phoneme,
    required this.score,
    required this.tileIndex,
  });

  factory SmPhonemeScore.fromJson(Map<String, dynamic> json) {
    return SmPhonemeScore(
      phoneme: json['phoneme'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      tileIndex: json['tileIndex'] as int? ?? 0,
    );
  }
}
