import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Writing Mode — stroke order tracing for logographic scripts (SM-12).
///
/// Shows a ghost character, user traces strokes on a canvas.
/// Grades accuracy and stroke order.
class SmWritingScreen extends StatefulWidget {
  final String character;
  final String? pinyin;
  final String meaning;
  final String language; // 'zh' | 'ja'
  final List<List<Offset>>? referenceStrokes;

  const SmWritingScreen({
    super.key,
    required this.character,
    this.pinyin,
    required this.meaning,
    this.language = 'zh',
    this.referenceStrokes,
  });

  @override
  State<SmWritingScreen> createState() => _SmWritingScreenState();
}

class _SmWritingScreenState extends State<SmWritingScreen> {
  // User's drawn strokes
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;

  // Grading
  int _currentStrokeIndex = 0;
  int _correctStrokes = 0;
  bool _completed = false;
  double _accuracy = 0;

  // Display
  bool _showGhost = true;
  bool _showGuide = true;

  int get _totalStrokes =>
      widget.referenceStrokes?.length ?? _estimateStrokes();

  int _estimateStrokes() {
    // Rough stroke count estimate based on character complexity
    final codeUnit = widget.character.codeUnitAt(0);
    if (codeUnit < 0x4E00) return 3; // Simple
    if (codeUnit < 0x6000) return 6; // Medium
    return 9; // Complex
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _isDrawing = false;
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];

      // Grade stroke
      _gradeStroke(_strokes.length - 1);
    });
  }

  void _gradeStroke(int strokeIndex) {
    // Simple grading: compare stroke direction and position to reference
    if (widget.referenceStrokes != null &&
        strokeIndex < widget.referenceStrokes!.length) {
      final ref = widget.referenceStrokes![strokeIndex];
      final drawn = _strokes[strokeIndex];

      if (ref.isNotEmpty && drawn.length >= 2) {
        // Check general direction matches
        final refDir = ref.last - ref.first;
        final drawnDir = drawn.last - drawn.first;
        final dotProduct = refDir.dx * drawnDir.dx + refDir.dy * drawnDir.dy;

        if (dotProduct > 0) {
          _correctStrokes++;
        }
      }
    } else {
      // No reference — accept all strokes
      _correctStrokes++;
    }

    _currentStrokeIndex = strokeIndex + 1;

    if (_currentStrokeIndex >= _totalStrokes) {
      _completed = true;
      _accuracy = _totalStrokes > 0 ? _correctStrokes / _totalStrokes : 1.0;
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _currentStrokeIndex = 0;
      _correctStrokes = 0;
      _completed = false;
      _accuracy = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Practice'),
        actions: [
          // Toggle ghost
          IconButton(
            icon: Icon(
              _showGhost ? Icons.visibility : Icons.visibility_off,
              size: 20,
            ),
            onPressed: () => setState(() => _showGhost = !_showGhost),
            tooltip: 'Toggle ghost character',
          ),
          // Toggle grid guide
          IconButton(
            icon: Icon(_showGuide ? Icons.grid_on : Icons.grid_off, size: 20),
            onPressed: () => setState(() => _showGuide = !_showGuide),
            tooltip: 'Toggle grid guide',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Character info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.character,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (widget.pinyin != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    widget.pinyin!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  widget.meaning,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stroke counter
            Text(
              'Stroke $_currentStrokeIndex of $_totalStrokes',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Drawing canvas
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: cs.outlineVariant, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onPanStart: _completed ? null : _onPanStart,
                      onPanUpdate: _completed ? null : _onPanUpdate,
                      onPanEnd: _completed ? null : _onPanEnd,
                      child: CustomPaint(
                        painter: _WritingCanvasPainter(
                          character: widget.character,
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          showGhost: _showGhost,
                          showGuide: _showGuide,
                          strokeColor: cs.primary,
                          ghostColor: cs.outlineVariant.withValues(alpha: 0.3),
                          guideColor: cs.outlineVariant.withValues(alpha: 0.15),
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results or actions
            if (_completed) ...[
              // Grade display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accuracy >= 0.8
                      ? Colors.green.withValues(alpha: 0.1)
                      : _accuracy >= 0.5
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _accuracy >= 0.8
                          ? Icons.check_circle
                          : _accuracy >= 0.5
                          ? Icons.info
                          : Icons.refresh,
                      color: _accuracy >= 0.8
                          ? Colors.green
                          : _accuracy >= 0.5
                          ? Colors.orange
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_accuracy * 100).toStringAsFixed(0)}% accuracy — '
                      '$_correctStrokes/$_totalStrokes strokes correct',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Clear button
              OutlinedButton.icon(
                onPressed: _strokes.isEmpty ? null : _clear,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Canvas painter for character writing practice.
class _WritingCanvasPainter extends CustomPainter {
  final String character;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final bool showGhost;
  final bool showGuide;
  final Color strokeColor;
  final Color ghostColor;
  final Color guideColor;

  _WritingCanvasPainter({
    required this.character,
    required this.strokes,
    required this.currentStroke,
    required this.showGhost,
    required this.showGuide,
    required this.strokeColor,
    required this.ghostColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Grid guide
    if (showGuide) {
      final guidePaint = Paint()
        ..color = guideColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Center cross
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        guidePaint,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        guidePaint,
      );
      // Diagonal guides
      canvas.drawLine(Offset.zero, Offset(size.width, size.height), guidePaint);
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        guidePaint,
      );
    }

    // Ghost character
    if (showGhost) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: character,
          style: TextStyle(
            fontSize: size.width * 0.75,
            color: ghostColor,
            fontWeight: FontWeight.w300,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    }

    // User strokes
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Current stroke being drawn
    if (currentStroke.length >= 2) {
      final currentPaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.7)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (var i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WritingCanvasPainter oldDelegate) {
    return strokes.length != oldDelegate.strokes.length ||
        currentStroke.length != oldDelegate.currentStroke.length ||
        showGhost != oldDelegate.showGhost ||
        showGuide != oldDelegate.showGuide;
  }
}
