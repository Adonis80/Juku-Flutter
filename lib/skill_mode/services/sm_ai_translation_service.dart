import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/supabase_config.dart';
import 'sm_translation_service.dart';

/// AI Draft translation cold-start (SM-6).
///
/// Generates draft translations using the user's BYOLLM key when no
/// community translation exists. Drafts are marked `is_ai_draft = true`
/// and start at 0 votes — community can verify/improve them.
class SmAiTranslationService {
  final _translationService = SmTranslationService();

  /// Generate an AI draft translation for a card if none exists.
  /// Returns the translation ID if created, null if one already exists.
  Future<String?> generateCardDraft({
    required String cardId,
    required String sourceText,
    required String sourceLanguage,
    String targetLanguage = 'en',
  }) async {
    // Check if any translation exists
    final existing = await _translationService.getCardTranslations(
      cardId: cardId,
      targetLanguage: targetLanguage,
    );
    if (existing.isNotEmpty) return null;

    final translation = await _generateTranslation(
      sourceText: sourceText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    if (translation == null) return null;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return _translationService.submitTranslation(
      translatorId: userId,
      sourceText: sourceText,
      translatedText: translation['text']!,
      cardId: cardId,
      targetLanguage: targetLanguage,
      notes: translation['notes'],
      isAiDraft: true,
    );
  }

  /// Generate an AI draft for a lyric line.
  Future<String?> generateLyricDraft({
    required String songId,
    required int lineIndex,
    required String sourceText,
    required String sourceLanguage,
    String targetLanguage = 'en',
  }) async {
    final existing = await _translationService.getLyricTranslations(
      songId: songId,
      lineIndex: lineIndex,
      targetLanguage: targetLanguage,
    );
    if (existing.isNotEmpty) return null;

    final translation = await _generateTranslation(
      sourceText: sourceText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    if (translation == null) return null;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return _translationService.submitTranslation(
      translatorId: userId,
      sourceText: sourceText,
      translatedText: translation['text']!,
      songId: songId,
      lyricLineIndex: lineIndex,
      targetLanguage: targetLanguage,
      notes: translation['notes'],
      isAiDraft: true,
    );
  }

  /// Call BYOLLM to generate a translation.
  Future<Map<String, String>?> _generateTranslation({
    required String sourceText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final profile = await supabase
        .from('profiles')
        .select('llm_provider, llm_api_key_encrypted')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return null;

    final provider = profile['llm_provider'] as String?;
    final encryptedKey = profile['llm_api_key_encrypted'] as String?;

    if (provider == null || encryptedKey == null || encryptedKey.isEmpty) {
      return null; // No BYOLLM key — silently skip
    }

    final apiKey = utf8.decode(base64Decode(encryptedKey));

    final prompt = 'Translate this $sourceLanguage text to $targetLanguage. '
        'Return ONLY a JSON object with "text" (the translation) and "notes" '
        '(a brief grammar or context note, max 1 sentence). '
        'Text to translate: "$sourceText"';

    try {
      final responseText = await _callLlm(
        provider: provider,
        apiKey: apiKey,
        prompt: prompt,
      );

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch == null) return null;

      final parsed =
          jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      return {
        'text': parsed['text'] as String? ?? sourceText,
        'notes': parsed['notes'] as String? ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  Future<String> _callLlm({
    required String provider,
    required String apiKey,
    required String prompt,
  }) async {
    switch (provider) {
      case 'openai':
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.3,
            'max_tokens': 200,
          }),
        );
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['choices'] as List).first['message']['content'] as String;

      case 'anthropic':
        final response = await http.post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 200,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        );
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['content'] as List).first['text'] as String;

      default:
        throw Exception('Unsupported LLM provider: $provider');
    }
  }
}
