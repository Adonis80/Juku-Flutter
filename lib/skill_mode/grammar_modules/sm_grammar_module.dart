import 'package:flutter/material.dart';

/// Abstract base class that all language-specific grammar modules implement.
///
/// Each language ships as a self-contained module that plugs into the
/// language-agnostic tile engine. Modules provide custom tile overlays,
/// colour coding, annotation builders, and dial configurations.
abstract class SmGrammarModule {
  /// ISO 639-1 language code this module handles (e.g. 'de', 'ru', 'ar').
  String get languageCode;

  /// Human-readable language name.
  String get languageName;

  /// Text direction for this language.
  TextDirection get textDirection => TextDirection.ltr;

  /// Return a border colour for the given tile based on grammar metadata.
  /// Returns null to use the default POS-based colour.
  Color? tileBorderColor(Map<String, dynamic> grammarMetadata);

  /// Return an optional overlay widget to render on top of a tile
  /// (e.g. gender colour band, case chip, tone mark).
  Widget? tileOverlay({
    required String tileType,
    required Map<String, dynamic> grammarMetadata,
  });

  /// Build annotation widgets for the grammar panel (Press 3).
  /// Returns a list of annotation entries for each tile in the sentence.
  List<SmGrammarAnnotation> buildAnnotations({
    required List<Map<String, dynamic>> tiles,
    required Map<String, dynamic> cardGrammar,
  });

  /// Return custom conjugation dial labels for this language.
  /// Default: generic person labels. Override for language-specific forms.
  List<String> get conjugationLabels;

  /// Whether this module supports separable verb animations.
  bool get hasSeparableVerbs => false;

  /// Identify a separable prefix from grammar metadata.
  /// Returns null if the verb is not separable.
  String? separablePrefix(Map<String, dynamic> grammarMetadata) => null;
}

/// A single grammar annotation entry shown in the grammar panel.
class SmGrammarAnnotation {
  final String label;
  final String? partOfSpeech;
  final String? gender;
  final String? grammaticalCase;
  final String? tense;
  final String? rule;
  final Color? accentColor;

  const SmGrammarAnnotation({
    required this.label,
    this.partOfSpeech,
    this.gender,
    this.grammaticalCase,
    this.tense,
    this.rule,
    this.accentColor,
  });
}
