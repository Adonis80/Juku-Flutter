import 'package:flutter/material.dart';

import 'sm_grammar_module.dart';

/// Mandarin grammar module — tone colour overlay (4 tones + neutral),
/// pinyin layer below characters, character/pinyin toggle,
/// measure words (\u91CF\u8BCD), aspect particles (\u4E86/\u8FC7/\u7740).
class SmMandarinModule extends SmGrammarModule {
  @override
  String get languageCode => 'zh';

  @override
  String get languageName => 'Mandarin Chinese';

  // Mandarin has no conjugation — override with empty list
  @override
  List<String> get conjugationLabels => [];

  // --- Tone colours (standard Pinyin colour scheme) ---
  static const _toneColors = <int, Color>{
    1: Color(0xFFEF4444), // 1st tone (high level) — red
    2: Color(0xFFF59E0B), // 2nd tone (rising) — orange
    3: Color(0xFF22C55E), // 3rd tone (dipping) — green
    4: Color(0xFF3B82F6), // 4th tone (falling) — blue
    5: Color(0xFF6B7280), // neutral tone — grey
  };

  @override
  Color? tileBorderColor(Map<String, dynamic> grammarMetadata) {
    final tone = grammarMetadata['tone'] as int?;
    if (tone != null) return _toneColors[tone];
    return null;
  }

  @override
  Widget? tileOverlay({
    required String tileType,
    required Map<String, dynamic> grammarMetadata,
  }) {
    final tone = grammarMetadata['tone'] as int?;
    final pinyin = grammarMetadata['pinyin'] as String?;
    final measureWord = grammarMetadata['measure_word'] as String?;
    final aspectParticle = grammarMetadata['aspect_particle'] as String?;

    if (tone != null && pinyin != null) {
      return _TonePinyinOverlay(tone: tone, pinyin: pinyin);
    }
    if (measureWord != null) {
      return _MeasureWordChip(measureWord: measureWord);
    }
    if (aspectParticle != null) {
      return _AspectParticleChip(particle: aspectParticle);
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
      final pinyin = (tile['pinyin'] ?? cardGrammar['pinyin']) as String?;
      final tone = cardGrammar['tone'] as int?;
      final measureWord = cardGrammar['measure_word'] as String?;

      String? rule;
      if (tone != null) {
        rule = 'Tone $tone: ${_toneDescription(tone)}';
      }
      if (measureWord != null) {
        rule = '${rule != null ? "$rule. " : ""}Measure word: $measureWord';
      }
      if (pinyin != null) {
        rule = '${rule != null ? "$rule. " : ""}Pinyin: $pinyin';
      }

      return SmGrammarAnnotation(
        label: word,
        partOfSpeech: pos,
        tense: cardGrammar['tense'] as String?,
        rule: rule ?? cardGrammar['note'] as String?,
        accentColor: _posColor(pos),
      );
    }).toList();
  }

  static String _toneDescription(int tone) {
    return switch (tone) {
      1 => 'High level \u2014 \u0304',
      2 => 'Rising \u2014 \u0301',
      3 => 'Dipping \u2014 \u030C',
      4 => 'Falling \u2014 \u0300',
      _ => 'Neutral \u2014 light/short',
    };
  }

  Color? _posColor(String? pos) {
    return switch (pos) {
      'noun' => const Color(0xFF3B82F6),
      'verb' => const Color(0xFF10B981),
      'adjective' => const Color(0xFFF59E0B),
      'particle' => const Color(0xFF6B7280),
      'measure_word' => const Color(0xFFEC4899),
      _ => const Color(0xFF8B5CF6),
    };
  }
}

/// Tone + pinyin overlay — shows tone-coloured pinyin below the character tile.
class _TonePinyinOverlay extends StatelessWidget {
  final int tone;
  final String pinyin;

  const _TonePinyinOverlay({required this.tone, required this.pinyin});

  @override
  Widget build(BuildContext context) {
    final color = SmMandarinModule._toneColors[tone] ?? const Color(0xFF6B7280);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 2,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            pinyin,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Measure word chip — shows classifier (\u91CF\u8BCD) for nouns.
class _MeasureWordChip extends StatelessWidget {
  final String measureWord;

  const _MeasureWordChip({required this.measureWord});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFEC4899).withAlpha(25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          measureWord,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEC4899),
          ),
        ),
      ),
    );
  }
}

/// Aspect particle chip — \u4E86 (le), \u8FC7 (guo), \u7740 (zhe).
class _AspectParticleChip extends StatelessWidget {
  final String particle;

  const _AspectParticleChip({required this.particle});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      top: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFF06B6D4).withAlpha(25),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          particle,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF06B6D4),
          ),
        ),
      ),
    );
  }
}
