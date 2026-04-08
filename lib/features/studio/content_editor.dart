import 'package:flutter/material.dart';

import 'conditional_calculator_editor.dart';
import 'studio_state.dart';

class ContentEditor extends StatelessWidget {
  final StudioTemplate templateType;
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;
  final VoidCallback onRegenerate;

  const ContentEditor({
    super.key,
    required this.templateType,
    required this.config,
    required this.onConfigChanged,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('Review & Edit',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerate all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (templateType) {
            StudioTemplate.quiz => _QuizEditor(
                config: config, onConfigChanged: onConfigChanged),
            StudioTemplate.flashcard => _FlashcardEditor(
                config: config, onConfigChanged: onConfigChanged),
            StudioTemplate.calculator => _CalculatorEditor(
                config: config, onConfigChanged: onConfigChanged),
            StudioTemplate.conditionalCalculator =>
              ConditionalCalculatorEditor(
                config: config,
                onConfigChanged: onConfigChanged,
                onRegenerate: onRegenerate,
              ),
          },
        ),
      ],
    );
  }
}

// --- Quiz Editor ---

class _QuizEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;

  const _QuizEditor({required this.config, required this.onConfigChanged});

  List<Map<String, dynamic>> get _questions =>
      (config['questions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _updateQuestion(int index, Map<String, dynamic> question) {
    final qs = _questions;
    qs[index] = question;
    onConfigChanged({...config, 'questions': qs});
  }

  void _deleteQuestion(int index) {
    final qs = _questions;
    qs.removeAt(index);
    onConfigChanged({...config, 'questions': qs});
  }

  void _addQuestion() {
    final qs = _questions;
    qs.add({
      'q': '',
      'options': ['', '', '', ''],
      'answer': 0,
      'hint': '',
    });
    onConfigChanged({...config, 'questions': qs});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = _questions;

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            final options = List<String>.from(
                q['options'] as List? ?? ['', '', '', '']);
            final correctIdx = q['answer'] as int? ?? 0;

            return Dismissible(
              key: ValueKey('q_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: theme.colorScheme.error,
                child:
                    const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _deleteQuestion(index),
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Q${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              )),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditSheet(
                                context, index, q, options, correctIdx),
                          ),
                        ],
                      ),
                      Text(
                        (q['q'] as String?)?.isNotEmpty == true
                            ? q['q'] as String
                            : '(empty question)',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(options.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(
                                i == correctIdx
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 16,
                                color: i == correctIdx
                                    ? Colors.green
                                    : theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  options[i].isNotEmpty
                                      ? options[i]
                                      : '(option ${i + 1})',
                                  style: TextStyle(
                                    fontWeight: i == correctIdx
                                        ? FontWeight.w600
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _addQuestion,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context, int index,
      Map<String, dynamic> q, List<String> options, int correctIdx) {
    final qCtrl = TextEditingController(text: q['q'] as String? ?? '');
    final optCtrls =
        options.map((o) => TextEditingController(text: o)).toList();
    final hintCtrl =
        TextEditingController(text: q['hint'] as String? ?? '');
    int selectedAnswer = correctIdx;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Question'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                RadioGroup<int>(
                  groupValue: selectedAnswer,
                  onChanged: (v) => setSheetState(
                      () => selectedAnswer = v!),
                  child: Column(
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(value: i),
                            Expanded(
                              child: TextField(
                                controller: optCtrls[i],
                                decoration: InputDecoration(
                                    labelText: 'Option ${i + 1}'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                TextField(
                  controller: hintCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Hint (optional)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    _updateQuestion(index, {
                      'q': qCtrl.text,
                      'options':
                          optCtrls.map((c) => c.text).toList(),
                      'answer': selectedAnswer,
                      'hint': hintCtrl.text,
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Flashcard Editor ---

class _FlashcardEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;

  const _FlashcardEditor(
      {required this.config, required this.onConfigChanged});

  List<Map<String, dynamic>> get _cards =>
      (config['cards'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _updateCard(int index, Map<String, dynamic> card) {
    final cs = _cards;
    cs[index] = card;
    onConfigChanged({...config, 'cards': cs});
  }

  void _deleteCard(int index) {
    final cs = _cards;
    cs.removeAt(index);
    onConfigChanged({...config, 'cards': cs});
  }

  void _addCard() {
    final cs = _cards;
    cs.add({'front': '', 'back': '', 'example': ''});
    onConfigChanged({...config, 'cards': cs});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = _cards;

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final c = cards[index];

            return Dismissible(
              key: ValueKey('fc_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: theme.colorScheme.error,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _deleteCard(index),
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () =>
                      _showEditSheet(context, index, c),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                (c['front'] as String?)?.isNotEmpty ==
                                        true
                                    ? c['front'] as String
                                    : '(front)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (c['back'] as String?)?.isNotEmpty ==
                                        true
                                    ? c['back'] as String
                                    : '(back)',
                                style: TextStyle(
                                    color: theme
                                        .colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit,
                            size: 16,
                            color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _addCard,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showEditSheet(
      BuildContext context, int index, Map<String, dynamic> c) {
    final frontCtrl =
        TextEditingController(text: c['front'] as String? ?? '');
    final backCtrl =
        TextEditingController(text: c['back'] as String? ?? '');
    final exampleCtrl =
        TextEditingController(text: c['example'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontCtrl,
              decoration: const InputDecoration(labelText: 'Front'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: backCtrl,
              decoration: const InputDecoration(labelText: 'Back'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: exampleCtrl,
              decoration:
                  const InputDecoration(labelText: 'Example sentence'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                _updateCard(index, {
                  'front': frontCtrl.text,
                  'back': backCtrl.text,
                  'example': exampleCtrl.text,
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Calculator Editor ---

class _CalculatorEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;

  const _CalculatorEditor(
      {required this.config, required this.onConfigChanged});

  List<Map<String, dynamic>> get _inputs =>
      (config['inputs'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _updateInput(int index, Map<String, dynamic> input) {
    final ins = _inputs;
    ins[index] = input;
    onConfigChanged({...config, 'inputs': ins});
  }

  void _deleteInput(int index) {
    final ins = _inputs;
    ins.removeAt(index);
    onConfigChanged({...config, 'inputs': ins});
  }

  void _addInput() {
    final ins = _inputs;
    final key = 'input_${ins.length + 1}';
    ins.add({'label': '', 'key': key, 'unit': '', 'type': 'number'});
    onConfigChanged({...config, 'inputs': ins});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputs = _inputs;
    final formula = config['formula'] as String? ?? '';
    final outputLabel = config['output_label'] as String? ?? 'Result';
    final outputUnit = config['output_unit'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text('Inputs', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...List.generate(inputs.length, (index) {
          final inp = inputs[index];
          return Dismissible(
            key: ValueKey('inp_$index'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: theme.colorScheme.error,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _deleteInput(index),
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () =>
                    _showEditInputSheet(context, index, inp),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${inp['label']} (${inp['key']}) — ${inp['unit']}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(Icons.edit,
                          size: 16,
                          color: theme.colorScheme.outline),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: _addInput,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Input'),
        ),
        const SizedBox(height: 16),
        Text('Formula', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: formula),
          decoration: InputDecoration(
            hintText: 'e.g. hours * rate',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
          ),
          style: const TextStyle(fontFamily: 'monospace'),
          onChanged: (v) =>
              onConfigChanged({...config, 'formula': v}),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                    TextEditingController(text: outputLabel),
                decoration:
                    const InputDecoration(labelText: 'Output Label'),
                onChanged: (v) => onConfigChanged(
                    {...config, 'output_label': v}),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller:
                    TextEditingController(text: outputUnit),
                decoration:
                    const InputDecoration(labelText: 'Unit'),
                onChanged: (v) => onConfigChanged(
                    {...config, 'output_unit': v}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Live preview
        Text('Preview', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...inputs.map((inp) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: inp['label'] as String? ?? '',
                          suffixText: inp['unit'] as String? ?? '',
                        ),
                        keyboardType: TextInputType.number,
                        enabled: false,
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(outputLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    Text('0 $outputUnit',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditInputSheet(BuildContext context, int index,
      Map<String, dynamic> inp) {
    final labelCtrl =
        TextEditingController(text: inp['label'] as String? ?? '');
    final keyCtrl =
        TextEditingController(text: inp['key'] as String? ?? '');
    final unitCtrl =
        TextEditingController(text: inp['unit'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Label'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                  labelText: 'Key (used in formula)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitCtrl,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                _updateInput(index, {
                  'label': labelCtrl.text,
                  'key': keyCtrl.text,
                  'unit': unitCtrl.text,
                  'type': 'number',
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
