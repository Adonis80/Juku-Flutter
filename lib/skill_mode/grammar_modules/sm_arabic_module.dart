import 'package:flutter/material.dart';

import 'sm_grammar_module.dart';

/// Arabic grammar module — RTL text direction, root system tile overlay
/// (3-letter root highlight), verb forms (I–X), case endings (i'rab),
/// definite article (al-), sun/moon letter rules.
class SmArabicModule extends SmGrammarModule {
  @override
  String get languageCode => 'ar';

  @override
  String get languageName => 'Arabic';

  @override
  TextDirection get textDirection => TextDirection.rtl;

  @override
  List<String> get conjugationLabels => [
    '\u0623\u0646\u0627', // أنا (I)
    '\u0623\u0646\u062A/\u0623\u0646\u062A\u0650', // أنتَ/أنتِ (you m/f)
    '\u0647\u0648/\u0647\u064A', // هو/هي (he/she)
    '\u0646\u062D\u0646', // نحن (we)
    '\u0623\u0646\u062A\u0645', // أنتم (you pl)
    '\u0647\u0645', // هم (they)
  ];

  // --- Root system colours ---
  static const _rootColor = Color(0xFFF59E0B); // amber for root consonants
  static const _verbFormColor = Color(0xFF8B5CF6); // purple for verb form

  // --- Case ending colours (i'rab) ---
  static const _caseColors = <String, Color>{
    'nominative': Color(0xFF3B82F6), // marfu' (raf')
    'accusative': Color(0xFFF59E0B), // mansub (nasb)
    'genitive': Color(0xFFEF4444), // majrur (jarr)
    'jussive': Color(0xFF10B981), // majzum (jazm)
  };

  @override
  Color? tileBorderColor(Map<String, dynamic> grammarMetadata) {
    final verbForm = grammarMetadata['verb_form'] as String?;
    if (verbForm != null) return _verbFormColor;

    final root = grammarMetadata['root'] as String?;
    if (root != null) return _rootColor;

    return null;
  }

  @override
  Widget? tileOverlay({
    required String tileType,
    required Map<String, dynamic> grammarMetadata,
  }) {
    final root = grammarMetadata['root'] as String?;
    final verbForm = grammarMetadata['verb_form'] as String?;
    final grammaticalCase = grammarMetadata['case'] as String?;
    final isDefinite = grammarMetadata['is_definite'] as bool? ?? false;
    final isSunLetter = grammarMetadata['is_sun_letter'] as bool? ?? false;

    // Priority: root > verb form > case > article indicator
    if (root != null) {
      return _RootOverlay(root: root);
    }
    if (verbForm != null) {
      return _VerbFormChip(form: verbForm);
    }
    if (grammaticalCase != null) {
      return _ArabicCaseTile(grammaticalCase: grammaticalCase);
    }
    if (isDefinite) {
      return _ArticleIndicator(isSunLetter: isSunLetter);
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
      final root = cardGrammar['root'] as String?;
      final verbForm = cardGrammar['verb_form'] as String?;
      final grammaticalCase = cardGrammar['case'] as String?;

      String? rule;
      if (root != null) {
        rule =
            'Root: $root \u2014 three-letter root system (\u062C\u0630\u0631)';
      }
      if (verbForm != null) {
        rule = '${rule != null ? "$rule. " : ""}Verb Form $verbForm';
      }
      final isSunLetter = cardGrammar['is_sun_letter'] as bool? ?? false;
      if (isSunLetter) {
        rule =
            '${rule != null ? "$rule. " : ""}Sun letter \u2014 \u0627\u0644 assimilates';
      }

      return SmGrammarAnnotation(
        label: word,
        partOfSpeech: pos,
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
      'particle' || 'preposition' => const Color(0xFF6B7280),
      'pronoun' => const Color(0xFF06B6D4),
      _ => const Color(0xFF8B5CF6),
    };
  }
}

/// Root overlay — shows the 3-letter Arabic root above the tile.
class _RootOverlay extends StatelessWidget {
  final String root;

  const _RootOverlay({required this.root});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 4,
      bottom: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: SmArabicModule._rootColor.withAlpha(25),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: SmArabicModule._rootColor.withAlpha(80),
            width: 0.5,
          ),
        ),
        child: Text(
          root,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: SmArabicModule._rootColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

/// Verb form chip — shows form number (I–X) in Roman numerals.
class _VerbFormChip extends StatelessWidget {
  final String form;

  const _VerbFormChip({required this.form});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: SmArabicModule._verbFormColor.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          form,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: SmArabicModule._verbFormColor,
          ),
        ),
      ),
    );
  }
}

/// Arabic case ending chip (i'rab).
class _ArabicCaseTile extends StatelessWidget {
  final String grammaticalCase;

  const _ArabicCaseTile({required this.grammaticalCase});

  static const _labels = <String, String>{
    'nominative': '\u0631\u0641\u0639', // رفع
    'accusative': '\u0646\u0635\u0628', // نصب
    'genitive': '\u062C\u0631', // جر
    'jussive': '\u062C\u0632\u0645', // جزم
  };

  @override
  Widget build(BuildContext context) {
    final color =
        SmArabicModule._caseColors[grammaticalCase] ?? const Color(0xFF6B7280);
    final label = _labels[grammaticalCase] ?? grammaticalCase;

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
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

/// Definite article indicator — shows al- with sun/moon letter distinction.
class _ArticleIndicator extends StatelessWidget {
  final bool isSunLetter;

  const _ArticleIndicator({required this.isSunLetter});

  @override
  Widget build(BuildContext context) {
    final color = isSunLetter
        ? const Color(0xFFF59E0B) // amber for sun
        : const Color(0xFF94A3B8); // grey for moon

    return Positioned(
      right: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isSunLetter ? '\u2600' : '\u263D', // ☀ / ☽
          style: TextStyle(fontSize: 10, color: color),
        ),
      ),
    );
  }
}
