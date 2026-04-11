import 'package:flutter/material.dart';

class ConditionalCalculatorEditor extends StatelessWidget {
  final Map<String, dynamic> config;
  final ValueChanged<Map<String, dynamic>> onConfigChanged;
  final VoidCallback onRegenerate;

  const ConditionalCalculatorEditor({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.onRegenerate,
  });

  List<Map<String, dynamic>> get _steps => (config['steps'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  void _updateStep(int index, Map<String, dynamic> step) {
    final steps = _steps;
    steps[index] = step;
    onConfigChanged({...config, 'steps': steps});
  }

  void _deleteStep(int index) {
    final steps = _steps;
    steps.removeAt(index);
    onConfigChanged({...config, 'steps': steps});
  }

  void _addStep() {
    final steps = _steps;
    final id = 'step_${steps.length + 1}';
    steps.add({
      'id': id,
      'question': '',
      'type': 'choice',
      'options': [
        {'label': '', 'next': 'result', 'value': ''},
      ],
    });
    onConfigChanged({...config, 'steps': steps});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _steps;
    final resultTemplate = config['result_template'] as String? ?? '';
    final currency = config['currency'] as String? ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Edit Steps',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerate'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ...steps.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                final question = step['question'] as String? ?? '';
                final stepType = step['type'] as String? ?? 'choice';
                final options = (step['options'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();

                return Dismissible(
                  key: ValueKey(step['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: theme.colorScheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteStep(idx),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Step ${idx + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stepType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showStepEditor(
                                  context,
                                  idx,
                                  step,
                                  options,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            question.isNotEmpty ? question : '(empty question)',
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (options.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...options.map((opt) {
                              final label = opt['label'] as String? ?? '';
                              final next = opt['next'] as String? ?? '';
                              final price = opt['price'] as num?;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_right,
                                      size: 16,
                                      color: theme.colorScheme.outline,
                                    ),
                                    Expanded(
                                      child: Text(
                                        label.isNotEmpty ? label : '(option)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (price != null)
                                      Text(
                                        '+$price',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '→ $next',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Step'),
              ),
              const SizedBox(height: 16),
              Text('Result Template', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: resultTemplate),
                decoration: const InputDecoration(
                  hintText: 'Your {alteration_type} will cost {price}',
                ),
                onChanged: (v) =>
                    onConfigChanged({...config, 'result_template': v}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: currency),
                decoration: const InputDecoration(labelText: 'Currency symbol'),
                onChanged: (v) => onConfigChanged({...config, 'currency': v}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStepEditor(
    BuildContext context,
    int idx,
    Map<String, dynamic> step,
    List<Map<String, dynamic>> options,
  ) {
    final qCtrl = TextEditingController(
      text: step['question'] as String? ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: qCtrl,
                    decoration: const InputDecoration(labelText: 'Question'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Text('Options', style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...options.asMap().entries.map((e) {
                    final oIdx = e.key;
                    final opt = e.value;
                    final labelCtrl = TextEditingController(
                      text: opt['label'] as String? ?? '',
                    );
                    final nextCtrl = TextEditingController(
                      text: opt['next'] as String? ?? 'result',
                    );
                    final priceCtrl = TextEditingController(
                      text: (opt['price'] as num?)?.toString() ?? '',
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: labelCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Label ${oIdx + 1}',
                                    ),
                                    onChanged: (v) {
                                      options[oIdx] = {
                                        ...options[oIdx],
                                        'label': v,
                                      };
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () {
                                    setSheetState(() {
                                      options.removeAt(oIdx);
                                    });
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nextCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Next step ID',
                                    ),
                                    onChanged: (v) {
                                      options[oIdx] = {
                                        ...options[oIdx],
                                        'next': v,
                                      };
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: priceCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      options[oIdx] = {
                                        ...options[oIdx],
                                        'price': double.tryParse(v),
                                      };
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () {
                      setSheetState(() {
                        options.add({
                          'label': '',
                          'next': 'result',
                          'value': '',
                        });
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add option'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      _updateStep(idx, {
                        ...step,
                        'question': qCtrl.text,
                        'options': options,
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Step'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
