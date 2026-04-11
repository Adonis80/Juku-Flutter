import 'package:flutter_test/flutter_test.dart';
import 'package:juku/skill_mode/models/sm_conversation.dart';

void main() {
  group('ConversationScenario', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'sc-1',
        'title': 'At the Airport',
        'description': 'Navigate check-in and boarding.',
        'language': 'de',
        'difficulty': 'beginner',
        'icon_name': 'flight',
        'sort_order': 1,
      };
      final scenario = ConversationScenario.fromJson(json);
      expect(scenario.id, 'sc-1');
      expect(scenario.title, 'At the Airport');
      expect(scenario.description, 'Navigate check-in and boarding.');
      expect(scenario.language, 'de');
      expect(scenario.difficulty, 'beginner');
      expect(scenario.iconName, 'flight');
      expect(scenario.sortOrder, 1);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {'id': 'sc-2', 'title': 'Test', 'description': 'Test desc'};
      final scenario = ConversationScenario.fromJson(json);
      expect(scenario.language, 'de');
      expect(scenario.difficulty, 'beginner');
      expect(scenario.iconName, 'chat');
      expect(scenario.sortOrder, 0);
    });
  });

  group('AiConversation', () {
    test('fromJson parses completed conversation', () {
      final json = {
        'id': 'conv-1',
        'user_id': 'u-1',
        'scenario_id': 'sc-1',
        'language': 'de',
        'status': 'completed',
        'fluency_score': 85,
        'vocabulary_score': 70,
        'grammar_score': 90,
        'overall_score': 82,
        'xp_awarded': 35,
        'turn_count': 5,
        'duration_seconds': 120,
        'created_at': '2026-04-11T10:00:00Z',
        'completed_at': '2026-04-11T10:02:00Z',
      };
      final conv = AiConversation.fromJson(json);
      expect(conv.id, 'conv-1');
      expect(conv.userId, 'u-1');
      expect(conv.status, 'completed');
      expect(conv.fluencyScore, 85);
      expect(conv.vocabularyScore, 70);
      expect(conv.grammarScore, 90);
      expect(conv.overallScore, 82);
      expect(conv.xpAwarded, 35);
      expect(conv.turnCount, 5);
      expect(conv.durationSeconds, 120);
      expect(conv.completedAt, isNotNull);
    });

    test('fromJson handles active conversation with nulls', () {
      final json = {
        'id': 'conv-2',
        'user_id': 'u-2',
        'language': 'fr',
        'status': 'active',
        'turn_count': 0,
        'created_at': '2026-04-11T11:00:00Z',
      };
      final conv = AiConversation.fromJson(json);
      expect(conv.status, 'active');
      expect(conv.fluencyScore, isNull);
      expect(conv.overallScore, isNull);
      expect(conv.xpAwarded, 0);
      expect(conv.completedAt, isNull);
      expect(conv.scenario, isNull);
    });

    test('fromJson with nested scenario', () {
      final json = {
        'id': 'conv-3',
        'user_id': 'u-1',
        'scenario_id': 'sc-1',
        'language': 'de',
        'status': 'active',
        'turn_count': 2,
        'created_at': '2026-04-11T12:00:00Z',
        'ai_conversation_scenarios': {
          'id': 'sc-1',
          'title': 'Restaurant',
          'description': 'Order food.',
          'language': 'de',
          'difficulty': 'beginner',
          'icon_name': 'restaurant',
          'sort_order': 2,
        },
      };
      final conv = AiConversation.fromJson(json);
      expect(conv.scenario, isNotNull);
      expect(conv.scenario!.title, 'Restaurant');
    });
  });

  group('ConversationMessage', () {
    test('fromJson parses user message', () {
      final json = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'role': 'user',
        'content': 'Hallo, ich möchte einchecken.',
        'transcription': 'Hallo, ich möchte einchecken.',
        'duration_ms': 2500,
        'created_at': '2026-04-11T10:00:05Z',
      };
      final msg = ConversationMessage.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.role, 'user');
      expect(msg.content, 'Hallo, ich möchte einchecken.');
      expect(msg.transcription, 'Hallo, ich möchte einchecken.');
      expect(msg.durationMs, 2500);
    });

    test('fromJson handles assistant message without audio', () {
      final json = {
        'id': 'msg-2',
        'conversation_id': 'conv-1',
        'role': 'assistant',
        'content': 'Willkommen! Ihren Ausweis bitte.',
        'created_at': '2026-04-11T10:00:10Z',
      };
      final msg = ConversationMessage.fromJson(json);
      expect(msg.role, 'assistant');
      expect(msg.audioUrl, isNull);
      expect(msg.durationMs, isNull);
    });
  });

  group('ConversationScores', () {
    test('fromJson parses scores with corrections', () {
      final json = {
        'fluency': 80,
        'vocabulary': 65,
        'grammar': 90,
        'corrections': [
          'Use "dem" instead of "den" here',
          'Missing article before noun',
        ],
      };
      final scores = ConversationScores.fromJson(json);
      expect(scores.fluency, 80);
      expect(scores.vocabulary, 65);
      expect(scores.grammar, 90);
      expect(scores.overall, 78); // (80+65+90)/3 = 78.33 → 78
      expect(scores.corrections, hasLength(2));
    });

    test('fromJson handles empty/null corrections', () {
      final json = <String, dynamic>{
        'fluency': 50,
        'vocabulary': 50,
        'grammar': 50,
      };
      final scores = ConversationScores.fromJson(json);
      expect(scores.corrections, isEmpty);
      expect(scores.overall, 50);
    });

    test('fromJson handles null scores', () {
      final json = <String, dynamic>{};
      final scores = ConversationScores.fromJson(json);
      expect(scores.fluency, 0);
      expect(scores.vocabulary, 0);
      expect(scores.grammar, 0);
      expect(scores.overall, 0);
    });
  });

  group('AiApiKey', () {
    test('fromJson parses valid key', () {
      final json = {
        'id': 'key-1',
        'user_id': 'u-1',
        'provider': 'openai',
        'is_valid': true,
        'created_at': '2026-04-11T10:00:00Z',
      };
      final key = AiApiKey.fromJson(json);
      expect(key.id, 'key-1');
      expect(key.provider, 'openai');
      expect(key.isValid, true);
    });

    test('fromJson handles invalid key', () {
      final json = {
        'id': 'key-2',
        'user_id': 'u-1',
        'provider': 'elevenlabs',
        'is_valid': false,
        'created_at': '2026-04-11T10:00:00Z',
      };
      final key = AiApiKey.fromJson(json);
      expect(key.isValid, false);
    });
  });

  group('XP calculation', () {
    test('perfect score gives 50 XP', () {
      expect(_calculateXp(95), 50);
    });
    test('good score gives 35 XP', () {
      expect(_calculateXp(80), 35);
    });
    test('okay score gives 25 XP', () {
      expect(_calculateXp(65), 25);
    });
    test('low score gives 15 XP', () {
      expect(_calculateXp(45), 15);
    });
    test('very low score gives 10 XP participation', () {
      expect(_calculateXp(20), 10);
    });
  });
}

// Mirror of the XP calculation from SmConversationService for testing.
int _calculateXp(int overallScore) {
  if (overallScore >= 90) return 50;
  if (overallScore >= 75) return 35;
  if (overallScore >= 60) return 25;
  if (overallScore >= 40) return 15;
  return 10;
}
