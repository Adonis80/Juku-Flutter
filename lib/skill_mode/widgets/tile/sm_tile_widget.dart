import 'package:flutter/material.dart';

/// Base tile widget — renders all 5 tile types.
/// Full implementation in SM-1.1.
class SmTileWidget extends StatelessWidget {
  final String foreignText;
  final String? nativeText;
  final String tileType;
  final String? partOfSpeech;

  const SmTileWidget({
    super.key,
    required this.foreignText,
    this.nativeText,
    this.tileType = 'standard',
    this.partOfSpeech,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: tileType == 'ghost' || tileType == 'particle'
            ? Border.all(
                color: Theme.of(context).colorScheme.outline.withAlpha(153),
                style: BorderStyle.solid,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            foreignText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (nativeText != null)
            Text(
              nativeText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
