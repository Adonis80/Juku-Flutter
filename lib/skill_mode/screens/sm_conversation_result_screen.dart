import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/sm_conversation_state.dart';

/// Session result screen for AI Conversation (GL-3).
///
/// Shows fluency/vocabulary/grammar scores, XP earned, and overall grade.
class SmConversationResultScreen extends ConsumerWidget {
  const SmConversationResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final convState = ref.watch(conversationProvider);
    final conversation = convState.conversation;

    final fluency = conversation?.fluencyScore ?? convState.avgFluency;
    final vocabulary = conversation?.vocabularyScore ?? convState.avgVocabulary;
    final grammar = conversation?.grammarScore ?? convState.avgGrammar;
    final overall = conversation?.overallScore ?? convState.avgOverall;
    final xp = conversation?.xpAwarded ?? 0;
    final turns = conversation?.turnCount ?? convState.messages.length ~/ 2;
    final duration = conversation?.durationSeconds ?? 0;

    final grade = _gradeFor(overall);
    final gradeColor = _colorFor(grade);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Overall score.
            Text(
                  '$overall%',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: gradeColor,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                )
                .fadeIn(),

            Text(
              grade,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: gradeColor,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

            const SizedBox(height: 8),
            Text(
              '$turns turns · ${_formatDuration(duration)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // Score breakdown.
            _ScoreRow(
              label: 'Fluency',
              score: fluency,
              color: const Color(0xFF6366F1),
              icon: Icons.water_drop,
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
            const SizedBox(height: 12),
            _ScoreRow(
              label: 'Vocabulary',
              score: vocabulary,
              color: const Color(0xFFF59E0B),
              icon: Icons.menu_book,
            ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
            const SizedBox(height: 12),
            _ScoreRow(
              label: 'Grammar',
              score: grammar,
              color: const Color(0xFF10B981),
              icon: Icons.rule,
            ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

            const SizedBox(height: 32),

            // XP earned.
            if (xp > 0)
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Text(
                          '+$xp XP',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                  ),

            const SizedBox(height: 32),

            // Scenario info.
            if (conversation?.scenario != null)
              Text(
                conversation!.scenario!.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

            const SizedBox(height: 32),

            // Actions.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/skill/conversation'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('New Scenario'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    // Retry same scenario.
                    final scenario = conversation?.scenario;
                    if (scenario != null) {
                      ref
                          .read(conversationProvider.notifier)
                          .startConversation(
                            scenarioId: scenario.id,
                            language: conversation!.language,
                          );
                      context.pushReplacement('/skill/conversation/live');
                    } else {
                      context.go('/skill/conversation');
                    }
                  },
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _gradeFor(int score) {
    if (score >= 90) return 'Outstanding!';
    if (score >= 75) return 'Great job!';
    if (score >= 60) return 'Good effort';
    if (score >= 40) return 'Keep practising';
    return 'Getting started';
  }

  Color _colorFor(String grade) {
    return switch (grade) {
      'Outstanding!' => const Color(0xFFF59E0B),
      'Great job!' => const Color(0xFF10B981),
      'Good effort' => const Color(0xFF6366F1),
      'Keep practising' => const Color(0xFFF97316),
      _ => const Color(0xFFEF4444),
    };
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final IconData icon;

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              color: color,
              backgroundColor: color.withAlpha(30),
            ),
          ),
        ),
      ],
    );
  }
}
