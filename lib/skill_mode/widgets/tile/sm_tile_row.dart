import 'package:flutter/material.dart';

import 'sm_tile_widget.dart';

/// Direction-aware tile row with wrapping (SM-1.2).
///
/// Renders an ordered list of tiles in a `Wrap` with 8dp spacing.
/// Arabic/Hebrew/RTL languages flow right-to-left.
/// Each tile gets a `ValueKey(index)` for animation targeting.
class SmTileRow extends StatelessWidget {
  final List<Map<String, dynamic>> tiles;
  final TextDirection textDirection;
  final double nativeOpacity;
  final bool allFaceDown;
  final double scale;

  const SmTileRow({
    super.key,
    required this.tiles,
    this.textDirection = TextDirection.ltr,
    this.nativeOpacity = 1.0,
    this.allFaceDown = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Directionality(
        textDirection: textDirection,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(tiles.length, (index) {
            final t = tiles[index];
            return SmTileWidget(
              key: ValueKey(index),
              foreignText: t['word'] as String? ?? '',
              nativeText: t['native'] as String?,
              tileType: t['type'] as String? ?? 'standard',
              partOfSpeech: t['pos'] as String?,
              nativeOpacity: nativeOpacity,
              isFaceDown: allFaceDown,
              tileConfig: t['tile_config'] as Map<String, dynamic>?,
            );
          }),
        ),
      ),
    );
  }
}
