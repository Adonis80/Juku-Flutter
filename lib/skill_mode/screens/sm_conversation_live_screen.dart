import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/sm_conversation_state.dart';

/// Live AI conversation screen (GL-3).
///
/// Hold mic to record → transcription → AI response → TTS playback.
/// Shows chat bubbles, live waveform, and per-turn scores.
class SmConversationLiveScreen extends ConsumerStatefulWidget {
  const SmConversationLiveScreen({super.key});

  @override
  ConsumerState<SmConversationLiveScreen> createState() =>
      _SmConversationLiveScreenState();
}

class _SmConversationLiveScreenState
    extends ConsumerState<SmConversationLiveScreen> {
  final _scrollController = ScrollController();
  final _audioPlayer = AudioPlayer();
  bool _isPlayingTts = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _playTts() async {
    setState(() => _isPlayingTts = true);
    try {
      final audioBytes = await ref
          .read(conversationProvider.notifier)
          .synthesizeLastReply();
      if (audioBytes != null && mounted) {
        await _audioPlayer.play(BytesSource(audioBytes));
        _audioPlayer.onPlayerComplete.first.then((_) {
          if (mounted) setState(() => _isPlayingTts = false);
        });
      } else {
        if (mounted) setState(() => _isPlayingTts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isPlayingTts = false);
    }
  }

  Future<void> _endConversation() async {
    final result = await ref
        .read(conversationProvider.notifier)
        .endConversation();
    if (result != null && mounted) {
      context.pushReplacement('/skill/conversation/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final convState = ref.watch(conversationProvider);
    final conversation = convState.conversation;

    // Auto-scroll when messages change.
    ref.listen(conversationProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(conversation?.scenario?.title ?? 'Conversation'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showEndDialog(),
        ),
        actions: [
          // Turn counter.
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${convState.messages.where((m) => m.role == 'user').length} turns',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score bar (running average).
          if (convState.scoredTurns > 0)
            _RunningScoreBar(
              fluency: convState.avgFluency,
              vocabulary: convState.avgVocabulary,
              grammar: convState.avgGrammar,
            ),

          // Chat messages.
          Expanded(
            child: convState.messages.isEmpty
                ? _EmptyState(
                    scenarioTitle:
                        conversation?.scenario?.title ?? 'Conversation',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: convState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = convState.messages[index];
                      final isUser = msg.role == 'user';

                      return _ChatBubble(
                            content: msg.content,
                            isUser: isUser,
                            onPlayTts: !isUser ? _playTts : null,
                            isPlayingTts: !isUser && _isPlayingTts,
                          )
                          .animate()
                          .fadeIn(duration: const Duration(milliseconds: 200))
                          .slideX(
                            begin: isUser ? 0.1 : -0.1,
                            end: 0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                    },
                  ),
          ),

          // Corrections display.
          if (convState.lastScores != null &&
              convState.lastScores!.corrections.isNotEmpty)
            _CorrectionsBar(corrections: convState.lastScores!.corrections),

          // Error display.
          if (convState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.errorContainer,
              child: Text(
                convState.error!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),

          // Bottom controls.
          _BottomControls(
            phase: convState.phase,
            amplitudes: convState.amplitudes,
            onStartRecording: () =>
                ref.read(conversationProvider.notifier).startRecording(),
            onStopRecording: () => ref
                .read(conversationProvider.notifier)
                .stopRecordingAndProcess(),
            onEndConversation: _endConversation,
          ),
        ],
      ),
    );
  }

  void _showEndDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End conversation?'),
        content: const Text('Your conversation will be scored and XP awarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _endConversation();
            },
            child: const Text('End & Score'),
          ),
        ],
      ),
    );
  }
}

// ── Running Score Bar ──

class _RunningScoreBar extends StatelessWidget {
  final int fluency;
  final int vocabulary;
  final int grammar;

  const _RunningScoreBar({
    required this.fluency,
    required this.vocabulary,
    required this.grammar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ScoreChip('Fluency', fluency, const Color(0xFF6366F1)),
          _ScoreChip('Vocab', vocabulary, const Color(0xFFF59E0B)),
          _ScoreChip('Grammar', grammar, const Color(0xFF10B981)),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreChip(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $score',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Empty State ──

class _EmptyState extends StatelessWidget {
  final String scenarioTitle;

  const _EmptyState({required this.scenarioTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.record_voice_over,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              scenarioTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hold the mic button and speak.\nThe AI will respond as a native speaker.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chat Bubble ──

class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final VoidCallback? onPlayTts;
  final bool isPlayingTts;

  const _ChatBubble({
    required this.content,
    required this.isUser,
    this.onPlayTts,
    this.isPlayingTts = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (!isUser && onPlayTts != null) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: isPlayingTts ? null : onPlayTts,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPlayingTts
                                ? Icons.volume_up
                                : Icons.play_circle_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPlayingTts ? 'Playing...' : 'Listen',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Corrections Bar ──

class _CorrectionsBar extends StatelessWidget {
  final List<String> corrections;

  const _CorrectionsBar({required this.corrections});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: const Border(
          top: BorderSide(color: Color(0xFFFCD34D), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Corrections',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF92400E),
            ),
          ),
          ...corrections.map(
            (c) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $c',
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Controls ──

class _BottomControls extends StatelessWidget {
  final ConversationPhase phase;
  final List<double> amplitudes;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onEndConversation;

  const _BottomControls({
    required this.phase,
    required this.amplitudes,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onEndConversation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecording = phase == ConversationPhase.recording;
    final isProcessing =
        phase == ConversationPhase.transcribing ||
        phase == ConversationPhase.thinking;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Waveform when recording.
            if (isRecording && amplitudes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 40,
                  child: CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: _WaveformPainter(
                      amplitudes: amplitudes,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),

            // Status text.
            if (isProcessing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phase == ConversationPhase.transcribing
                          ? 'Transcribing...'
                          : 'AI is thinking...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Buttons.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // End button.
                TextButton.icon(
                  onPressed: isProcessing ? null : onEndConversation,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('End'),
                ),

                const SizedBox(width: 16),

                // Mic button.
                GestureDetector(
                  onLongPressStart: isProcessing
                      ? null
                      : (_) => onStartRecording(),
                  onLongPressEnd: isProcessing
                      ? null
                      : (_) => onStopRecording(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isRecording ? 80 : 64,
                    height: isRecording ? 80 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording
                          ? theme.colorScheme.error
                          : isProcessing
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primary,
                      boxShadow: [
                        if (isRecording)
                          BoxShadow(
                            color: theme.colorScheme.error.withAlpha(80),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                      ],
                    ),
                    child: Icon(
                      isRecording ? Icons.mic : Icons.mic_none,
                      color: isProcessing
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.white,
                      size: isRecording ? 36 : 28,
                    ),
                  ),
                ),

                const SizedBox(width: 56), // Balance layout.
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waveform Painter ──

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _WaveformPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = 4.0;
    final maxBars = (size.width / barWidth).floor();
    final startIdx = amplitudes.length > maxBars
        ? amplitudes.length - maxBars
        : 0;

    for (var i = startIdx; i < amplitudes.length; i++) {
      final barIdx = i - startIdx;
      final x = barIdx * barWidth + barWidth / 2;
      final amp = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = max(2.0, amp * size.height * 0.9);
      canvas.drawLine(
        Offset(x, size.height / 2 - barHeight / 2),
        Offset(x, size.height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.amplitudes.length != amplitudes.length;
}
