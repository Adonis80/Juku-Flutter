import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../core/supabase_config.dart';
import '../../features/auth/auth_state.dart';
import '../models/sm_card.dart';
import '../services/sm_audio_service.dart';
import '../services/sm_pronunciation_service.dart';
import '../state/sm_session_notifier.dart';
import '../widgets/pronunciation/sm_phoneme_feedback.dart';
import '../widgets/pronunciation/sm_waveform_widget.dart';

/// Pronunciation recording + scoring screen (SM-4.2 + SM-4.3).
///
/// Tap-and-hold mic to record. Waveform shows live amplitude.
/// On release: uploads, scores via Edge Function, shows feedback.
class SmPronunciationScreen extends ConsumerStatefulWidget {
  final String cardId;

  const SmPronunciationScreen({super.key, required this.cardId});

  @override
  ConsumerState<SmPronunciationScreen> createState() =>
      _SmPronunciationScreenState();
}

class _SmPronunciationScreenState extends ConsumerState<SmPronunciationScreen>
    with TickerProviderStateMixin {
  SmCard? _card;
  bool _loading = true;
  bool _isRecording = false;
  bool _isScoring = false;
  SmPronunciationResult? _result;

  final _recorder = AudioRecorder();
  final _audio = SmAudioService.instance;
  final _pronunciationService = SmPronunciationService.instance;

  // Live waveform data.
  final List<double> _userAmplitudes = [];
  Timer? _amplitudeTimer;

  // Reference waveform (static pattern).
  late List<double> _referenceAmplitudes;

  @override
  void initState() {
    super.initState();
    _referenceAmplitudes = _generateReferencePattern();
    _loadCard();
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  List<double> _generateReferencePattern() {
    final rng = Random(42);
    return List.generate(80, (i) {
      // Simulated speech envelope: build up, sustain, taper.
      final t = i / 80.0;
      final envelope = sin(t * pi) * 0.6 + 0.2;
      return (envelope + rng.nextDouble() * 0.15).clamp(0.0, 1.0);
    });
  }

  Future<void> _loadCard() async {
    try {
      final data = await supabase
          .from('skill_mode_cards')
          .select()
          .eq('id', widget.cardId)
          .single();

      if (mounted) {
        setState(() {
          _card = SmCard.fromJson(data);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    setState(() {
      _isRecording = true;
      _userAmplitudes.clear();
      _result = null;
    });

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '', // Let record choose temp path.
    );

    // Poll amplitude every 50ms.
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (
      _,
    ) async {
      final amp = await _recorder.getAmplitude();
      if (mounted && _isRecording) {
        setState(() {
          // Normalize dBFS to 0–1. -60dB = silence, 0dB = max.
          final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          _userAmplitudes.add(normalized);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _amplitudeTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isScoring = true;
    });

    if (path == null || _card == null) {
      setState(() => _isScoring = false);
      return;
    }

    // Score pronunciation.
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isScoring = false);
      return;
    }

    final result = await _pronunciationService.score(
      wavPath: path,
      referenceText: _card!.foreignText,
      language: _card!.language == 'de' ? 'de-DE' : 'en-US',
      userId: user.id,
      cardId: _card!.id,
    );

    if (mounted) {
      setState(() {
        _result = result;
        _isScoring = false;
      });

      // Award XP if scored.
      if (result != null && result.xpReward > 0) {
        ref.read(smSessionProvider.notifier).addXp(result.xpReward);
      }
    }
  }

  void _playReference() {
    final card = _card;
    if (card != null) {
      _audio.playCardAudio(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pronunciation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final card = _card;
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pronunciation')),
        body: const Center(child: Text('Card not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Play reference audio.
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _playReference,
            tooltip: 'Hear reference',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Target sentence.
            Text(
              card.foreignText,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              card.nativeText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Waveform.
            SmWaveformWidget(
              userAmplitudes: _userAmplitudes,
              referenceAmplitudes: _referenceAmplitudes,
              isRecording: _isRecording,
            ),
            const SizedBox(height: 32),

            // Mic button.
            _buildMicButton(theme),
            const SizedBox(height: 8),
            Text(
              _isRecording
                  ? 'Release to stop'
                  : _isScoring
                  ? 'Scoring...'
                  : 'Hold to record',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Result.
            if (_result != null) _buildResult(card, theme),

            if (_isScoring)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(ThemeData theme) {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isRecording ? 80 : 72,
        height: _isRecording ? 80 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          boxShadow: [
            if (_isRecording)
              BoxShadow(
                color: theme.colorScheme.error.withAlpha(80),
                blurRadius: 20,
                spreadRadius: 5,
              ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildResult(SmCard card, ThemeData theme) {
    final result = _result!;
    final gradeColor = switch (result.grade) {
      'perfect' => const Color(0xFFF59E0B),
      'good' => const Color(0xFF10B981),
      'almost' => const Color(0xFFF97316),
      _ => const Color(0xFFEF4444),
    };
    final gradeLabel = switch (result.grade) {
      'perfect' => 'Perfect!',
      'good' => 'Good!',
      'almost' => 'Almost there',
      _ => 'Try again',
    };

    return Column(
      children: [
        // Score.
        Text(
          '${result.overallScore}%',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: gradeColor,
          ),
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 4),
        Text(
          gradeLabel,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: gradeColor,
          ),
        ),
        const SizedBox(height: 12),

        // Score bar.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: result.overallScore / 100,
            minHeight: 8,
            color: gradeColor,
            backgroundColor: gradeColor.withAlpha(30),
          ),
        ),
        const SizedBox(height: 16),

        // Phoneme feedback on tiles.
        if (card.sentenceTiles != null)
          SmPhonemeFeedback(
            tiles: card.sentenceTiles!,
            weakTileIndices: result.weakTileIndices,
          ),

        const SizedBox(height: 16),

        // XP earned.
        if (result.xpReward > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(
                  '+${result.xpReward} XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
      ],
    );
  }
}
