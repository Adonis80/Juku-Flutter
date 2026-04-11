import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/sm_competition.dart';
import '../services/sm_competition_service.dart';
import '../state/sm_competition_notifier.dart';

/// Line-by-line translation entry editor for a competition.
class SmCompetitionEntryScreen extends ConsumerStatefulWidget {
  final String competitionId;
  const SmCompetitionEntryScreen({super.key, required this.competitionId});

  @override
  ConsumerState<SmCompetitionEntryScreen> createState() =>
      _SmCompetitionEntryScreenState();
}

class _SmCompetitionEntryScreenState
    extends ConsumerState<SmCompetitionEntryScreen> {
  final _service = SmCompetitionService();
  final _styleController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  List<_LineEntry> _lines = [];
  SmCompetition? _competition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _styleController.dispose();
    for (final line in _lines) {
      line.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final detail = ref.read(
        smCompetitionDetailProvider(widget.competitionId),
      );
      final comp = detail.competition;
      if (comp == null) return;

      _competition = comp;

      // Fetch lyrics for the song.
      final lyrics = await _service.fetchSongLyrics(comp.songId);

      // Pre-populate from existing entry if editing.
      final myEntry = detail.myEntry;
      final existingMap = <int, SmEntryLine>{};
      if (myEntry != null) {
        for (final t in myEntry.translations) {
          existingMap[t.lineIndex] = t;
        }
        _styleController.text = myEntry.styleNote ?? '';
      }

      setState(() {
        _lines = lyrics.asMap().entries.map((e) {
          final idx = e.key;
          final lyric = e.value;
          final existing = existingMap[idx];
          return _LineEntry(
            lineIndex: idx,
            sourceText: lyric['text'] as String? ?? '',
            controller: TextEditingController(
              text: existing?.translatedText ?? '',
            ),
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    // Validate at least one line translated.
    final translated = _lines
        .where((l) => l.controller.text.trim().isNotEmpty)
        .toList();
    if (translated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translate at least one line')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final translations = translated
          .map(
            (l) => SmEntryLine(
              lineIndex: l.lineIndex,
              sourceText: l.sourceText,
              translatedText: l.controller.text.trim(),
            ),
          )
          .toList();

      final actions = SmCompetitionDetailActions(ref, widget.competitionId);
      await actions.submitEntry(
        translations: translations,
        styleNote: _styleController.text.trim().isNotEmpty
            ? _styleController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Entry submitted!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translatedCount = _lines
        .where((l) => l.controller.text.trim().isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Progress bar.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _lines.isEmpty
                              ? 0
                              : translatedCount / _lines.length,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$translatedCount/${_lines.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lines list.
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _lines.length + 1, // +1 for style note
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      if (i == _lines.length) {
                        // Style note at the end.
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 32),
                            Text(
                              'Style Note (optional)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _styleController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText:
                                    'Describe your translation approach...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        );
                      }

                      final line = _lines[i];
                      return _LineEditor(
                        lineIndex: line.lineIndex,
                        sourceText: line.sourceText,
                        controller: line.controller,
                        targetLanguage: _competition?.targetLanguage ?? 'en',
                        onChanged: () => setState(() {}),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _LineEntry {
  final int lineIndex;
  final String sourceText;
  final TextEditingController controller;

  _LineEntry({
    required this.lineIndex,
    required this.sourceText,
    required this.controller,
  });
}

class _LineEditor extends StatelessWidget {
  final int lineIndex;
  final String sourceText;
  final TextEditingController controller;
  final String targetLanguage;
  final VoidCallback onChanged;

  const _LineEditor({
    required this.lineIndex,
    required this.sourceText,
    required this.controller,
    required this.targetLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFilled = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isFilled
              ? theme.colorScheme.primary.withAlpha(80)
              : theme.colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isFilled
            ? theme.colorScheme.primaryContainer.withAlpha(20)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number + source text.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${lineIndex + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sourceText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Translation input.
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Your ${targetLanguage.toUpperCase()} translation...',
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(left: 32),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
