import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JukumonWidget extends StatelessWidget {
  const JukumonWidget({
    super.key,
    required this.level,
    required this.rank,
  });

  final int level;
  final String rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (level < 5) {
      return _buildEgg(theme);
    }

    return _buildCompanion(theme);
  }

  Widget _buildEgg(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms,
                ),
            const SizedBox(height: 12),
            Text(
              'Jukumon Egg',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Reach Level 5 to hatch!',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanion(ThemeData theme) {
    final config = _companionConfig(rank);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: config.colors,
                ),
                boxShadow: config.glow
                    ? [
                        BoxShadow(
                          color: config.colors.first.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  config.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -6,
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 12),
            Text(
              config.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Level $level companion',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CompanionConfig _companionConfig(String rank) {
    return switch (rank) {
      'silver' => _CompanionConfig(
          name: 'Silver Sprite',
          emoji: '\u{1F9CA}', // ice
          colors: [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)],
          glow: false,
        ),
      'gold' => _CompanionConfig(
          name: 'Golden Guardian',
          emoji: '\u{1F451}', // crown
          colors: [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
          glow: true,
        ),
      'diamond' => _CompanionConfig(
          name: 'Diamond Drake',
          emoji: '\u{1F48E}', // gem
          colors: [const Color(0xFF06B6D4), const Color(0xFF67E8F9)],
          glow: true,
        ),
      'mythic' => _CompanionConfig(
          name: 'Mythic Phoenix',
          emoji: '\u{1F525}', // fire
          colors: [const Color(0xFFA855F7), const Color(0xFFF472B6)],
          glow: true,
        ),
      _ => _CompanionConfig(
          name: 'Bronze Hatchling',
          emoji: '\u{1F423}', // hatching chick
          colors: [const Color(0xFFCD7F32), const Color(0xFFDEB887)],
          glow: false,
        ),
    };
  }
}

class _CompanionConfig {
  const _CompanionConfig({
    required this.name,
    required this.emoji,
    required this.colors,
    required this.glow,
  });

  final String name;
  final String emoji;
  final List<Color> colors;
  final bool glow;
}
