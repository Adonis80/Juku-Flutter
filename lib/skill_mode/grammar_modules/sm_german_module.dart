import 'package:flutter/material.dart';

import 'sm_grammar_module.dart';

/// German grammar module — provides GenderTile, CaseTile, and
/// SeparableVerbTile overlays for the tile engine.
class SmGermanModule extends SmGrammarModule {
  @override
  String get languageCode => 'de';

  @override
  String get languageName => 'German';

  @override
  List<String> get conjugationLabels =>
      ['ich', 'du', 'er/sie/es', 'wir', 'ihr', 'sie/Sie'];

  @override
  bool get hasSeparableVerbs => true;

  // --- Gender colours ---
  static const _masculineColor = Color(0xFF3B82F6); // blue — der
  static const _feminineColor = Color(0xFFEF4444); // red — die
  static const _neuterColor = Color(0xFF22C55E); // green — das

  /// Border colour based on noun gender.
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

  /// Overlay widget for gender band or case chip.
  @override
  Widget? tileOverlay({
    required String tileType,
    required Map<String, dynamic> grammarMetadata,
  }) {
    final gender = grammarMetadata['gender'] as String?;
    final grammaticalCase = grammarMetadata['case'] as String?;

    if (gender != null) {
      return GenderTile(gender: gender);
    }
    if (grammaticalCase != null) {
      return CaseTile(grammaticalCase: grammaticalCase);
    }
    return null;
  }

  @override
  String? separablePrefix(Map<String, dynamic> grammarMetadata) {
    return grammarMetadata['separable_prefix'] as String?;
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

      return SmGrammarAnnotation(
        label: word,
        partOfSpeech: pos,
        gender: gender,
        grammaticalCase: grammaticalCase,
        rule: cardGrammar['note'] as String?,
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
      _ => const Color(0xFF8B5CF6),
    };
  }
}

/// Gender indicator — coloured left-border band on noun tiles.
/// Blue = der (masculine), Red = die (feminine), Green = das (neuter).
class GenderTile extends StatelessWidget {
  final String gender;

  const GenderTile({super.key, required this.gender});

  Color get _color => switch (gender) {
        'masculine' => SmGermanModule._masculineColor,
        'feminine' => SmGermanModule._feminineColor,
        'neuter' => SmGermanModule._neuterColor,
        _ => const Color(0xFF6B7280),
      };

  String get _label => switch (gender) {
        'masculine' => 'der',
        'feminine' => 'die',
        'neuter' => 'das',
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

/// Case chip — small label in the top-left of a tile showing NOM/ACC/DAT/GEN.
class CaseTile extends StatelessWidget {
  final String grammaticalCase;

  const CaseTile({super.key, required this.grammaticalCase});

  String get _abbreviation => switch (grammaticalCase) {
        'nominative' => 'NOM',
        'accusative' => 'ACC',
        'dative' => 'DAT',
        'genitive' => 'GEN',
        _ => grammaticalCase.substring(0, 3).toUpperCase(),
      };

  Color get _color => switch (grammaticalCase) {
        'nominative' => const Color(0xFF3B82F6),
        'accusative' => const Color(0xFFF59E0B),
        'dative' => const Color(0xFF8B5CF6),
        'genitive' => const Color(0xFFEF4444),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: _color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color.withAlpha(100), width: 0.5),
        ),
        child: Text(
          _abbreviation,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: _color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Separable verb tile — prefix detaches and flies to sentence end
/// during the Magnet Transform animation.
/// This widget renders the visual indicator; the animation logic
/// lives in SmMagnetTransform.
class SeparableVerbTile extends StatelessWidget {
  final String stem;
  final String prefix;
  final bool isSeparated;

  const SeparableVerbTile({
    super.key,
    required this.stem,
    required this.prefix,
    this.isSeparated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isSeparated) {
      // When separated, show only the stem with a dashed trailing edge
      return Container(
        constraints: const BoxConstraints(minWidth: 48),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Center(
          child: Text(
            stem,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ),
      );
    }

    // Joined state: prefix|stem shown together with a subtle divider
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prefix,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: theme.colorScheme.outline.withAlpha(80),
          ),
          Text(
            stem,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
