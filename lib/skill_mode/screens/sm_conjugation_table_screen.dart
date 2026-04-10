import 'package:flutter/material.dart';

import '../grammar_modules/sm_language_registry.dart';

/// Conjugation table — reference card showing all verb forms at once (SM-10).
///
/// Language-aware: adapts person labels, tenses, and layout per language.
class SmConjugationTableScreen extends StatelessWidget {
  final String verb;
  final String language;
  final Map<String, dynamic> conjugations;

  const SmConjugationTableScreen({
    super.key,
    required this.verb,
    required this.language,
    required this.conjugations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final module = SmLanguageRegistry.getModule(language);
    final persons = module?.conjugationLabels ?? _defaultPersons;

    // Group conjugations by tense
    final tenses = _extractTenses();

    return Scaffold(
      appBar: AppBar(
        title: Text(verb),
        actions: [
          if (module != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(module.languageName),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: tenses.isEmpty
          ? Center(
              child: Text(
                'No conjugation data available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Verb header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primaryContainer,
                        cs.primaryContainer.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        verb,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      if (conjugations['meaning'] != null)
                        Text(
                          conjugations['meaning'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                        ),
                      if (conjugations['verb_group'] != null) ...[
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            conjugations['verb_group'] as String,
                            style: theme.textTheme.labelSmall,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tense tables
                for (final tense in tenses.entries)
                  _buildTenseTable(tense.key, tense.value, persons, theme, cs),
              ],
            ),
    );
  }

  static const _defaultPersons = [
    'I',
    'you (sg)',
    'he/she/it',
    'we',
    'you (pl)',
    'they',
  ];

  Map<String, List<String>> _extractTenses() {
    final tenses = <String, List<String>>{};
    final forms = conjugations['forms'] as Map<String, dynamic>?;
    if (forms == null) return tenses;

    for (final entry in forms.entries) {
      final tense = entry.key;
      final formList = entry.value;
      if (formList is List) {
        tenses[tense] = formList.map((e) => e.toString()).toList();
      }
    }
    return tenses;
  }

  Widget _buildTenseTable(
    String tense,
    List<String> forms,
    List<String> persons,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final tenseLabel = _formatTense(tense);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tense header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: cs.surfaceContainerHighest,
              child: Text(
                tenseLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            // Conjugation rows
            for (var i = 0; i < forms.length && i < persons.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i < forms.length - 1
                        ? BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))
                        : BorderSide.none,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          persons[i],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          forms[i],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTense(String tense) {
    return tense
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }
}
