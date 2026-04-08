import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/supabase_config.dart';
import 'multiplayer_state.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const LobbyScreen({super.key, required this.sessionId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  GameSession? _session;
  List<GamePlayer> _players = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _playersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _sessionSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _playersSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sessionData = await supabase
          .from('game_sessions')
          .select()
          .eq('id', widget.sessionId)
          .single();

      final session = GameSession.fromJson(sessionData);

      final playersData = await supabase
          .from('game_players')
          .select('*, profiles!game_players_player_id_fkey(username, rank)')
          .eq('session_id', widget.sessionId)
          .order('joined_at');

      final players = (playersData as List)
          .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _session = session;
          _players = players;
          _loading = false;
        });
      }

      // Real-time player subscription
      _playersSub = supabase
          .from('game_players')
          .stream(primaryKey: ['id'])
          .eq('session_id', widget.sessionId)
          .listen((_) async {
        final fresh = await supabase
            .from('game_players')
            .select('*, profiles!game_players_player_id_fkey(username, rank)')
            .eq('session_id', widget.sessionId)
            .order('joined_at');
        if (mounted) {
          setState(() {
            _players = (fresh as List)
                .map((e) => GamePlayer.fromJson(e as Map<String, dynamic>))
                .toList();
          });
        }
      });

      // Real-time session subscription
      _sessionSub = supabase
          .from('game_sessions')
          .stream(primaryKey: ['id'])
          .eq('id', widget.sessionId)
          .listen((data) {
        if (data.isNotEmpty && mounted) {
          setState(() => _session = GameSession.fromJson(data.first));
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = supabase.auth.currentUser?.id;

    // Navigate to game when status changes to in_progress
    if (_session?.status == GameStatus.inProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/studio/game/${widget.sessionId}');
      });
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $_error')),
      );
    }

    final session = _session!;
    final isHost = session.hostId == currentUserId;
    final playerCount = _players.length;
    final canStart = isHost && playerCount >= 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'Join my quiz game on Juku! '
                      'https://juku.pro/join/${widget.sessionId}',
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.group,
                        size: 32, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$playerCount / ${session.maxPlayers} players',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Waiting for players...',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Player list
            Text('Players',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  final isPlayerHost =
                      player.playerId == session.hostId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primaryContainer,
                        child: Text(
                          (player.username ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            color:
                                theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '@${player.username ?? 'player'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500),
                      ),
                      trailing: isPlayerHost
                          ? Icon(Icons.star,
                              color: Colors.amber.shade600,
                              size: 20)
                          : null,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
            ),

            // Bottom actions
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isHost)
                    FilledButton.icon(
                      onPressed: canStart
                          ? () => startGame(widget.sessionId)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(canStart
                          ? 'Start Game'
                          : 'Need at least 2 players'),
                    )
                  else
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Waiting for host to start...'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
