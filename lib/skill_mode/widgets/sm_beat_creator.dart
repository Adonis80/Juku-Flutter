import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../services/sm_xp_engine.dart';

/// Beat the Creator result overlay (SM-3.5.1).
///
/// Shown after completing a deck with a creator_target_score set.
/// Beat: gold burst + "+30 bonus XP" + share card.
/// Didn't beat: "So close!" + retry button.
class SmBeatCreatorResult extends StatelessWidget {
  final String creatorName;
  final int targetScore;
  final int playerScore;
  final bool didBeat;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  const SmBeatCreatorResult({
    super.key,
    required this.creatorName,
    required this.targetScore,
    required this.playerScore,
    required this.didBeat,
    required this.onDismiss,
    this.onRetry,
  });

  /// Show as overlay.
  static void show(
    BuildContext context, {
    required String creatorName,
    required String deckTitle,
    required int targetScore,
    required int playerScore,
    required String userId,
    required VoidCallback onDismiss,
    VoidCallback? onRetry,
  }) {
    final didBeat = playerScore > targetScore;

    // Award bonus XP if beaten.
    if (didBeat) {
      SmXpEngine.instance.awardXp(
        userId: userId,
        baseAmount: 30,
        reason: 'beat_creator',
        currentCombo: 0,
      );
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SmBeatCreatorResult(
        creatorName: creatorName,
        targetScore: targetScore,
        playerScore: playerScore,
        didBeat: didBeat,
        onDismiss: () {
          entry.remove();
          onDismiss();
        },
        onRetry: onRetry != null
            ? () {
                entry.remove();
                onRetry();
              }
            : null,
      ),
    );
    overlay.insert(entry);
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'I beat $creatorName\'s score! $playerScore% vs $targetScore% on Juku Skill Mode',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (didBeat) ...[
                // Beat result.
                const Text(
                  '🎉',
                  style: TextStyle(fontSize: 64),
                ).animate().scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                ),
                const SizedBox(height: 12),
                Text(
                  'You beat $creatorName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF59E0B),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                const SizedBox(height: 8),
                Text(
                  '$playerScore% vs $targetScore%',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  '+30 bonus XP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF1E293B),
                  ),
                ),
              ] else ...[
                // Didn't beat.
                const Text('😤', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  'So close!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$creatorName scored $targetScore%\nYou scored $playerScore%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withAlpha(200),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (onRetry != null)
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.replay),
                    label: const Text('Try Again'),
                  ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDismiss,
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.white.withAlpha(150)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
