import 'sm_arabic_module.dart';
import 'sm_french_module.dart';
import 'sm_german_module.dart';
import 'sm_grammar_module.dart';
import 'sm_mandarin_module.dart';
import 'sm_russian_module.dart';

/// Registry mapping language codes to their grammar modules.
///
/// Usage:
/// ```dart
/// final module = SmLanguageRegistry.getModule('de');
/// final overlay = module?.tileOverlay(tileType: 'standard', grammarMetadata: {...});
/// ```
class SmLanguageRegistry {
  SmLanguageRegistry._();

  static final Map<String, SmGrammarModule> _modules = {
    'de': SmGermanModule(),
    'fr': SmFrenchModule(),
    'ru': SmRussianModule(),
    'ar': SmArabicModule(),
    'zh': SmMandarinModule(),
  };

  /// Get the grammar module for a language code. Returns null for unsupported languages.
  static SmGrammarModule? getModule(String languageCode) {
    return _modules[languageCode];
  }

  /// All supported language codes.
  static List<String> get supportedLanguages => _modules.keys.toList();

  /// All supported languages as display info.
  static List<SmLanguageInfo> get allLanguages => [
    const SmLanguageInfo(code: 'de', name: 'German', flag: '\u{1F1E9}\u{1F1EA}', nativeName: 'Deutsch'),
    const SmLanguageInfo(code: 'fr', name: 'French', flag: '\u{1F1EB}\u{1F1F7}', nativeName: 'Fran\u{00E7}ais'),
    const SmLanguageInfo(code: 'ru', name: 'Russian', flag: '\u{1F1F7}\u{1F1FA}', nativeName: '\u{0420}\u{0443}\u{0441}\u{0441}\u{043A}\u{0438}\u{0439}'),
    const SmLanguageInfo(code: 'ar', name: 'Arabic', flag: '\u{1F1F8}\u{1F1E6}', nativeName: '\u{0627}\u{0644}\u{0639}\u{0631}\u{0628}\u{064A}\u{0629}'),
    const SmLanguageInfo(code: 'zh', name: 'Mandarin', flag: '\u{1F1E8}\u{1F1F3}', nativeName: '\u{4E2D}\u{6587}'),
  ];

  /// Check if a language is supported.
  static bool isSupported(String languageCode) => _modules.containsKey(languageCode);
}

/// Display info for a supported language.
class SmLanguageInfo {
  final String code;
  final String name;
  final String flag;
  final String nativeName;

  const SmLanguageInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.nativeName,
  });
}
