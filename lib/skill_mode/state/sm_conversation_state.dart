import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_state.dart';
import '../models/sm_conversation.dart';
import '../services/sm_conversation_service.dart';

final _service = SmConversationService.instance;

// ── Scenarios ──

final conversationScenariosProvider =
    FutureProvider.family<List<ConversationScenario>, String>(
  (ref, language) => _service.getScenarios(language: language),
);

// ── Conversation History ──

final conversationHistoryProvider =
    FutureProvider<List<AiConversation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return _service.getHistory(userId: user.id);
});

// ── Active Conversation ──

enum ConversationPhase { idle, recording, transcribing, thinking, speaking }

class ConversationState {
  final AiConversation? conversation;
  final List<ConversationMessage> messages;
  final ConversationPhase phase;
  final List<double> amplitudes;
  final ConversationScores? lastScores;
  final String? error;
  final int runningFluency;
  final int runningVocabulary;
  final int runningGrammar;
  final int scoredTurns;

  const ConversationState({
    this.conversation,
    this.messages = const [],
    this.phase = ConversationPhase.idle,
    this.amplitudes = const [],
    this.lastScores,
    this.error,
    this.runningFluency = 0,
    this.runningVocabulary = 0,
    this.runningGrammar = 0,
    this.scoredTurns = 0,
  });

  int get avgFluency => scoredTurns > 0 ? runningFluency ~/ scoredTurns : 0;
  int get avgVocabulary =>
      scoredTurns > 0 ? runningVocabulary ~/ scoredTurns : 0;
  int get avgGrammar => scoredTurns > 0 ? runningGrammar ~/ scoredTurns : 0;
  int get avgOverall =>
      scoredTurns > 0
          ? ((avgFluency + avgVocabulary + avgGrammar) / 3).round()
          : 0;

  ConversationState copyWith({
    AiConversation? conversation,
    List<ConversationMessage>? messages,
    ConversationPhase? phase,
    List<double>? amplitudes,
    ConversationScores? lastScores,
    String? error,
    int? runningFluency,
    int? runningVocabulary,
    int? runningGrammar,
    int? scoredTurns,
  }) {
    return ConversationState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      phase: phase ?? this.phase,
      amplitudes: amplitudes ?? this.amplitudes,
      lastScores: lastScores ?? this.lastScores,
      error: error ?? this.error,
      runningFluency: runningFluency ?? this.runningFluency,
      runningVocabulary: runningVocabulary ?? this.runningVocabulary,
      runningGrammar: runningGrammar ?? this.runningGrammar,
      scoredTurns: scoredTurns ?? this.scoredTurns,
    );
  }
}

class ConversationNotifier extends Notifier<ConversationState> {
  Timer? _amplitudeTimer;
  DateTime? _startTime;

  @override
  ConversationState build() => const ConversationState();

  Future<void> startConversation({
    required String scenarioId,
    required String language,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final conversation = await _service.startConversation(
        userId: user.id,
        scenarioId: scenarioId,
        language: language,
      );

      _startTime = DateTime.now();

      state = ConversationState(
        conversation: conversation,
        phase: ConversationPhase.idle,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to start conversation: $e');
    }
  }

  Future<void> startRecording() async {
    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Microphone permission required');
      return;
    }

    state = state.copyWith(
      phase: ConversationPhase.recording,
      amplitudes: [],
      lastScores: null,
      error: null,
    );

    await _service.startRecording();

    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) async {
        final amp = await _service.getAmplitude();
        final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
        state = state.copyWith(
          amplitudes: [...state.amplitudes, normalized],
        );
      },
    );
  }

  Future<void> stopRecordingAndProcess() async {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;

    final conversation = state.conversation;
    if (conversation == null) return;

    // Stop recording.
    state = state.copyWith(phase: ConversationPhase.transcribing);
    final audioPath = await _service.stopRecording();

    if (audioPath == null) {
      state = state.copyWith(
        phase: ConversationPhase.idle,
        error: 'Recording failed',
      );
      return;
    }

    // Transcribe.
    final transcription = await _service.transcribe(
      audioPath: audioPath,
      language: conversation.language,
    );

    if (transcription == null || transcription.isEmpty) {
      state = state.copyWith(
        phase: ConversationPhase.idle,
        error: 'Could not transcribe audio. Try speaking louder.',
      );
      return;
    }

    // Add user message to UI immediately.
    final userMsg = ConversationMessage(
      id: 'temp-user-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversation.id,
      role: 'user',
      content: transcription,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      phase: ConversationPhase.thinking,
    );

    // Get AI response.
    final result = await _service.getAiResponse(
      conversationId: conversation.id,
      userMessage: transcription,
    );

    if (result == null) {
      state = state.copyWith(
        phase: ConversationPhase.idle,
        error: 'AI response failed. Check your API key.',
      );
      return;
    }

    // Add assistant message.
    final assistantMsg = ConversationMessage(
      id: 'temp-ai-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversation.id,
      role: 'assistant',
      content: result.reply,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, assistantMsg],
      lastScores: result.scores,
      runningFluency: state.runningFluency + result.scores.fluency,
      runningVocabulary: state.runningVocabulary + result.scores.vocabulary,
      runningGrammar: state.runningGrammar + result.scores.grammar,
      scoredTurns: state.scoredTurns + 1,
      phase: ConversationPhase.speaking,
    );

    // Synthesize speech (non-blocking for UI).
    // Audio playback handled by the screen widget.
    state = state.copyWith(phase: ConversationPhase.idle);
  }

  Future<Uint8List?> synthesizeLastReply() async {
    final conversation = state.conversation;
    if (conversation == null || state.messages.isEmpty) return null;

    final lastAssistant = state.messages.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => state.messages.last,
    );

    return _service.synthesizeSpeech(
      text: lastAssistant.content,
      language: conversation.language,
    );
  }

  Future<AiConversation?> endConversation() async {
    _amplitudeTimer?.cancel();
    final conversation = state.conversation;
    if (conversation == null) return null;

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    final result = await _service.endConversation(
      conversationId: conversation.id,
      fluency: state.avgFluency,
      vocabulary: state.avgVocabulary,
      grammar: state.avgGrammar,
      durationSeconds: duration,
    );

    if (result != null) {
      state = state.copyWith(conversation: result);
    }

    return result;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final conversationProvider =
    NotifierProvider<ConversationNotifier, ConversationState>(
  ConversationNotifier.new,
);

// ── API Keys ──

final aiApiKeysProvider =
    FutureProvider<List<AiApiKey>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return _service.getApiKeys(user.id);
});
