import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/supabase_config.dart';
import 'studio_state.dart';

class AiGenerator {
  /// Generates content for a studio module using the user's LLM key.
  /// Returns the generated config map ready to merge into module config.
  static Future<Map<String, dynamic>> generate({
    required StudioTemplate templateType,
    required String topic,
    required String level,
    required int itemCount,
    String? calculatorDescription,
    int? timeLimitSecs,
    int? passScorePct,
    String? languagePair,
  }) async {
    // Load user profile to get LLM settings
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final profile = await supabase
        .from('profiles')
        .select('llm_provider, llm_api_key_encrypted')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) throw Exception('Profile not found');

    final provider = profile['llm_provider'] as String?;
    final encryptedKey = profile['llm_api_key_encrypted'] as String?;

    if (provider == null || encryptedKey == null || encryptedKey.isEmpty) {
      throw Exception('No AI key configured. Add your key in Settings.');
    }

    // Decode key (base64 obfuscation — not true encryption)
    final apiKey = utf8.decode(base64Decode(encryptedKey));

    final prompt = _buildPrompt(
      templateType: templateType,
      topic: topic,
      level: level,
      itemCount: itemCount,
      calculatorDescription: calculatorDescription,
    );

    final responseText = await _callLlm(
      provider: provider,
      apiKey: apiKey,
      prompt: prompt,
    );

    // Parse JSON from response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
    if (jsonMatch == null) {
      throw Exception('AI returned invalid format. Please try again.');
    }

    final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

    // Merge template-specific settings
    switch (templateType) {
      case StudioTemplate.quiz:
        if (timeLimitSecs != null) parsed['time_limit_secs'] = timeLimitSecs;
        if (passScorePct != null) parsed['pass_score_pct'] = passScorePct;
      case StudioTemplate.flashcard:
        if (languagePair != null) parsed['language_pair'] = languagePair;
      case StudioTemplate.calculator:
        break;
      case StudioTemplate.conditionalCalculator:
        break;
    }

    return parsed;
  }

  static String _buildPrompt({
    required StudioTemplate templateType,
    required String topic,
    required String level,
    required int itemCount,
    String? calculatorDescription,
  }) {
    switch (templateType) {
      case StudioTemplate.quiz:
        return 'Generate $itemCount multiple choice questions about "$topic" '
            'for $level learners. Each question has 4 options, one correct '
            'answer (0-indexed), and an optional hint. Return valid JSON only, '
            'no explanation: {"questions": [{"q": "...", "options": ["A","B","C","D"], '
            '"answer": 0, "hint": "..."}]}';
      case StudioTemplate.flashcard:
        return 'Generate $itemCount flashcards for "$topic" for $level learners. '
            'Return valid JSON only, no explanation: '
            '{"cards": [{"front": "word/phrase", "back": "translation/meaning", '
            '"example": "example sentence"}]}';
      case StudioTemplate.calculator:
        final desc = calculatorDescription ?? topic;
        return 'The user described their pricing/calculation system as: "$desc". '
            'Convert this into a simple calculator with named inputs and a '
            'formula using those input keys. Return valid JSON only, no explanation: '
            '{"inputs": [{"label": "...", "key": "snake_case_key", "unit": "...", '
            '"type": "number"}], "formula": "key1 * key2", '
            '"output_label": "Total", "output_unit": "\$"}';
      case StudioTemplate.conditionalCalculator:
        final desc = calculatorDescription ?? topic;
        return 'The user described their pricing/service system as: "$desc". '
            'Convert this into a step-by-step decision tree calculator. Each step '
            'asks a question and offers choices that lead to the next step or a result. '
            'Choices can have prices attached. Return valid JSON only, no explanation: '
            '{"steps": [{"id": "step_1", "question": "What type?", "type": "choice", '
            '"options": [{"label": "Option A", "next": "step_2", "value": "opt_a"}, '
            '{"label": "Option B", "next": "result", "value": "opt_b", "price": 25}]}], '
            '"result_template": "Your {step_1} will cost {price}", "currency": "GBP"}';
    }
  }

  static Future<String> _callLlm({
    required String provider,
    required String apiKey,
    required String prompt,
  }) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        return _callOpenAi(apiKey, prompt);
      case 'anthropic':
        return _callAnthropic(apiKey, prompt);
      case 'google':
        return _callGoogle(apiKey, prompt);
      default:
        return _callOpenAi(apiKey, prompt);
    }
  }

  static Future<String> _callOpenAi(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful content generator. Return only valid JSON.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI error: ${response.statusCode} — ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List;
    return (choices[0]['message']['content'] as String).trim();
  }

  static Future<String> _callAnthropic(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-haiku-4-5-20251001',
        'max_tokens': 2048,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Anthropic error: ${response.statusCode} — ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List;
    return (content[0]['text'] as String).trim();
  }

  static Future<String> _callGoogle(String apiKey, String prompt) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Google AI error: ${response.statusCode} — ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List;
    final parts = candidates[0]['content']['parts'] as List;
    return (parts[0]['text'] as String).trim();
  }
}
