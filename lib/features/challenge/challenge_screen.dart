import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'challenge_service.dart';

/// Daily Challenge screen — play today's challenge card.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  DailyChallenge? _challenge;
  bool _loading = true;
  bool _alreadyAttempted = false;
  bool _answering = false;
  int _selectedOption = -1;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final challenge = await ChallengeService.instance.getTodayChallenge();
    if (challenge == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    final attempted =
        await ChallengeService.instance.hasAttemptedToday(challenge.id);

    if (mounted) {
      setState(() {
        _challenge = challenge;
        _alreadyAttempted = attempted;
        _loading = false;
      });
    }
  }

  void _startChallenge() {
    setState(() => _answering = true);
    _stopwatch
      ..reset()
      ..start();
  }

  Future<void> _submitAnswer() async {
    _stopwatch.stop();
    final challenge = _challenge;
    if (challenge == null) return;

    final cardData = challenge.cardData;
    final correctAnswer = cardData['answer'] as int? ?? 0;
    final isCorrect = _selectedOption == correctAnswer;
    final score =
        isCorrect ? _calculateScore(_stopwatch.elapsedMilliseconds) : 0;

    final result = await ChallengeService.instance.submitAttempt(
      challengeId: challenge.id,
      score: score,
      timeMs: _stopwatch.elapsedMilliseconds,
      correct: isCorrect,
      answers: [_selectedOption.toString()],
    );

    if (result != null && mounted) {
      GoRouter.of(context).push(
        '/challenge/result',
        extra: {
          'result': result,
          'correct': isCorrect,
          'score': score,
          'timeMs': _stopwatch.elapsedMilliseconds,
          'challengeId': challenge.id,
        },
      );
    }
  }

  int _calculateScore(int timeMs) {
    // Score = 100 - time penalty (lose 1 point per second, min 10)
    final timePenalty = (timeMs / 1000).round();
    return (100 - timePenalty).clamp(10, 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _challenge == null
              ? _buildNoChallenge(theme)
              : _alreadyAttempted
                  ? _buildAlreadyDone(theme)
                  : _answering
                      ? _buildQuestionView(theme)
                      : _buildRevealView(theme),
    );
  }

  Widget _buildNoChallenge(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'No challenge available today',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check back tomorrow!',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyDone(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{2705}', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          const Text(
            "You've already completed today's challenge!",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => GoRouter.of(context).push(
              '/challenge/result',
              extra: {'challengeId': _challenge!.id},
            ),
            icon: const Icon(Icons.leaderboard),
            label: const Text('View Leaderboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reveal animation
          Container(
            width: 200,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\u{1F4E8}',
                    style: const TextStyle(fontSize: 48),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    "Today's Challenge",
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _challenge!.language.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary
                          .withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startChallenge,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Challenge'),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            'One attempt only — no retries!',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(ThemeData theme) {
    final cardData = _challenge!.cardData;
    final question = cardData['q'] as String? ?? 'Challenge question';
    final options =
        (cardData['options'] as List?)?.cast<String>() ?? ['A', 'B', 'C', 'D'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Timer indicator
          LinearProgressIndicator(
            value: null, // Indeterminate while answering
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),

          // Question
          Text(
            question,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 32),

          // Options
          ...options.indexed.map((entry) {
            final (i, option) = entry;
            final isSelected = _selectedOption == i;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedOption = i),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer
                        : null,
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * i))
                  .slideX(begin: 0.1),
            );
          }),

          const Spacer(),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedOption >= 0 ? _submitAnswer : null,
              child: const Text('Submit Answer'),
            ),
          ),
        ],
      ),
    );
  }
}
