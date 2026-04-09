import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

/// Per-card audio recording widget for deck builder (SM-2.5.2).
///
/// Tap mic → 3-second countdown → record card's foreign text.
/// Waveform shows during recording. Saves path for R2 upload.
class SmCardAudioRecorder extends StatefulWidget {
  final String cardIndex;
  final String deckId;
  final ValueChanged<String> onRecorded;

  const SmCardAudioRecorder({
    super.key,
    required this.cardIndex,
    required this.deckId,
    required this.onRecorded,
  });

  @override
  State<SmCardAudioRecorder> createState() => _SmCardAudioRecorderState();
}

class _SmCardAudioRecorderState extends State<SmCardAudioRecorder> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasRecording = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  final List<double> _amplitudes = [];
  Timer? _amplitudeTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startCountdownThenRecord() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    // 3-second countdown.
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _startRecording();
        }
      });
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _amplitudes.clear();
    });

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '',
    );

    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) async {
        final amp = await _recorder.getAmplitude();
        if (mounted && _isRecording) {
          setState(() {
            final normalized =
                ((amp.current + 60) / 60).clamp(0.0, 1.0);
            _amplitudes.add(normalized);
          });
        }
      },
    );
  }

  Future<void> _stopRecording() async {
    _amplitudeTimer?.cancel();
    final path = await _recorder.stop();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _hasRecording = path != null;
      });

      if (path != null) {
        widget.onRecorded(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_countdown > 0) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            '$_countdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    if (_isRecording) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini waveform.
          SizedBox(
            width: 60,
            height: 24,
            child: CustomPaint(
              painter: _MiniWaveformPainter(
                amplitudes: _amplitudes,
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            iconSize: 28,
            onPressed: _stopRecording,
          ),
        ],
      );
    }

    return IconButton(
      icon: Icon(
        _hasRecording ? Icons.check_circle : Icons.mic,
        color: _hasRecording ? const Color(0xFF10B981) : null,
      ),
      iconSize: 24,
      onPressed: _startCountdownThenRecord,
      tooltip: _hasRecording ? 'Re-record' : 'Record audio',
    );
  }
}

class _MiniWaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _MiniWaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barCount = (size.width / 4).floor();
    final startIdx = (amplitudes.length - barCount).clamp(0, amplitudes.length);

    for (var i = startIdx; i < amplitudes.length; i++) {
      final barIdx = i - startIdx;
      final x = barIdx * 4.0 + 2;
      final amp = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = (amp * size.height * 0.8).clamp(2.0, size.height);
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWaveformPainter old) =>
      old.amplitudes.length != amplitudes.length;
}
