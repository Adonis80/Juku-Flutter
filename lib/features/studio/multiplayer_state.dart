import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_config.dart';

enum GameStatus { waiting, inProgress, finished }

GameStatus gameStatusFromDb(String value) {
  switch (value) {
    case 'in_progress':
      return GameStatus.inProgress;
    case 'finished':
      return GameStatus.finished;
    default:
      return GameStatus.waiting;
  }
}

String gameStatusToDb(GameStatus s) {
  switch (s) {
    case GameStatus.waiting:
      return 'waiting';
    case GameStatus.inProgress:
      return 'in_progress';
    case GameStatus.finished:
      return 'finished';
  }
}

class GameSession {
  final String id;
  final String moduleId;
  final String hostId;
  final GameStatus status;
  final int maxPlayers;
  final Map<String, dynamic> config;
  final int currentQuestion;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const GameSession({
    required this.id,
    required this.moduleId,
    required this.hostId,
    required this.status,
    required this.maxPlayers,
    required this.config,
    required this.currentQuestion,
    this.startedAt,
    this.finishedAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      hostId: json['host_id'] as String,
      status: gameStatusFromDb(json['status'] as String),
      maxPlayers: json['max_players'] as int? ?? 4,
      config: json['config'] as Map<String, dynamic>? ?? {},
      currentQuestion: json['current_question'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      finishedAt: json['finished_at'] != null
          ? DateTime.tryParse(json['finished_at'] as String)
          : null,
    );
  }
}

class GamePlayer {
  final String id;
  final String sessionId;
  final String playerId;
  final int score;
  final int currentQuestion;
  final bool finished;
  final String? username;
  final String? rank;

  const GamePlayer({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.score,
    required this.currentQuestion,
    required this.finished,
    this.username,
    this.rank,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return GamePlayer(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      playerId: json['player_id'] as String,
      score: json['score'] as int? ?? 0,
      currentQuestion: json['current_question'] as int? ?? 0,
      finished: json['finished'] as bool? ?? false,
      username: profile?['username'] as String?,
      rank: profile?['rank'] as String?,
    );
  }
}

// --- Lobby state ---

class LobbyState {
  final GameSession? session;
  final List<GamePlayer> players;
  final bool loading;
  final String? error;

  const LobbyState({
    this.session,
    this.players = const [],
    this.loading = true,
    this.error,
  });

  LobbyState copyWith({
    GameSession? session,
    List<GamePlayer>? players,
    bool? loading,
    String? error,
  }) {
    return LobbyState(
      session: session ?? this.session,
      players: players ?? this.players,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Loads lobby state for a session. Uses FutureProvider for initial load.
/// Real-time updates are handled in the LobbyScreen widget directly.
final lobbySessionProvider = FutureProvider.family<GameSession, String>((
  ref,
  sessionId,
) async {
  final data = await supabase
      .from('game_sessions')
      .select()
      .eq('id', sessionId)
      .single();
  return GameSession.fromJson(data);
});

final lobbyPlayersProvider = FutureProvider.family<List<GamePlayer>, String>((
  ref,
  sessionId,
) async {
  final data = await supabase
      .from('game_players')
      .select('*, profiles!game_players_player_id_fkey(username, rank)')
      .eq('session_id', sessionId)
      .order('joined_at');

  return (data as List)
      .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Combined lobby state provider
final lobbyProvider = Provider.family<LobbyState, String>((ref, sessionId) {
  final sessionAsync = ref.watch(lobbySessionProvider(sessionId));
  final playersAsync = ref.watch(lobbyPlayersProvider(sessionId));

  return LobbyState(
    session: sessionAsync.value,
    players: playersAsync.value ?? [],
    loading: sessionAsync.isLoading || playersAsync.isLoading,
    error: sessionAsync.error?.toString() ?? playersAsync.error?.toString(),
  );
});

// --- Helpers ---

Future<String> createGameSession({
  required String moduleId,
  int maxPlayers = 4,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Not authenticated');

  final result = await supabase
      .from('game_sessions')
      .insert({
        'module_id': moduleId,
        'host_id': user.id,
        'max_players': maxPlayers,
      })
      .select('id')
      .single();

  final sessionId = result['id'] as String;

  // Auto-join host as first player
  await supabase.from('game_players').insert({
    'session_id': sessionId,
    'player_id': user.id,
  });

  return sessionId;
}

Future<void> joinGameSession(String sessionId) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Not authenticated');

  await supabase.from('game_players').upsert({
    'session_id': sessionId,
    'player_id': user.id,
  });
}

Future<void> startGame(String sessionId) async {
  await supabase
      .from('game_sessions')
      .update({
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      })
      .eq('id', sessionId);
}

Future<void> advanceQuestion(String sessionId, int questionIndex) async {
  await supabase
      .from('game_sessions')
      .update({'current_question': questionIndex})
      .eq('id', sessionId);
}

Future<void> updatePlayerScore(
  String sessionId,
  String playerId,
  int score,
  int questionIdx, {
  bool finished = false,
}) async {
  await supabase
      .from('game_players')
      .update({
        'score': score,
        'current_question': questionIdx,
        'finished': finished,
      })
      .eq('session_id', sessionId)
      .eq('player_id', playerId);
}

Future<void> finishGame(String sessionId) async {
  await supabase
      .from('game_sessions')
      .update({
        'status': 'finished',
        'finished_at': DateTime.now().toIso8601String(),
      })
      .eq('id', sessionId);
}

Future<void> awardMultiplayerXp(
  String sessionId,
  String moduleCreatorId,
) async {
  final players = await supabase
      .from('game_players')
      .select('player_id, score')
      .eq('session_id', sessionId)
      .order('score', ascending: false);

  final playerList = players as List;
  for (var i = 0; i < playerList.length; i++) {
    final playerId = playerList[i]['player_id'] as String;
    int xp;
    if (i == 0) {
      xp = 10;
    } else if (i == 1) {
      xp = 5;
    } else if (i == 2) {
      xp = 3;
    } else {
      xp = 2;
    }

    await supabase.from('xp_events').insert({
      'user_id': playerId,
      'event_type': 'multiplayer_${i == 0 ? "win" : "play"}',
      'xp_amount': xp,
    });
  }

  // Creator XP
  await supabase.from('xp_events').insert({
    'user_id': moduleCreatorId,
    'event_type': 'multiplayer_creator',
    'xp_amount': 5,
  });
}
