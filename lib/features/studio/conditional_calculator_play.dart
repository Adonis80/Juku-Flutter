import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'studio_state.dart';

class ConditionalCalculatorPlay extends StatefulWidget {
  final StudioModule module;

  const ConditionalCalculatorPlay({super.key, required this.module});

  @override
  State<ConditionalCalculatorPlay> createState() =>
      _ConditionalCalculatorPlayState();
}

class _ConditionalCalculatorPlayState extends State<ConditionalCalculatorPlay> {
  late List<Map<String, dynamic>> _steps;
  String _currentStepId = 'step_1';
  final Map<String, dynamic> _answers = {};
  bool _showResult = false;
  double _totalPrice = 0;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _steps = (widget.module.config['steps'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (_steps.isNotEmpty) {
      _currentStepId = _steps.first['id'] as String? ?? 'step_1';
    }
  }

  Map<String, dynamic>? get _currentStep {
    try {
      return _steps.firstWhere((s) => s['id'] == _currentStepId);
    } catch (_) {
      return null;
    }
  }

  void _selectOption(Map<String, dynamic> option) {
    final value =
        option['value'] as String? ?? option['label'] as String? ?? '';
    final price = (option['price'] as num?)?.toDouble() ?? 0;
    final next = option['next'] as String? ?? 'result';

    _answers[_currentStepId] = value;
    _totalPrice += price;

    if (next == 'result' || !_steps.any((s) => s['id'] == next)) {
      // Build result text
      final template = widget.module.config['result_template'] as String? ?? '';
      var result = template;
      for (final entry in _answers.entries) {
        result = result.replaceAll('{${entry.key}}', entry.value.toString());
      }
      result = result.replaceAll('{price}', _totalPrice.toStringAsFixed(2));

      setState(() {
        _showResult = true;
        _resultText = result;
      });

      recordPlay(moduleId: widget.module.id, completed: true);
    } else {
      setState(() => _currentStepId = next);
    }
  }

  void _onNumberSubmit(String key, double value) {
    _answers[key] = value;
    final step = _currentStep;
    final next = step?['next'] as String? ?? 'result';

    if (next == 'result' || !_steps.any((s) => s['id'] == next)) {
      _totalPrice += value * ((step?['multiplier'] as num?)?.toDouble() ?? 1);
      setState(() {
        _showResult = true;
        var template = widget.module.config['result_template'] as String? ?? '';
        for (final entry in _answers.entries) {
          template = template.replaceAll(
            '{${entry.key}}',
            entry.value.toString(),
          );
        }
        template = template.replaceAll(
          '{price}',
          _totalPrice.toStringAsFixed(2),
        );
        _resultText = template;
      });
      recordPlay(moduleId: widget.module.id, completed: true);
    } else {
      setState(() => _currentStepId = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = widget.module.config['currency'] as String? ?? '';

    if (_showResult) {
      return _buildResultScreen(theme, currency);
    }

    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: const Center(child: Text('No steps configured.')),
      );
    }

    final step = _currentStep;
    if (step == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: const Center(child: Text('Step not found.')),
      );
    }

    final stepType = step['type'] as String? ?? 'choice';
    final question = step['question'] as String? ?? '';
    final stepIdx = _steps.indexOf(step);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (stepIdx + 1) / (_steps.length + 1),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn().slideX(begin: 0.05, end: 0),
            const SizedBox(height: 24),
            if (stepType == 'choice')
              ..._buildChoiceOptions(theme, step)
            else if (stepType == 'number')
              _buildNumberInput(theme, step),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChoiceOptions(ThemeData theme, Map<String, dynamic> step) {
    final options = (step['options'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return options.asMap().entries.map((e) {
      final idx = e.key;
      final opt = e.value;
      final label = opt['label'] as String? ?? '';
      final price = opt['price'] as num?;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _selectOption(opt),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (price != null)
                      Text(
                        '+${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate().fadeIn(delay: (idx * 100).ms).slideX(begin: 0.1, end: 0);
    }).toList();
  }

  Widget _buildNumberInput(ThemeData theme, Map<String, dynamic> step) {
    final key = step['id'] as String? ?? '';
    final unit = step['unit'] as String? ?? '';
    final ctrl = TextEditingController();

    return Column(
      children: [
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            hintText: 'Enter a number',
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final val = double.tryParse(ctrl.text) ?? 0;
            _onNumberSubmit(key, val);
          },
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildResultScreen(ThemeData theme, String currency) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: theme.colorScheme.primary,
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_resultText.isNotEmpty) ...[
                          Text(
                            _resultText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          '$currency${_totalPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+2 XP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              'My quote from ${widget.module.title}: '
                              '$currency${_totalPrice.toStringAsFixed(2)} '
                              '— https://juku.pro/play/${widget.module.id}',
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share this quote'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _currentStepId =
                            _steps.first['id'] as String? ?? 'step_1';
                        _answers.clear();
                        _totalPrice = 0;
                        _resultText = '';
                        _showResult = false;
                      });
                    },
                    child: const Text('Start Over'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/studio'),
                  child: const Text('Back to Studio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
