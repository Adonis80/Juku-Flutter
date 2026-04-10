import 'package:flutter/material.dart';

import '../services/sm_items_service.dart';

/// Items bar — shows streak freeze count and XP booster status (SM-11).
class SmItemsBar extends StatefulWidget {
  final String userId;
  const SmItemsBar({super.key, required this.userId});

  @override
  State<SmItemsBar> createState() => _SmItemsBarState();
}

class _SmItemsBarState extends State<SmItemsBar> {
  final _service = SmItemsService();
  int _freezeCount = 0;
  Map<String, dynamic>? _activeBooster;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final freezes = await _service.countAvailable(
        userId: widget.userId,
        itemType: 'streak_freeze',
      );
      final booster = await _service.getActiveBooster(widget.userId);

      if (mounted) {
        setState(() {
          _freezeCount = freezes;
          _activeBooster = booster;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Streak freeze count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{2744}\u{FE0F}', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$_freezeCount',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Active XP booster
        if (_activeBooster != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{26A1}', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${(_activeBooster!['multiplier'] as num?)?.toStringAsFixed(0) ?? '2'}x XP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
