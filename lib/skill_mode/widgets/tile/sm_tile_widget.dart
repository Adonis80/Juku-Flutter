import 'package:flutter/material.dart';

import 'sm_tile_types.dart';

/// POS-based colour map for tile left-accent borders.
Color smPosColor(String? pos) {
  return switch (pos) {
    'noun' => const Color(0xFF3B82F6),
    'verb' => const Color(0xFF10B981),
    'adjective' => const Color(0xFFF59E0B),
    'article' || 'particle' || 'conjunction' => const Color(0xFF6B7280),
    _ => const Color(0xFF8B5CF6),
  };
}

/// The fundamental UI unit — renders all 5 tile types.
///
/// Visual spec (SM-1.1):
/// - 56dp height, 12dp corner radius, min 48dp width
/// - POS colour left-accent border
/// - Foreign word bold 18sp, native word small 12sp below
/// - Ghost/Particle: dashed-style border, 60% opacity, grey tint
/// - Inflected: root + suffix chip
/// - Compound: two words stacked with "+" divider
class SmTileWidget extends StatelessWidget {
  final String foreignText;
  final String? nativeText;
  final String tileType;
  final String? partOfSpeech;
  final double nativeOpacity;
  final bool isFaceDown;
  final Map<String, dynamic>? tileConfig;

  /// Optional overlay widget from a grammar module (gender band, case chip).
  final Widget? overlay;

  const SmTileWidget({
    super.key,
    required this.foreignText,
    this.nativeText,
    this.tileType = SmTileTypes.standard,
    this.partOfSpeech,
    this.nativeOpacity = 1.0,
    this.isFaceDown = false,
    this.tileConfig,
    this.overlay,
  });

  bool get _isGhostLike =>
      tileType == SmTileTypes.ghost || tileType == SmTileTypes.particle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posColor = smPosColor(partOfSpeech);

    if (isFaceDown) {
      return _buildFaceDown(theme);
    }

    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            height: 56,
            padding: const EdgeInsets.only(
              left: 16,
              right: 12,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color: _isGhostLike
                  ? theme.colorScheme.surfaceContainerHighest.withAlpha(153)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: _isGhostLike
                  ? Border.all(color: theme.colorScheme.outline.withAlpha(100))
                  : Border(left: BorderSide(color: posColor, width: 4)),
            ),
            child: _buildContent(theme),
          ),
          ?overlay,
        ],
      ),
    );
  }

  Widget _buildFaceDown(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 56,
      width: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(60)),
      ),
      child: Center(
        child: Icon(
          Icons.help_outline,
          size: 20,
          color: theme.colorScheme.outline.withAlpha(100),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return switch (tileType) {
      SmTileTypes.inflected => _buildInflected(theme),
      SmTileTypes.compound => _buildCompound(theme),
      _ => _buildStandard(theme),
    };
  }

  Widget _buildStandard(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          foreignText,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isGhostLike
                ? theme.colorScheme.onSurface.withAlpha(153)
                : theme.colorScheme.onSurface,
          ),
        ),
        if (nativeText != null && nativeText!.isNotEmpty)
          Opacity(
            opacity: nativeOpacity,
            child: Text(
              nativeText!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInflected(ThemeData theme) {
    final root = tileConfig?['root'] as String? ?? foreignText;
    final suffix = tileConfig?['suffix'] as String? ?? '';
    final suffixColor = tileConfig?['suffix_color'] as String?;
    final chipColor = suffixColor != null
        ? Color(int.parse(suffixColor.replaceFirst('#', '0xFF')))
        : const Color(0xFF10B981);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              root,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (suffix.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: chipColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
          ],
        ),
        if (nativeText != null && nativeText!.isNotEmpty)
          Opacity(
            opacity: nativeOpacity,
            child: Text(
              nativeText!,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompound(ThemeData theme) {
    final parts = foreignText.split(' ');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.length >= 2) ...[
          Text(
            parts[0],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '+',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.outline),
          ),
          Text(
            parts.sublist(1).join(' '),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ] else
          Text(
            foreignText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}
