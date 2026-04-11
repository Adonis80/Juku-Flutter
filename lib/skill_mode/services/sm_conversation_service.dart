import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../../core/supabase_config.dart';
import '../models/sm_conversation.dart';

/// Service for AI Conversation Partner (GL-3).
///
/// Handles: recording, transcription (Whisper), AI response (Claude),
/// speech synthesis (ElevenLabs), scoring, and conversation CRUD.
class SmConversationService {
  SmConversationService._();
  static final instance = SmConversationService._();

  final _recorder = AudioRecorder();

  // ── Scenarios ──

  Future<List<ConversationScenario>> getScenarios({
    required String language,
  }) async {
    final data = await supabase
        .from('ai_conversation_scenarios')
        .select()
        .eq('language', language)
        .order('sort_order');

    return (data as List)
        .map((e) => ConversationScenario.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Conversations ──

  Future<AiConversation> startConversation({
    required String userId,
    required String scenarioId,
    required String language,
  }) async {
    final data = await supabase
        .from('ai_conversations')
        .insert({
          'user_id': userId,
          'scenario_id': scenarioId,
          'language': language,
          'status': 'active',
        })
        .select('*, ai_conversation_scenarios(*)')
        .single();

    return AiConversation.fromJson(data);
  }

  Future<List<AiConversation>> getHistory({
    required String userId,
    int limit = 20,
  }) async {
    final data = await supabase
        .from('ai_conversations')
        .select('*, ai_conversation_scenarios(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => AiConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConversationMessage>> getMessages(String conversationId) async {
    final data = await supabase
        .from('ai_conversation_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');

    return (data as List)
        .map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Recording ──

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '',
    );
  }

  Future<Amplitude> getAmplitude() async {
    return _recorder.getAmplitude();
  }

  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  // ── Transcribe (Whisper via Edge Function) ──

  Future<String?> transcribe({
    required String audioPath,
    required String language,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final file = File(audioPath);
    if (!file.existsSync()) return null;

    final uri = Uri.parse('$supabaseUrl/functions/v1/transcribe-audio');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..fields['language'] = language
      ..files.add(await http.MultipartFile.fromPath('audio', audioPath));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) return null;

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['text'] as String?;
  }

  // ── AI Response (Claude via Edge Function) ──

  Future<({String reply, ConversationScores scores})?> getAiResponse({
    required String conversationId,
    required String userMessage,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final response = await supabase.functions.invoke(
      'ai-conversation-respond',
      body: {'conversation_id': conversationId, 'user_message': userMessage},
    );

    if (response.status != 200) return null;

    final data = response.data as Map<String, dynamic>;
    final reply = data['reply'] as String? ?? '';
    final scoresJson = data['scores'] as Map<String, dynamic>? ?? {};

    return (reply: reply, scores: ConversationScores.fromJson(scoresJson));
  }

  // ── Speech Synthesis (ElevenLabs via Edge Function) ──

  Future<Uint8List?> synthesizeSpeech({
    required String text,
    required String language,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    final uri = Uri.parse('$supabaseUrl/functions/v1/synthesize-speech');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text, 'language': language}),
    );

    if (response.statusCode != 200) return null;

    return response.bodyBytes;
  }

  // ── End Conversation + Score ──

  Future<AiConversation?> endConversation({
    required String conversationId,
    required int fluency,
    required int vocabulary,
    required int grammar,
    required int durationSeconds,
  }) async {
    final overall = ((fluency + vocabulary + grammar) / 3).round();

    // XP based on performance: max 50 XP for perfect conversation.
    final xp = _calculateXp(overall);

    final data = await supabase
        .from('ai_conversations')
        .update({
          'status': 'completed',
          'fluency_score': fluency,
          'vocabulary_score': vocabulary,
          'grammar_score': grammar,
          'overall_score': overall,
          'xp_awarded': xp,
          'duration_seconds': durationSeconds,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId)
        .select('*, ai_conversation_scenarios(*)')
        .single();

    // Award XP.
    final conversation = AiConversation.fromJson(data);
    if (xp > 0) {
      await supabase.from('xp_events').insert({
        'user_id': conversation.userId,
        'xp': xp,
        'reason': 'ai_conversation_completed',
      });
    }

    return conversation;
  }

  int _calculateXp(int overallScore) {
    if (overallScore >= 90) return 50;
    if (overallScore >= 75) return 35;
    if (overallScore >= 60) return 25;
    if (overallScore >= 40) return 15;
    return 10; // Participation XP.
  }

  // ── API Key Management ──

  Future<List<AiApiKey>> getApiKeys(String userId) async {
    final data = await supabase
        .from('ai_api_keys')
        .select('id, user_id, provider, is_valid, created_at')
        .eq('user_id', userId)
        .order('provider');

    return (data as List)
        .map((e) => AiApiKey.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveApiKey({
    required String userId,
    required String provider,
    required String apiKey,
  }) async {
    await supabase.from('ai_api_keys').upsert({
      'user_id': userId,
      'provider': provider,
      'api_key_encrypted': apiKey,
      'is_valid': true,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,provider');
  }

  Future<void> deleteApiKey({
    required String userId,
    required String provider,
  }) async {
    await supabase
        .from('ai_api_keys')
        .delete()
        .eq('user_id', userId)
        .eq('provider', provider);
  }

  void dispose() {
    _recorder.dispose();
  }
}
