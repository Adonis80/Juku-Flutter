import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants.dart';

class LevelBar extends StatelessWidget {
  const LevelBar({
    super.key,
    required this.xp,
    required this.level,
    required this.rank,
  });

  final int xp;
  final int level;
  final String rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xpPerLevel = xpForLevel(level);

    // Calculate XP within current level
    int xpAccumulated = 0;
    for (int l = 1; l < level; l++) {
      xpAccumulated += xpForLevel(l);
    }
    final xpInLevel = xp - xpAccumulated;
    final progress = (xpInLevel / xpPerLevel).clamp(0.0, 1.0);

    final rankColor = _rankColor(rank);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _rankIcon(rank),
                    color: rankColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${rankLabels[rank] ?? 'Bronze'} · Level $level',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$xpInLevel / $xpPerLevel XP to next level',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total XP
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$xp',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Total XP',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(rankColor),
              ),
            ).animate().scaleX(
                  begin: 0,
                  end: 1,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                  alignment: Alignment.centerLeft,
                ),
          ],
        ),
      ),
    );
  }

  Color _rankColor(String rank) {
    return switch (rank) {
      'silver' => const Color(0xFF94A3B8),
      'gold' => const Color(0xFFF59E0B),
      'diamond' => const Color(0xFF06B6D4),
      'mythic' => const Color(0xFFA855F7),
      _ => const Color(0xFFCD7F32), // bronze
    };
  }

  IconData _rankIcon(String rank) {
    return switch (rank) {
      'silver' => Icons.shield_outlined,
      'gold' => Icons.military_tech,
      'diamond' => Icons.diamond_outlined,
      'mythic' => Icons.auto_awesome,
      _ => Icons.shield_outlined,
    };
  }
}
