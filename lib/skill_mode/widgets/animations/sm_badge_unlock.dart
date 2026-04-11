import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/sm_badge_service.dart';

/// Badge unlock animation overlay (SM-3.4).
///
/// Shimmer reveal + sound. Rare badges get holographic shimmer.
class SmBadgeUnlock extends StatefulWidget {
  final SmBadge badge;
  final VoidCallback? onDismiss;

  const SmBadgeUnlock({super.key, required this.badge, this.onDismiss});

  /// Show as overlay.
  static void show(BuildContext context, SmBadge badge) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          SmBadgeUnlock(badge: badge, onDismiss: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  State<SmBadgeUnlock> createState() => _SmBadgeUnlockState();
}

class _SmBadgeUnlockState extends State<SmBadgeUnlock>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    if (widget.badge.rarity == SmBadgeRarity.legendary) {
      _shimmerController.repeat();
    } else {
      _shimmerController.forward();
    }

    // Auto-dismiss.
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge icon with shimmer.
              _buildBadgeIcon(),
              const SizedBox(height: 16),
              Text(
                'Badge Unlocked!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(180),
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 500)),
              const SizedBox(height: 8),
              Text(
                    widget.badge.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600))
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    delay: const Duration(milliseconds: 600),
                  ),
              const SizedBox(height: 4),
              Text(
                widget.badge.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(150),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    Widget icon =
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _rarityColor.withAlpha(30),
                border: Border.all(color: _rarityColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _rarityColor.withAlpha(80),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.badge.icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            )
            .animate()
            .scale(
              begin: const Offset(0.0, 0.0),
              end: const Offset(1.0, 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: const Duration(milliseconds: 200));

    // Legendary: holographic shimmer.
    if (widget.badge.rarity == SmBadgeRarity.legendary) {
      icon = AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Colors.white,
                  Color(0xFF7DF9FF),
                  Color(0xFFFFD700),
                  Color(0xFF8B5CF6),
                  Colors.white,
                ],
                stops: [
                  0.0,
                  _shimmerController.value * 0.5,
                  _shimmerController.value,
                  _shimmerController.value * 1.5,
                  1.0,
                ].map((s) => s.clamp(0.0, 1.0)).toList(),
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: child,
          );
        },
        child: icon,
      );
    }

    return icon;
  }

  Color get _rarityColor => switch (widget.badge.rarity) {
    SmBadgeRarity.common => const Color(0xFF10B981),
    SmBadgeRarity.rare => const Color(0xFF3B82F6),
    SmBadgeRarity.legendary => const Color(0xFFFFD700),
  };
}

/// Badge card for the gallery in SmVaultScreen.
class SmBadgeCard extends StatelessWidget {
  final SmBadge badge;
  final bool unlocked;

  const SmBadgeCard({super.key, required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: unlocked
              ? Border.all(color: _rarityBorderColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              unlocked ? badge.icon : '?',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              badge.description,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color get _rarityBorderColor => switch (badge.rarity) {
    SmBadgeRarity.common => const Color(0xFF10B981),
    SmBadgeRarity.rare => const Color(0xFF3B82F6),
    SmBadgeRarity.legendary => const Color(0xFFFFD700),
  };
}
