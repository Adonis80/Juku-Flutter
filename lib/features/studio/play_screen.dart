import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'conditional_calculator_play.dart';
import 'multiplayer_state.dart';
import 'studio_state.dart';

class PlayScreen extends ConsumerWidget {
  final String moduleId;

  const PlayScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moduleAsync = ref.watch(moduleByIdProvider(moduleId));

    return moduleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (module) {
        if (module == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Module not found')),
          );
        }

        return switch (module.templateType) {
          StudioTemplate.quiz => _PlayModeChooser(module: module),
          StudioTemplate.flashcard => _FlashcardPlay(module: module),
          StudioTemplate.calculator => _CalculatorPlay(module: module),
          StudioTemplate.conditionalCalculator =>
            ConditionalCalculatorPlay(module: module),
        };
      },
    );
  }
}

class _PlayModeChooser extends StatelessWidget {
  final StudioModule module;
  const _PlayModeChooser({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              module.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        body: _QuizPlay(module: module),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text('Play Solo'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final sessionId = await createGameSession(
                    moduleId: module.id,
                  );
                  if (context.mounted) {
                    context.go('/studio/lobby/$sessionId');
                  }
                },
                icon: const Icon(Icons.group),
                label: const Text('Play Multiplayer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// QUIZ PLAY
// ============================================================

class _QuizPlay extends StatefulWidget {
  final StudioModule module;
  const _QuizPlay({required this.module});

  @override
  State<_QuizPlay> createState() => _QuizPlayState();
}

class _QuizPlayState extends State<_QuizPlay> {
  late List<Map<String, dynamic>> _questions;
  int _currentIdx = 0;
  int _correct = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _finished = false;
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _questions = (widget.module.config['questions'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final limit =
        widget.module.config['time_limit_secs'] as int? ?? 0;
    if (limit <= 0) return;

    _timeLeft = limit;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _onAnswer(-1); // Time's up
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _onAnswer(int idx) {
    if (_answered) return;
    _timer?.cancel();

    final correctIdx =
        _questions[_currentIdx]['answer'] as int? ?? 0;
    final isCorrect = idx == correctIdx;

    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      if (isCorrect) _correct++;
    });

    // Auto-advance after 1.2s
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIdx < _questions.length - 1) {
        setState(() {
          _currentIdx++;
          _selectedAnswer = null;
          _answered = false;
        });
        _startTimer();
      } else {
        setState(() => _finished = true);
        // Record play
        final score = (_questions.isNotEmpty)
            ? ((_correct / _questions.length) * 100).round()
            : 0;
        recordPlay(
          moduleId: widget.module.id,
          score: score,
          completed: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_finished) {
      return _buildResults(theme);
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: const Center(child: Text('No questions in this quiz.')),
      );
    }

    final q = _questions[_currentIdx];
    final options = List<String>.from(q['options'] as List? ?? []);
    final correctIdx = q['answer'] as int? ?? 0;
    final limit =
        widget.module.config['time_limit_secs'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIdx + 1} / ${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIdx + 1) / _questions.length,
          ),

          // Timer
          if (limit > 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _timeLeft / limit,
                      strokeWidth: 4,
                      color: _timeLeft <= 5
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    Text(
                      '$_timeLeft',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 5
                            ? theme.colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Question
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Text(
              q['q'] as String? ?? '',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),

          // Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: List.generate(options.length, (i) {
                Color? bgColor;
                Color? fgColor;

                if (_answered) {
                  if (i == correctIdx) {
                    bgColor = Colors.green.withValues(alpha: 0.15);
                    fgColor = Colors.green;
                  } else if (i == _selectedAnswer) {
                    bgColor = Colors.red.withValues(alpha: 0.15);
                    fgColor = Colors.red;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: bgColor ??
                        theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _answered ? null : () => _onAnswer(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: fgColor ??
                                      theme.colorScheme.outline,
                                ),
                                color: fgColor?.withValues(alpha: 0.2),
                              ),
                              child: Center(
                                child: _answered && i == correctIdx
                                    ? Icon(Icons.check,
                                        size: 16,
                                        color: fgColor)
                                    : _answered &&
                                            i == _selectedAnswer &&
                                            i != correctIdx
                                        ? Icon(Icons.close,
                                            size: 16,
                                            color: fgColor)
                                        : Text(
                                            String.fromCharCode(
                                                65 + i),
                                            style: TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: fgColor ??
                                                  theme.colorScheme
                                                      .onSurface,
                                            ),
                                          ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[i],
                                style: TextStyle(
                                  color: fgColor,
                                  fontWeight: fgColor != null
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final score =
        _questions.isNotEmpty
            ? ((_correct / _questions.length) * 100).round()
            : 0;
    final passScore =
        widget.module.config['pass_score_pct'] as int? ?? 70;
    final passed = score >= passScore;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed
                      ? Icons.emoji_events
                      : Icons.sentiment_neutral,
                  size: 72,
                  color: passed ? Colors.amber : theme.colorScheme.outline,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 16),
                Text(
                  '$score%',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.green : theme.colorScheme.error,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  passed ? 'You passed!' : 'Nice try — play again?',
                  style: theme.textTheme.titleLarge,
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 4),
                Text(
                  '$_correct / ${_questions.length} correct',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+2 XP',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ).animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _currentIdx = 0;
                      _correct = 0;
                      _selectedAnswer = null;
                      _answered = false;
                      _finished = false;
                    });
                    _startTimer();
                  },
                  child: const Text('Play Again'),
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

// ============================================================
// FLASHCARD PLAY
// ============================================================

class _FlashcardPlay extends StatefulWidget {
  final StudioModule module;
  const _FlashcardPlay({required this.module});

  @override
  State<_FlashcardPlay> createState() => _FlashcardPlayState();
}

class _FlashcardPlayState extends State<_FlashcardPlay>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _cards;
  int _currentIdx = 0;
  bool _flipped = false;
  int _known = 0;
  bool _finished = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _cards = (widget.module.config['cards'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipped) return;
    setState(() => _flipped = true);
    _flipCtrl.forward();
  }

  void _answer(bool knew) {
    if (knew) _known++;

    if (_currentIdx < _cards.length - 1) {
      setState(() {
        _currentIdx++;
        _flipped = false;
      });
      _flipCtrl.reset();
    } else {
      setState(() => _finished = true);
      final score = _cards.isNotEmpty
          ? ((_known / _cards.length) * 100).round()
          : 0;
      recordPlay(
        moduleId: widget.module.id,
        score: score,
        completed: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_finished) return _buildResults(theme);

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: const Center(child: Text('No cards in this deck.')),
      );
    }

    final card = _cards[_currentIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIdx + 1} / ${_cards.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIdx + 1) / _cards.length,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (context, _) {
                  final angle = _flipAnim.value * pi;
                  final showBack = _flipAnim.value > 0.5;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        constraints:
                            const BoxConstraints(minHeight: 250),
                        decoration: BoxDecoration(
                          color: showBack
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow
                                  .withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Transform(
                          alignment: Alignment.center,
                          transform: showBack
                              ? (Matrix4.identity()..rotateY(pi))
                              : Matrix4.identity(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showBack
                                    ? card['back'] as String? ?? ''
                                    : card['front'] as String? ?? '',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (showBack &&
                                  (card['example'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                const SizedBox(height: 12),
                                Text(
                                  card['example'] as String,
                                  style: TextStyle(
                                    color: theme.colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (!_flipped) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Tap to flip',
                                  style: TextStyle(
                                    color: theme.colorScheme.outline,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_flipped)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _answer(false),
                      icon: const Icon(Icons.close),
                      label: const Text('Still learning'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _answer(true),
                      icon: const Icon(Icons.check),
                      label: const Text('I knew it'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final pct = _cards.isNotEmpty
        ? ((_known / _cards.length) * 100).round()
        : 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pct >= 70 ? Icons.star : Icons.sentiment_satisfied,
                  size: 72,
                  color: pct >= 70
                      ? Colors.amber
                      : theme.colorScheme.primary,
                ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 16),
                Text(
                  '$pct% known',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  '$_known / ${_cards.length} cards',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+2 XP',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _currentIdx = 0;
                      _known = 0;
                      _flipped = false;
                      _finished = false;
                    });
                    _flipCtrl.reset();
                  },
                  child: const Text('Play Again'),
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

// ============================================================
// CALCULATOR PLAY
// ============================================================

class _CalculatorPlay extends StatefulWidget {
  final StudioModule module;
  const _CalculatorPlay({required this.module});

  @override
  State<_CalculatorPlay> createState() => _CalculatorPlayState();
}

class _CalculatorPlayState extends State<_CalculatorPlay> {
  final Map<String, double> _values = {};
  double? _result;
  bool _calculated = false;

  List<Map<String, dynamic>> get _inputs =>
      (widget.module.config['inputs'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  String get _formula =>
      widget.module.config['formula'] as String? ?? '';

  String get _outputLabel =>
      widget.module.config['output_label'] as String? ?? 'Result';

  String get _outputUnit =>
      widget.module.config['output_unit'] as String? ?? '';

  void _calculate() {
    try {
      var expr = _formula;
      for (final entry in _values.entries) {
        expr = expr.replaceAll(entry.key, entry.value.toString());
      }
      final result = _evalSimple(expr);
      setState(() {
        _result = result;
        _calculated = true;
      });

      recordPlay(
        moduleId: widget.module.id,
        completed: true,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not calculate — check inputs')),
      );
    }
  }

  /// Simple expression evaluator for basic arithmetic
  double _evalSimple(String expr) {
    expr = expr.replaceAll(' ', '');
    return _parseExpr(expr, 0).$1;
  }

  (double, int) _parseExpr(String s, int i) {
    var (left, pos) = _parseTerm(s, i);
    while (pos < s.length && (s[pos] == '+' || s[pos] == '-')) {
      final op = s[pos];
      final (right, newPos) = _parseTerm(s, pos + 1);
      left = op == '+' ? left + right : left - right;
      pos = newPos;
    }
    return (left, pos);
  }

  (double, int) _parseTerm(String s, int i) {
    var (left, pos) = _parseFactor(s, i);
    while (pos < s.length && (s[pos] == '*' || s[pos] == '/')) {
      final op = s[pos];
      final (right, newPos) = _parseFactor(s, pos + 1);
      left = op == '*' ? left * right : left / right;
      pos = newPos;
    }
    return (left, pos);
  }

  (double, int) _parseFactor(String s, int i) {
    if (i < s.length && s[i] == '(') {
      final (val, pos) = _parseExpr(s, i + 1);
      return (val, pos + 1); // skip ')'
    }
    var j = i;
    if (j < s.length && s[j] == '-') j++;
    while (j < s.length &&
        (s.codeUnitAt(j) >= 48 && s.codeUnitAt(j) <= 57 ||
            s[j] == '.')) {
      j++;
    }
    return (double.parse(s.substring(i, j)), j);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputs = _inputs;

    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ...List.generate(inputs.length, (index) {
            final inp = inputs[index];
            final key = inp['key'] as String? ?? 'input_$index';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                decoration: InputDecoration(
                  labelText: inp['label'] as String? ?? 'Input',
                  suffixText: inp['unit'] as String? ?? '',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  _values[key] = double.tryParse(v) ?? 0;
                  if (_calculated) _calculate();
                },
              ),
            )
                .animate()
                .fadeIn(delay: (index * 100).ms)
                .slideX(begin: 0.1, end: 0);
          }),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _calculate,
            child: const Text('Calculate'),
          ),
          if (_calculated && _result != null) ...[
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      _outputLabel,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_outputUnit${_result!.toStringAsFixed(2)}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn()
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 16),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+2 XP',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/studio'),
            child: const Text('Back to Studio'),
          ),
        ],
      ),
    );
  }
}
