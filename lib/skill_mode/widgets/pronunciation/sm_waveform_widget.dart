import 'dart:math';

import 'package:flutter/material.dart';

/// Dual waveform display — user's live voice + ghost reference (SM-4.2).
///
/// User bars: reactive to mic amplitude, in primaryColor.
/// Ghost bars: pre-rendered reference pattern, in grey/white.
class SmWaveformWidget extends StatelessWidget {
  /// Live amplitude values (0.0–1.0), updated every 50ms.
  final List<double> userAmplitudes;

  /// Reference waveform pattern (static).
  final List<double> referenceAmplitudes;

  /// Whether currently recording.
  final bool isRecording;

  const SmWaveformWidget({
    super.key,
    this.userAmplitudes = const [],
    this.referenceAmplitudes = const [],
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: CustomPaint(
        size: const Size(double.infinity, 120),
        painter: _WaveformPainter(
          userAmplitudes: userAmplitudes,
          referenceAmplitudes: referenceAmplitudes,
          isRecording: isRecording,
          userColor: theme.colorScheme.primary,
          referenceColor: theme.colorScheme.onSurface.withAlpha(40),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> userAmplitudes;
  final List<double> referenceAmplitudes;
  final bool isRecording;
  final Color userColor;
  final Color referenceColor;

  _WaveformPainter({
    required this.userAmplitudes,
    required this.referenceAmplitudes,
    required this.isRecording,
    required this.userColor,
    required this.referenceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final gap = 2.0;
    final maxBars = (size.width / (barWidth + gap)).floor();
    final centerY = size.height / 2;

    // Draw ghost reference waveform (behind).
    if (referenceAmplitudes.isNotEmpty) {
      final refPaint = Paint()
        ..color = referenceColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      for (var i = 0; i < maxBars && i < referenceAmplitudes.length; i++) {
        final amp = referenceAmplitudes[i].clamp(0.0, 1.0);
        final barHeight = max(4.0, amp * size.height * 0.4);
        final x = i * (barWidth + gap) + barWidth / 2;
        canvas.drawLine(
          Offset(x, centerY - barHeight / 2),
          Offset(x, centerY + barHeight / 2),
          refPaint,
        );
      }
    }

    // Draw user waveform (in front).
    if (userAmplitudes.isNotEmpty && isRecording) {
      final userPaint = Paint()
        ..color = userColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      // Show only the most recent bars that fit.
      final startIdx = max(0, userAmplitudes.length - maxBars);
      for (var i = startIdx; i < userAmplitudes.length; i++) {
        final amp = userAmplitudes[i].clamp(0.0, 1.0);
        final barHeight = max(4.0, amp * size.height * 0.8);
        final barIdx = i - startIdx;
        final x = barIdx * (barWidth + gap) + barWidth / 2;
        canvas.drawLine(
          Offset(x, centerY - barHeight / 2),
          Offset(x, centerY + barHeight / 2),
          userPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.userAmplitudes.length != userAmplitudes.length ||
      old.isRecording != isRecording;
}
