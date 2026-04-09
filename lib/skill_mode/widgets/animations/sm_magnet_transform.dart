import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../tile/sm_tile_widget.dart';

/// The signature Magnet Animation (SM-1.4).
///
/// Tiles spring from native word order to foreign word order with
/// physics-based springs. Each tile has its own AnimationController.
///
/// Architecture (per CLAUDE.md critical notes):
/// - Stack + Positioned — NOT AnimatedContainer
/// - Spring: SpringDescription(mass: 1, stiffness: 300, damping: 20)
/// - Each tile independent controller
/// - RepaintBoundary on each tile
/// - Z-arc: reorder stack children mid-animation when paths cross
/// - Target 60fps on Pixel 4a
class SmMagnetTransform extends StatefulWidget {
  final List<Map<String, dynamic>> tiles;
  final List<int> nativeWordOrder;
  final List<int> foreignWordOrder;
  final bool showForeignOrder;
  final double nativeOpacity;
  final VoidCallback? onComplete;

  const SmMagnetTransform({
    super.key,
    required this.tiles,
    required this.nativeWordOrder,
    required this.foreignWordOrder,
    this.showForeignOrder = false,
    this.nativeOpacity = 1.0,
    this.onComplete,
  });

  @override
  State<SmMagnetTransform> createState() => _SmMagnetTransformState();
}

