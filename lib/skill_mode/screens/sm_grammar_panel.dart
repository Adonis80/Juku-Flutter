import 'package:flutter/material.dart';

import '../widgets/tile/sm_tile_row.dart';
import '../widgets/tile/sm_tile_widget.dart';

/// Press 3 grammar markup bottom sheet (SM-1.5).
///
/// Shows tile row at 0.8x scale at top, draws coloured lines from each
/// tile to its annotation block below (sequential draw, 50ms stagger).
class SmGrammarPanel extends StatefulWidget {
  final List<Map<String, dynamic>> tiles;
  final Map<String, dynamic> grammarMetadata;

  const SmGrammarPanel({
    super.key,
    required this.tiles,
    this.grammarMetadata = const {},
  });

  /// Show the grammar panel as a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required List<Map<String, dynamic>> tiles,
    Map<String, dynamic> grammarMetadata = const {},
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SmGrammarPanel(
          tiles: tiles,
          grammarMetadata: grammarMetadata,
        ),
      ),
    );
  }

  @override
  State<SmGrammarPanel> createState() => _SmGrammarPanelState();
}

class _SmGrammarPanelState extends State<SmGrammarPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lineController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 50 * widget.tiles.length + 300),
    )..forward();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Tile row at 0.8x scale
          Center(
            child: SmTileRow(
              tiles: widget.tiles,
              scale: 0.8,
              nativeOpacity: 0.3,
            ),
          ),
          const SizedBox(height: 24),

          // Grammar rule (if present)
          if (widget.grammarMetadata['note'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.grammarMetadata['note'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Annotation list
          Expanded(
            child: AnimatedBuilder(
              animation: _lineController,
              builder: (context, _) {
                return ListView.separated(
                  itemCount: widget.tiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    // Stagger: each annotation appears 50ms apart
                    final threshold = index / widget.tiles.length;
                    final visible = _lineController.value >= threshold;
                    if (!visible) return const SizedBox.shrink();

                    return _AnnotationEntry(
                      tile: widget.tiles[index],
                      isExpanded: _expandedIndex == index,
                      onTap: () {
                        setState(() {
                          _expandedIndex =
                              _expandedIndex == index ? -1 : index;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnotationEntry extends StatelessWidget {
  final Map<String, dynamic> tile;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AnnotationEntry({
    required this.tile,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = tile['word'] as String? ?? '';
    final pos = tile['pos'] as String?;
    final native = tile['native'] as String?;
    final tileType = tile['type'] as String? ?? 'standard';
    final posColor = smPosColor(pos);
    final isGhost = tile['is_ghost'] == true;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: posColor, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  word,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (pos != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: posColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pos.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: posColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                if (isGhost) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'GHOST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
            if (native != null && native.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                native,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (isExpanded) ...[
              const SizedBox(height: 8),
              _buildExpandedContent(context, tileType),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, String tileType) {
    final theme = Theme.of(context);
    final details = <String>[];

    if (tileType == 'ghost') {
      details.add('This word exists in German but has no direct English equivalent. '
          'It appears in the sentence structure but is "invisible" in translation.');
    } else if (tileType == 'particle') {
      details.add('A grammatical particle — it modifies meaning or structure '
          'but doesn\'t translate directly as a standalone word.');
    } else if (tileType == 'inflected') {
      details.add('This word changes form based on person, tense, or case.');
    } else if (tileType == 'compound') {
      details.add('A compound expression — two words that function as one unit.');
    }

    if (details.isEmpty) {
      details.add('Standard vocabulary tile.');
    }

    return Text(
      details.join('\n'),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }
}

