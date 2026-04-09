import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Conjugation tumbler dial for inflected tiles (SM-2.2).
///
/// Vertical scroll through conjugation forms. Swipe up/down to spin.
/// Correct form: heavy haptic + gold glow + lock icon.
/// Overshoot: spring simulation snaps back.
class SmConjugationDial extends StatefulWidget {
  final List<String> forms;
  final int correctIndex;
  final ValueChanged<int>? onLocked;

  /// Optional label shown above the dial (e.g., "ich", "du", etc.).
  final String? label;

  const SmConjugationDial({
    super.key,
    required this.forms,
    required this.correctIndex,
    this.onLocked,
    this.label,
  });

  @override
  State<SmConjugationDial> createState() => _SmConjugationDialState();
}

class _SmConjugationDialState extends State<SmConjugationDial>
    with SingleTickerProviderStateMixin {
  late double _currentPosition;
  bool _isLocked = false;
  late AnimationController _springController;
  double _dragStartPosition = 0;
  double _dragStartOffset = 0;

  // Gold glow animation.
  double _glowOpacity = 0;

  // Lock icon animation.
  double _lockScale = 0;

  static const double _itemExtent = 48.0;

  @override
  void initState() {
    super.initState();
    // Start at a random non-correct position.
    final rng = Random();
    int startIndex;
    do {
      startIndex = rng.nextInt(widget.forms.length);
    } while (startIndex == widget.correctIndex && widget.forms.length > 1);
    _currentPosition = startIndex.toDouble();

    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(_onSpringUpdate);
  }

  @override
  void dispose() {
    _springController.removeListener(_onSpringUpdate);
    _springController.dispose();
    super.dispose();
  }

  void _onSpringUpdate() {
    setState(() {
      _currentPosition = _springController.value;
    });

    // Check if we've settled on the correct index.
    final roundedIndex = _currentPosition.round();
    if (!_isLocked &&
        roundedIndex == widget.correctIndex &&
        (_currentPosition - roundedIndex).abs() < 0.05 &&
        _springController.velocity.abs() < 0.5) {
      _lock();
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_isLocked) return;
    _springController.stop();
    _dragStartPosition = _currentPosition;
    _dragStartOffset = details.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isLocked) return;
    final delta = details.localPosition.dy - _dragStartOffset;
    setState(() {
      _currentPosition = _dragStartPosition - delta / _itemExtent;
      _currentPosition = _currentPosition.clamp(
        -0.5,
        widget.forms.length - 0.5,
      );
    });

    // Haptic on crossing notch boundaries.
    final roundedNow = _currentPosition.round();
    final distToNotch = (_currentPosition - roundedNow).abs();
    if (distToNotch < 0.05) {
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isLocked) return;
    final velocity = -details.velocity.pixelsPerSecond.dy / _itemExtent;

    // Determine target notch.
    double targetNotch;
    if (velocity.abs() > 1) {
      targetNotch = (_currentPosition + velocity * 0.3).roundToDouble();
    } else {
      targetNotch = _currentPosition.roundToDouble();
    }
    targetNotch = targetNotch.clamp(0, widget.forms.length - 1.0);

    // Overshoot spring: go 0.5 notch past then spring back.
    final spring = SpringDescription(mass: 0.5, stiffness: 500, damping: 15);
    final simulation = SpringSimulation(
      spring,
      _currentPosition,
      targetNotch,
      velocity,
    );

    _springController.animateWith(simulation);
  }

  void _lock() {
    setState(() => _isLocked = true);
    HapticFeedback.heavyImpact();
    widget.onLocked?.call(widget.correctIndex);

    // Animate gold glow.
    _animateGlow();
    // Animate lock icon.
    _animateLockIcon();
  }

  Future<void> _animateGlow() async {
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _glowOpacity = i < 5 ? (i + 1) * 0.2 : (10 - i) * 0.2;
      });
    }
    if (mounted) setState(() => _glowOpacity = 0);
  }

  Future<void> _animateLockIcon() async {
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        // Elastic scale: overshoot then settle.
        final t = (i + 1) / 10.0;
        _lockScale = t < 0.6 ? t / 0.6 * 1.3 : 1.0 + (1 - t) / 0.4 * 0.3;
      });
    }
    if (mounted) setState(() => _lockScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        GestureDetector(
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Container(
            width: 120,
            height: _itemExtent * 3,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isLocked
                    ? const Color(0xFFF59E0B)
                    : theme.colorScheme.outline.withAlpha(80),
                width: _isLocked ? 2 : 1,
              ),
              boxShadow: [
                if (_glowOpacity > 0)
                  BoxShadow(
                    color: const Color(0xFFF59E0B)
                        .withAlpha((_glowOpacity * 150).round().clamp(0, 255)),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Form items.
                ...List.generate(widget.forms.length, (index) {
                  final offset = (index - _currentPosition) * _itemExtent;
                  final centerY = _itemExtent * 1.5;
                  final y = centerY + offset - _itemExtent / 2;
                  final distFromCenter = (offset / _itemExtent).abs();
                  final opacity = (1 - distFromCenter * 0.4).clamp(0.0, 1.0);
                  final scale = (1 - distFromCenter * 0.15).clamp(0.7, 1.0);

                  final isSelected = index == _currentPosition.round() &&
                      (_currentPosition - index).abs() < 0.3;
                  final isCorrectAndLocked = _isLocked && index == widget.correctIndex;

                  return Positioned(
                    left: 0,
                    right: 0,
                    top: y,
                    height: _itemExtent,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: Text(
                            widget.forms[index],
                            style: TextStyle(
                              fontSize: isSelected ? 18 : 15,
                              fontWeight: isCorrectAndLocked
                                  ? FontWeight.w800
                                  : isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                              color: isCorrectAndLocked
                                  ? const Color(0xFFF59E0B)
                                  : isSelected
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Center selection highlight.
                Positioned(
                  left: 8,
                  right: 8,
                  top: _itemExtent,
                  height: _itemExtent,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isLocked
                              ? const Color(0xFFF59E0B).withAlpha(100)
                              : theme.colorScheme.primary.withAlpha(60),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Lock icon overlay.
                if (_isLocked && _lockScale > 0)
                  Positioned(
                    right: 8,
                    top: _itemExtent + (_itemExtent - 20) / 2,
                    child: Transform.scale(
                      scale: _lockScale,
                      child: const Icon(
                        Icons.lock,
                        size: 20,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),

                // Top/bottom gradient fade.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _itemExtent * 0.8,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surfaceContainerHighest,
                            theme.colorScheme.surfaceContainerHighest
                                .withAlpha(0),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _itemExtent * 0.8,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.colorScheme.surfaceContainerHighest,
                            theme.colorScheme.surfaceContainerHighest
                                .withAlpha(0),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Multi-dial widget — stacks multiple conjugation dials horizontally (SM-2.2).
///
/// Used for agglutinative languages (e.g., Turkish) where a verb
/// has multiple inflection axes. Shows progress: "2 of 3 locked".
class SmMultiDial extends StatefulWidget {
  final List<SmDialConfig> dials;
  final VoidCallback? onAllLocked;

  const SmMultiDial({
    super.key,
    required this.dials,
    this.onAllLocked,
  });

  @override
  State<SmMultiDial> createState() => _SmMultiDialState();
}

class _SmMultiDialState extends State<SmMultiDial> {
  late List<bool> _lockedStates;

  @override
  void initState() {
    super.initState();
    _lockedStates = List.filled(widget.dials.length, false);
  }

  void _onDialLocked(int dialIndex, int formIndex) {
    setState(() {
      _lockedStates[dialIndex] = true;
    });

    final lockedCount = _lockedStates.where((l) => l).length;
    if (lockedCount == widget.dials.length) {
      // All locked — triple haptic + callback.
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.heavyImpact();
          widget.onAllLocked?.call();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lockedCount = _lockedStates.where((l) => l).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress indicator.
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$lockedCount of ${widget.dials.length} locked',
            style: theme.textTheme.labelMedium?.copyWith(
              color: lockedCount == widget.dials.length
                  ? const Color(0xFFF59E0B)
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Dials row.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.dials.length, (i) {
            final config = widget.dials[i];
            return Padding(
              padding: EdgeInsets.only(
                left: i > 0 ? 12 : 0,
              ),
              child: SmConjugationDial(
                forms: config.forms,
                correctIndex: config.correctIndex,
                label: config.label,
                onLocked: (formIndex) => _onDialLocked(i, formIndex),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Configuration for a single dial in a multi-dial setup.
class SmDialConfig {
  final List<String> forms;
  final int correctIndex;
  final String? label;

  const SmDialConfig({
    required this.forms,
    required this.correctIndex,
    this.label,
  });
}
