import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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
          StudioTemplate.conditionalCalculator => ConditionalCalculatorPlay(
            module: module,
          ),
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
            Icon(Icons.psychology, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              module.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(body: _QuizPlay(module: module)),
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

  // Streak system (23.5.3)
  int _streak = 0;
  int _maxStreak = 0;
  bool _showStreakBanner = false;
  String _streakText = '';
  // Question transition key for entrance animation
  int _questionKey = 0;

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
    final limit = widget.module.config['time_limit_secs'] as int? ?? 0;
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

    final correctIdx = _questions[_currentIdx]['answer'] as int? ?? 0;
    final isCorrect = idx == correctIdx;

    // Haptic feedback
    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      if (isCorrect) {
        _correct++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;

        // Streak milestones
        if (_streak == 3) {
          _showStreakBanner = true;
          _streakText = 'ON FIRE';
        } else if (_streak == 5) {
          _showStreakBanner = true;
          _streakText = 'UNSTOPPABLE';
        } else {
          _showStreakBanner = false;
        }
      } else {
        _streak = 0;
        _showStreakBanner = false;
      }
    });

    // Auto-advance after 1.2s (longer if streak banner showing)
    final delay = _showStreakBanner ? 1800 : 1200;
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      if (_currentIdx < _questions.length - 1) {
        setState(() {
          _currentIdx++;
          _selectedAnswer = null;
          _answered = false;
          _showStreakBanner = false;
          _questionKey++;
        });
        _startTimer();
      } else {
        setState(() => _finished = true);
        final score = (_questions.isNotEmpty)
            ? ((_correct / _questions.length) * 100).round()
            : 0;
        recordPlay(moduleId: widget.module.id, score: score, completed: true);
      }
    });
  }

  String get _gradeBadge {
    final score = _questions.isNotEmpty
        ? ((_correct / _questions.length) * 100).round()
        : 0;
    if (score >= 95) return 'S';
    if (score >= 85) return 'A';
    if (score >= 70) return 'B';
    if (score >= 50) return 'C';
    return 'F';
  }

  Color _gradeColor(String grade) {
    return switch (grade) {
      'S' => const Color(0xFFFFD700),
      'A' => Colors.green,
      'B' => Colors.blue,
      'C' => Colors.orange,
      _ => Colors.red,
    };
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
    final limit = widget.module.config['time_limit_secs'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          // Streak indicator
          if (_streak >= 2)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _streak >= 5
                        ? const Color(0xFFFFD700)
                        : _streak >= 3
                        ? Colors.orange
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _streak >= 5 ? Icons.bolt : Icons.local_fire_department,
                        size: 16,
                        color: _streak >= 3
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$_streak',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: _streak >= 3
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      body: Stack(
        children: [
          Column(
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
                            )
                            .animate(target: _timeLeft <= 5 ? 1 : 0)
                            .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.2, 1.2),
                              duration: 500.ms,
                            ),
                      ],
                    ),
                  ),
                ),

              // Question with entrance animation
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child:
                    Text(
                          q['q'] as String? ?? '',
                          key: ValueKey('q_$_questionKey'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(key: ValueKey('qa_$_questionKey'))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.15, end: 0, curve: Curves.easeOut),
              ),

              // Options
              Expanded(
                child: ListView(
                  key: ValueKey('opts_$_questionKey'),
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
                            color:
                                bgColor ??
                                theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _answered
                                  ? null
                                  : () {
                                      HapticFeedback.lightImpact();
                                      _onAnswer(i);
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              fgColor ??
                                              theme.colorScheme.outline,
                                          width: _answered && i == correctIdx
                                              ? 2.5
                                              : 1,
                                        ),
                                        color: fgColor?.withValues(alpha: 0.2),
                                      ),
                                      child: Center(
                                        child: _answered && i == correctIdx
                                            ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: fgColor,
                                              )
                                            : _answered &&
                                                  i == _selectedAnswer &&
                                                  i != correctIdx
                                            ? Icon(
                                                Icons.close,
                                                size: 16,
                                                color: fgColor,
                                              )
                                            : Text(
                                                String.fromCharCode(65 + i),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      fgColor ??
                                                      theme
                                                          .colorScheme
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
                                    // Correct/wrong icon on answered
                                    if (_answered && i == correctIdx)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    if (_answered &&
                                        i == _selectedAnswer &&
                                        i != correctIdx)
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate(key: ValueKey('opt_${_questionKey}_$i'))
                        .fadeIn(delay: (i * 80).ms, duration: 200.ms)
                        .slideX(begin: 0.1, end: 0);
                  }),
                ),
              ),
            ],
          ),

          // Streak banner overlay
          if (_showStreakBanner)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child:
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _streak >= 5
                                    ? [
                                        const Color(0xFFFFD700),
                                        const Color(0xFFF59E0B),
                                      ]
                                    : [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (_streak >= 5
                                              ? const Color(0xFFFFD700)
                                              : Colors.orange)
                                          .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              _streakText,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.3, 0.3),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 200.ms)
                          .then(delay: 800.ms)
                          .fadeOut(duration: 300.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final score = _questions.isNotEmpty
        ? ((_correct / _questions.length) * 100).round()
        : 0;
    final passScore = widget.module.config['pass_score_pct'] as int? ?? 70;
    final passed = score >= passScore;
    final grade = _gradeBadge;
    final gradeCol = _gradeColor(grade);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grade badge slams down
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: gradeCol,
                        boxShadow: [
                          BoxShadow(
                            color: gradeCol.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        grade,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(3, 3),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 20),
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
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ).animate().fadeIn(delay: 600.ms),
                // Streak info
                if (_maxStreak >= 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Best streak: $_maxStreak',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 650.ms),
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
                      _streak = 0;
                      _maxStreak = 0;
                      _showStreakBanner = false;
                      _questionKey++;
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

  // Swipe state
  double _dragX = 0;
  double _dragRotation = 0;

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
    _flipAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipped) return;
    HapticFeedback.lightImpact();
    setState(() => _flipped = true);
    _flipCtrl.forward();
  }

  void _answer(bool knew) {
    if (knew) _known++;

    if (_currentIdx < _cards.length - 1) {
      setState(() {
        _currentIdx++;
        _flipped = false;
        _dragX = 0;
        _dragRotation = 0;
      });
      _flipCtrl.reset();
    } else {
      setState(() => _finished = true);
      final score = _cards.isNotEmpty
          ? ((_known / _cards.length) * 100).round()
          : 0;
      recordPlay(moduleId: widget.module.id, score: score, completed: true);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_flipped) return;
    setState(() {
      _dragX += details.delta.dx;
      _dragRotation = _dragX * 0.0003; // subtle rotation
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_flipped) return;
    if (_dragX > 80) {
      // Swiped right = know it
      HapticFeedback.lightImpact();
      _answer(true);
    } else if (_dragX < -80) {
      // Swiped left = don't know
      HapticFeedback.lightImpact();
      _answer(false);
    } else {
      // Spring back
      setState(() {
        _dragX = 0;
        _dragRotation = 0;
      });
    }
  }

  double get _masteryProgress => _cards.isEmpty ? 0 : _known / _cards.length;

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
    // Swipe indicator colors
    final swipeColor = _dragX > 30
        ? Colors.green.withValues(alpha: (_dragX / 150).clamp(0, 0.3))
        : _dragX < -30
        ? Colors.red.withValues(alpha: (-_dragX / 150).clamp(0, 0.3))
        : Colors.transparent;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          // Mastery ring
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _masteryProgress,
                    strokeWidth: 3,
                    color: _masteryProgress >= 1
                        ? Colors.amber
                        : theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  Text(
                    '${(_masteryProgress * 100).round()}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          LinearProgressIndicator(value: (_currentIdx + 1) / _cards.length),
          Expanded(
            child: GestureDetector(
              onTap: _flip,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Stack depth — cards behind
                  for (
                    var d = min(2, _cards.length - _currentIdx - 1);
                    d >= 1;
                    d--
                  )
                    Positioned(
                      top: 32.0 + d * 4,
                      left: 32,
                      right: 32,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        transform: Matrix4.identity()
                          // ignore: deprecated_member_use
                          ..scale(1.0 - d * 0.03),
                      ),
                    ),

                  // Swipe color overlay
                  if (swipeColor != Colors.transparent)
                    Positioned.fill(
                      child: IgnorePointer(child: Container(color: swipeColor)),
                    ),

                  // Main card
                  AnimatedBuilder(
                    animation: _flipAnim,
                    builder: (context, _) {
                      final angle = _flipAnim.value * pi;
                      final showBack = _flipAnim.value > 0.5;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          // ignore: deprecated_member_use
                          ..translate(_dragX)
                          ..rotateZ(_dragRotation)
                          ..rotateY(angle),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 250),
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
                                  color: theme.colorScheme.shadow.withValues(
                                    alpha: 0.1,
                                  ),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                                        color: theme
                                            .colorScheme
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
                                  if (_flipped) ...[
                                    const SizedBox(height: 24),
                                    Text(
                                      'Swipe right = know it  |  left = study',
                                      style: TextStyle(
                                        color: theme.colorScheme.outline,
                                        fontSize: 11,
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
                ],
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
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
                  color: pct >= 70 ? Colors.amber : theme.colorScheme.primary,
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
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
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

class _CalculatorPlayState extends State<_CalculatorPlay>
    with SingleTickerProviderStateMixin {
  final Map<String, double> _values = {};
  double? _result;
  bool _calculated = false;

  // Step-by-step mode (23.5.5)
  int _currentStep = 0;
  final Map<int, TextEditingController> _controllers = {};

  // Count-up animation
  late AnimationController _countUpCtrl;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _countUpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _countUpCtrl.addListener(() {
      if (_result != null) {
        setState(() {
          _displayValue =
              _result! * Curves.easeOut.transform(_countUpCtrl.value);
        });
      }
    });

    // Create controllers for each input
    final inputs = _inputs;
    for (var i = 0; i < inputs.length; i++) {
      _controllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _countUpCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get _inputs =>
      (widget.module.config['inputs'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  String get _formula => widget.module.config['formula'] as String? ?? '';

  String get _outputLabel =>
      widget.module.config['output_label'] as String? ?? 'Result';

  String get _outputUnit =>
      widget.module.config['output_unit'] as String? ?? '';

  bool get _isStepMode => _inputs.length > 1;

  void _nextStep() {
    final inputs = _inputs;
    final key = inputs[_currentStep]['key'] as String? ?? 'input_$_currentStep';
    _values[key] = double.tryParse(_controllers[_currentStep]?.text ?? '') ?? 0;

    if (_currentStep < inputs.length - 1) {
      setState(() => _currentStep++);
    } else {
      _calculate();
    }
  }

  void _calculate() {
    try {
      // Collect all values from controllers if not step mode
      if (!_isStepMode) {
        final inputs = _inputs;
        for (var i = 0; i < inputs.length; i++) {
          final key = inputs[i]['key'] as String? ?? 'input_$i';
          _values[key] = double.tryParse(_controllers[i]?.text ?? '') ?? 0;
        }
      }

      var expr = _formula;
      for (final entry in _values.entries) {
        expr = expr.replaceAll(entry.key, entry.value.toString());
      }
      final result = _evalSimple(expr);
      HapticFeedback.mediumImpact();
      setState(() {
        _result = result;
        _calculated = true;
        _displayValue = 0;
      });

      _countUpCtrl.forward(from: 0);

      recordPlay(moduleId: widget.module.id, completed: true);
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
        (s.codeUnitAt(j) >= 48 && s.codeUnitAt(j) <= 57 || s[j] == '.')) {
      j++;
    }
    return (double.parse(s.substring(i, j)), j);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputs = _inputs;

    // Step-by-step mode for multi-input calculators
    if (_isStepMode && !_calculated) {
      final inp = inputs[_currentStep];
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.title)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  inputs.length,
                  (i) => Container(
                    width: i == _currentStep ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i < _currentStep
                          ? theme.colorScheme.primary
                          : i == _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Input label
              Text(
                    inp['label'] as String? ?? 'Input',
                    key: ValueKey('step_$_currentStep'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate(key: ValueKey('stepa_$_currentStep'))
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.15, end: 0),
              const SizedBox(height: 24),
              TextField(
                key: ValueKey('input_$_currentStep'),
                controller: _controllers[_currentStep],
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  suffixText: inp['unit'] as String? ?? '',
                  border: const UnderlineInputBorder(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep < inputs.length - 1 ? 'Next' : 'Calculate',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    // All-at-once mode (single input) or results
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!_calculated)
            ...List.generate(inputs.length, (index) {
              final inp = inputs[index];

              return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        labelText: inp['label'] as String? ?? 'Input',
                        suffixText: inp['unit'] as String? ?? '',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (index * 100).ms)
                  .slideX(begin: 0.1, end: 0);
            }),
          if (!_calculated) ...[
            const SizedBox(height: 8),
            FilledButton(onPressed: _calculate, child: const Text('Calculate')),
          ],
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
                    // Count-up display
                    Text(
                      '$_outputUnit${_displayValue.toStringAsFixed(2)}',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
            ),
            // Input breakdown
            if (inputs.length > 1) ...[
              const SizedBox(height: 16),
              ...List.generate(inputs.length, (i) {
                final inp = inputs[i];
                final key = inp['key'] as String? ?? 'input_$i';
                final val = _values[key] ?? 0;
                final maxVal = _values.values.fold<double>(
                  1,
                  (a, b) => a > b ? a : b,
                );
                final fraction = maxVal > 0
                    ? (val / maxVal).clamp(0.0, 1.0)
                    : 0.0;

                return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                inp['label'] as String? ?? '',
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                '${val.toStringAsFixed(1)} ${inp['unit'] ?? ''}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 8,
                              color: theme.colorScheme.primary,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (300 + i * 100).ms)
                    .slideX(begin: -0.1, end: 0);
              }),
            ],
            const SizedBox(height: 16),
            Container(
              alignment: Alignment.center,
              child: Container(
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
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _calculated = false;
                  _result = null;
                  _currentStep = 0;
                  _values.clear();
                  _displayValue = 0;
                  for (final c in _controllers.values) {
                    c.clear();
                  }
                });
                _countUpCtrl.reset();
              },
              child: const Text('Calculate Again'),
            ),
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
