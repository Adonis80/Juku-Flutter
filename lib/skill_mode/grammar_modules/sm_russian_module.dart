import 'package:flutter/material.dart';

import 'sm_grammar_module.dart';

/// Russian grammar module — Cyrillic, 6-case system, 3 genders,
/// verb aspect (perfective/imperfective), stress marks, motion verbs.
class SmRussianModule extends SmGrammarModule {
  @override
  String get languageCode => 'ru';

  @override
  String get languageName => 'Russian';

  @override
  List<String> get conjugationLabels =>
      ['\u044F', '\u0442\u044B', '\u043E\u043D/\u043E\u043D\u0430/\u043E\u043D\u043E',
       '\u043C\u044B', '\u0432\u044B', '\u043E\u043D\u0438']; // я, ты, он/она/оно, мы, вы, они

  // --- Gender colours ---
  static const _masculineColor = Color(0xFF3B82F6);
  static const _feminineColor = Color(0xFFEC4899);
  static const _neuterColor = Color(0xFF22C55E);

  // --- Case colours ---
  static const _caseColors = <String, Color>{
    'nominative': Color(0xFF3B82F6),
    'genitive': Color(0xFFEF4444),
    'dative': Color(0xFF8B5CF6),
    'accusative': Color(0xFFF59E0B),
    'instrumental': Color(0xFF06B6D4),
    'prepositional': Color(0xFF10B981),
  };

  @override
  Color? tileBorderColor(Map<String, dynamic> grammarMetadata) {
    final gender = grammarMetadata['gender'] as String?;
    return switch (gender) {
      'masculine' => _masculineColor,
      'feminine' => _feminineColor,
      'neuter' => _neuterColor,
      _ => null,
    };
  }

  @override
  Widget? tileOverlay({
    required String tileType,
    required Map<String, dynamic> grammarMetadata,
  }) {
    final grammaticalCase = grammarMetadata['case'] as String?;
    final aspect = grammarMetadata['aspect'] as String?;
    final stress = grammarMetadata['stress_position'] as int?;

    if (grammaticalCase != null) {
      return _RussianCaseTile(grammaticalCase: grammaticalCase);
    }
    if (aspect != null) {
      return _AspectIndicator(aspect: aspect);
    }
    if (stress != null) {
      return _StressOverlay(stressPosition: stress);
    }
    return null;
  }

  @override
  List<SmGrammarAnnotation> buildAnnotations({
    required List<Map<String, dynamic>> tiles,
    required Map<String, dynamic> cardGrammar,
  }) {
    return tiles.map((tile) {
      final pos = tile['pos'] as String?;
      final word = tile['word'] as String? ?? '';
      final gender = cardGrammar['gender'] as String?;
      final grammaticalCase = cardGrammar['case'] as String?;
      final aspect = cardGrammar['aspect'] as String?;

      String? rule;
      if (aspect != null) {
        rule = aspect == 'perfective'
            ? 'Perfective — completed action'
            : 'Imperfective — ongoing/repeated action';
      }
      final isMotion = cardGrammar['is_motion_verb'] as bool? ?? false;
      if (isMotion) {
        rule = '${rule ?? ''} Motion verb — directional/non-directional pair.'.trim();
      }

      return SmGrammarAnnotation(
        label: word,
        partOfSpeech: pos,
        gender: gender,
        grammaticalCase: grammaticalCase,
        tense: cardGrammar['tense'] as String?,
        rule: rule ?? cardGrammar['note'] as String?,
        accentColor: _posColor(pos),
      );
    }).toList();
  }

  Color? _posColor(String? pos) {
    return switch (pos) {
      'noun' => const Color(0xFF3B82F6),
      'verb' => const Color(0xFF10B981),
      'adjective' => const Color(0xFFF59E0B),
      'preposition' || 'particle' => const Color(0xFF6B7280),
      'pronoun' => const Color(0xFF06B6D4),
      _ => const Color(0xFF8B5CF6),
    };
  }
}

/// Russian case chip — 6 cases with unique colours.
class _RussianCaseTile extends StatelessWidget {
  final String grammaticalCase;

  const _RussianCaseTile({required this.grammaticalCase});

  static const _abbreviations = <String, String>{
    'nominative': '\u0418\u043C', // Им (именительный)
    'genitive': '\u0420\u043E\u0434',   // Род (родительный)
    'dative': '\u0414\u0430\u0442',     // Дат (дательный)
    'accusative': '\u0412\u0438\u043D', // Вин (винительный)
    'instrumental': '\u0422\u0432',     // Тв (творительный)
    'prepositional': '\u041F\u0440',    // Пр (предложный)
  };

  @override
  Widget build(BuildContext context) {
    final color = SmRussianModule._caseColors[grammaticalCase] ??
        const Color(0xFF6B7280);
    final abbr = _abbreviations[grammaticalCase] ??
        grammaticalCase.substring(0, 3).toUpperCase();

    return Positioned(
      left: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withAlpha(100), width: 0.5),
        ),
        child: Text(
          abbr,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Aspect indicator — small SV/NSV badge (perfective/imperfective).
class _AspectIndicator extends StatelessWidget {
  final String aspect;

  const _AspectIndicator({required this.aspect});

  @override
  Widget build(BuildContext context) {
    final isPerfective = aspect == 'perfective';
    final color = isPerfective
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Positioned(
      right: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isPerfective ? 'CB' : 'HCB', // СВ / НСВ
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Stress mark overlay — highlights the stressed vowel in Russian words.
class _StressOverlay extends StatelessWidget {
  final int stressPosition;

  const _StressOverlay({required this.stressPosition});

  @override
  Widget build(BuildContext context) {
    // Shows a small accent mark indicator
    return Positioned(
      left: 12.0 + (stressPosition * 9.0),
      top: 0,
      child: const Text(
        '\u0301', // combining acute accent
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }
}