class _SmMagnetTransformState extends State<SmMagnetTransform>
    with TickerProviderStateMixin {
  // Layout
  final List<GlobalKey> _tileKeys = [];
  final List<Offset> _nativePositions = [];
  final List<Offset> _foreignPositions = [];
  final List<Size> _tileSizes = [];
  bool _measured = false;
  bool _animating = false;

  // Per-tile spring animations
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];

  // Z-ordering: indices sorted by which tile should be on top
  List<int> _zOrder = [];

  // Shimmer
  bool _shimmerActive = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 300, damping: 20);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.tiles.length; i++) {
      _tileKeys.add(GlobalKey());
      _nativePositions.add(Offset.zero);
      _foreignPositions.add(Offset.zero);
      _tileSizes.add(Size.zero);
    }
    _zOrder = List.generate(widget.tiles.length, (i) => i);
  }

  @override
  void didUpdateWidget(SmMagnetTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showForeignOrder != oldWidget.showForeignOrder && _measured) {
      _runAnimation();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _measureAndStore() {
    if (_measured) return;
    final parentBox = context.findRenderObject() as RenderBox?;
    if (parentBox == null) return;
    final parentOffset = parentBox.localToGlobal(Offset.zero);

    // Measure each tile's current rendered position
    final positions = <int, Offset>{};
    final sizes = <int, Size>{};

    for (var i = 0; i < _tileKeys.length; i++) {
      final box =
          _tileKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      positions[i] = box.localToGlobal(Offset.zero) - parentOffset;
      sizes[i] = box.size;
    }

    // Current layout is native order.
    // Calculate foreign positions by reordering tiles.
    final nativeOrder = widget.nativeWordOrder;
    final foreignOrder = widget.foreignWordOrder;

    for (var i = 0; i < widget.tiles.length; i++) {
      _tileSizes[i] = sizes[i] ?? Size.zero;
    }

    // Native positions = current positions by native order index
    for (var i = 0; i < nativeOrder.length; i++) {
      final tileIdx = nativeOrder[i];
      if (tileIdx < _nativePositions.length) {
        _nativePositions[tileIdx] = positions[i] ?? Offset.zero;
      }
    }

    // Calculate foreign positions: tiles reordered by foreignOrder
    // We re-flow tiles into the same row layout but in foreign order
    double x = 0;
    double y = 0;
    const gap = 8.0;
    final maxWidth = parentBox.size.width;
    double rowHeight = 0;

    for (var i = 0; i < foreignOrder.length; i++) {
      final tileIdx = foreignOrder[i];
      final tileSize = _tileSizes.length > tileIdx
          ? _tileSizes[tileIdx]
          : const Size(72, 56);

      if (x + tileSize.width > maxWidth && x > 0) {
        x = 0;
        y += rowHeight + gap;
        rowHeight = 0;
      }

      if (tileIdx < _foreignPositions.length) {
        _foreignPositions[tileIdx] = Offset(x, y);
      }
      x += tileSize.width + gap;
      rowHeight = math.max(rowHeight, tileSize.height);
    }

    _measured = true;
  }

  void _runAnimation() {
    // Dispose previous controllers
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    _animations.clear();

    final goingForeign = widget.showForeignOrder;

    // Phase 1: Shimmer (0-200ms)
    setState(() => _shimmerActive = true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _shimmerActive = false;
        _animating = true;
      });

      // Phase 2: Movement with springs
      // Calculate z-order: tiles that travel further get higher z
      final distances = <int, double>{};
      for (var i = 0; i < widget.tiles.length; i++) {
        final from = goingForeign ? _nativePositions[i] : _foreignPositions[i];
        final to = goingForeign ? _foreignPositions[i] : _nativePositions[i];
        distances[i] = (to - from).distance;
      }
      _zOrder = List.generate(widget.tiles.length, (i) => i)
        ..sort((a, b) => (distances[a] ?? 0).compareTo(distances[b] ?? 0));

      int completed = 0;

      for (var i = 0; i < widget.tiles.length; i++) {
        final from = goingForeign ? _nativePositions[i] : _foreignPositions[i];
        final to = goingForeign ? _foreignPositions[i] : _nativePositions[i];

        final controller = AnimationController.unbounded(vsync: this);

        final simulation = SpringSimulation(_spring, 0.0, 1.0, 0.0);

        final animation = Tween<Offset>(begin: from, end: to)
            .animate(controller);

        _controllers.add(controller);
        _animations.add(animation);

        controller.addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            completed++;
            if (completed == widget.tiles.length) {
              if (mounted) {
                setState(() => _animating = false);
              }
              widget.onComplete?.call();
            }
          }
        });

        controller.animateWith(simulation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Schedule measurement after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_measured) _measureAndStore();
    });

    // If animating, render as positioned stack
    if (_animating && _animations.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: _calculateStackHeight(),
        child: Stack(
          clipBehavior: Clip.none,
          children: _zOrder.map((i) {
            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, child) {
                return Positioned(
                  left: _animations[i].value.dx,
                  top: _animations[i].value.dy,
                  child: child!,
                );
              },
              child: RepaintBoundary(
                child: _buildTile(i),
              ),
            );
          }).toList(),
        ),
      );
    }

    // Static render: show tiles in current order
    final order =
        widget.showForeignOrder ? widget.foreignWordOrder : widget.nativeWordOrder;
    final orderedTiles = order.map((idx) => widget.tiles[idx]).toList();
    final orderedKeys = order.map((idx) => _tileKeys[idx]).toList();

    Widget row = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(orderedTiles.length, (i) {
        final t = orderedTiles[i];
        return SmTileWidget(
          key: orderedKeys[i],
          foreignText: t['word'] as String? ?? '',
          nativeText: t['native'] as String?,
          tileType: t['type'] as String? ?? 'standard',
          partOfSpeech: t['pos'] as String?,
          nativeOpacity: widget.nativeOpacity,
        );
      }),
    );

    if (_shimmerActive) {
      row = row.animate().shimmer(
            duration: const Duration(milliseconds: 200),
            color: Theme.of(context).colorScheme.primary.withAlpha(50),
          );
    }

    return row;
  }

  Widget _buildTile(int index) {
    final t = widget.tiles[index];
    // Non-moving tiles get a scale pulse
    final from = widget.showForeignOrder
        ? _nativePositions[index]
        : _foreignPositions[index];
    final to = widget.showForeignOrder
        ? _foreignPositions[index]
        : _nativePositions[index];
    final isStationary = (to - from).distance < 2.0;

    Widget tile = SmTileWidget(
      foreignText: t['word'] as String? ?? '',
      nativeText: t['native'] as String?,
      tileType: t['type'] as String? ?? 'standard',
      partOfSpeech: t['pos'] as String?,
      nativeOpacity: widget.nativeOpacity,
    );

    if (isStationary) {
      tile = tile
          .animate()
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: const Duration(milliseconds: 150),
          )
          .then()
          .scale(
            begin: const Offset(1.05, 1.05),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 150),
          );
    }

    return tile;
  }

  double _calculateStackHeight() {
    double maxY = 0;
    final positions =
        widget.showForeignOrder ? _foreignPositions : _nativePositions;
    for (var i = 0; i < positions.length; i++) {
      final bottom = positions[i].dy + (_tileSizes[i].height);
      if (bottom > maxY) maxY = bottom;
    }
    return maxY + 16;
  }
}

