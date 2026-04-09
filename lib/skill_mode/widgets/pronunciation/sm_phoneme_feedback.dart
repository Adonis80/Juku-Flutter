import 'package:flutter/material.dart';

import '../tile/sm_tile_widget.dart';

/// Tile row with weak-phoneme highlighting (SM-4.3).
///
/// Tiles at weak indices get a red underline. Tap to hear phoneme.
class SmPhonemeFeedback extends StatelessWidget {
  final List<Map<String, dynamic>> tiles;
  final List<int> weakTileIndices;

  const SmPhonemeFeedback({
    super.key,
    required this.tiles,
    required this.weakTileIndices,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(tiles.length, (index) {
        final t = tiles[index];
        final isWeak = weakTileIndices.contains(index);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SmTileWidget(
              foreignText: t['word'] as String? ?? '',
              tileType: t['type'] as String? ?? 'standard',
              partOfSpeech: t['pos'] as String?,
              nativeOpacity: 0.0,
              tileConfig: t['tile_config'] as Map<String, dynamic>?,
            ),
            if (isWeak)
              Container(
                height: 3,
                width: 40,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(180),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      }),
    );
  }
}
