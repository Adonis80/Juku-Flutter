import 'package:flutter/material.dart';

import 'sm_grammar_module.dart';

/// French grammar module — gender (le/la/les), elision, accent marks,
/// verb groups (1st/2nd/3rd conjugation).
class SmFrenchModule extends SmGrammarModule {
  @override
  String get languageCode => 'fr';

  @override
  String get languageName => 'French';

  @override
  List<String> get conjugationLabels => [
    'je',
    'tu',
    'il/elle/on',
    'nous',
    'vous',
    'ils/elles',
  ];

  // --- Gender colours ---
  static const _masculineColor = Color(0xFF3B82F6); // blue — le
  static const _feminineColor = Color(0xFFEC4899); // pink — la

  @override
  Color? tileBorderColor(Map<String, dynamic> grammarMetadata) {
    final gender = grammarMetadata['gender'] as String?;
    return switch (gender) {
      'masculine' => _masculineColor,
      'feminine' => _feminineColor,
      _ => null,
    };
  }

  @override
  Widget? tileOverlay({
    required String tileType,
    required Map<String, dynamic> grammarMetadata,
  }) {
    final gender = grammarMetadata['gender'] as String?;
    final elision = grammarMetadata['elision'] as bool? ?? false;

    if (elision) {
      return const _ElisionIndicator();
    }
    if (gender != null) {
      return _FrenchGenderTile(gender: gender);
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
      final verbGroup = cardGrammar['verb_group'] as String?;

      String? rule;
      if (verbGroup != null) {
        rule = 'Verb group: $verbGroup conjugation (-er/-ir/-re)';
      }

      return SmGrammarAnnotation(
        label: word,
        partOfSpeech: pos,
        gender: gender,
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
      'article' || 'particle' => const Color(0xFF6B7280),
      'pronoun' => const Color(0xFF06B6D4),
      _ => const Color(0xFF8B5CF6),
    };
  }
}

/// Gender indicator for French nouns — le (masculine) / la (feminine).
class _FrenchGenderTile extends StatelessWidget {
  final String gender;

  const _FrenchGenderTile({required this.gender});

  Color get _color => switch (gender) {
    'masculine' => SmFrenchModule._masculineColor,
    'feminine' => SmFrenchModule._feminineColor,
    _ => const Color(0xFF6B7280),
  };

  String get _label => switch (gender) {
    'masculine' => 'le',
    'feminine' => 'la',
    _ => '?',
  };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 4,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Tooltip(
          message: '$_label ($gender)',
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Elision indicator — shows apostrophe connection (l', d', qu', etc.).
class _ElisionIndicator extends StatelessWidget {
  const _ElisionIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: -4,
      top: 16,
      child: Container(
        width: 8,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withAlpha(40),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            "'",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
      ),
    );
  }
}
