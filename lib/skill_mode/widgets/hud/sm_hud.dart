import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/sm_session_notifier.dart';

/// Persistent HUD overlay during sessions — XP bar, progress arc, combo.
/// Minimal working version for SM-1.6. Full juice in SM-3.1.
class SmHud extends ConsumerWidget {
  const SmHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(smSessionProvider);
    final theme = Theme.of(context);
    final progress = session.totalCards > 0
        ? session.cardsReviewed / session.totalCards
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Progress arc
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Card ${session.cardsReviewed + 1} of ${session.totalCards}',
            style: theme.textTheme.labelMedium,
          ),
          const Spacer(),
          // Combo
          if (session.combo > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${session.combo}x',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          const SizedBox(width: 8),
          // XP
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                '${session.currentXp}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
