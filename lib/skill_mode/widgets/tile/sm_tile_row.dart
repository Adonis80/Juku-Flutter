import 'package:flutter/material.dart';

import 'sm_tile_widget.dart';

/// Direction-aware tile row with wrapping.
/// Full implementation in SM-1.2.
class SmTileRow extends StatelessWidget {
  final List<Map<String, dynamic>> tiles;
  final TextDirection textDirection;

  const SmTileRow({
    super.key,
    required this.tiles,
    this.textDirection = TextDirection.ltr,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tiles
            .map((t) => SmTileWidget(
                  foreignText: t['word'] as String? ?? '',
                  nativeText: t['native'] as String?,
                  tileType: t['type'] as String? ?? 'standard',
                  partOfSpeech: t['pos'] as String?,
                ))
            .toList(),
      ),
    );
  }
}
