import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.current,
    required this.best,
  });

  final int current;
  final int best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = current > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Fire icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.orange.withValues(alpha: 0.15)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_fire_department,
                color: isActive ? Colors.orange : theme.colorScheme.outline,
                size: 28,
              ),
            )
                .animate(
                  onPlay: (c) => isActive ? c.repeat(reverse: true) : null,
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 800.ms,
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$current day${current == 1 ? '' : 's'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isActive ? 'Current streak' : 'No active streak',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$best',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Best',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
