import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import 'multiplayer_state.dart';

class MultiplayerGameScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const MultiplayerGameScreen({super.key, required this.sessionId});

  @override
  ConsumerState<MultiplayerGameScreen> createState() =>
      _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends ConsumerState<MultiplayerGameScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _currentIdx = 0;
  int _myScore = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _showingLeaderboard = false;
  bool _gameFinished = false;
  Timer? _timer;
  int _timeLeft = 0;
  String? _moduleCreatorId;

  @override
  void initState() {
    super.initState();
    _loadModule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadModule() async {
    final lobby = ref.read(lobbyProvider(widget.sessionId));
    final session = lobby.session;
    if (session == null) return;

    final moduleData = await supabase
        .from('studio_modules')
        .select('config, creator_id')
        .eq('id', session.moduleId)
        .single();

    final config = moduleData['config'] as Map<String, dynamic>;
    _moduleCreatorId = moduleData['creator_id'] as String?;

    setState(() {
      _questions = (config['questions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });

    _startTimer(config['time_limit_secs'] as int? ?? 0);
  }

  void _startTimer(int limit) {
    if (limit <= 0) return;
    _timeLeft = limit;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _onAnswer(-1);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _onAnswer(int idx) {
    if (_answered) return;
    _timer?.cancel();

    final correctIdx = _questions[_currentIdx]['answer'] as int? ?? 0;
    final isCorrect = idx == correctIdx;

    setState(() {
      _selectedAnswer = idx;
      _answered = true;
      if (isCorrect) {
        _myScore += 10 + (_timeLeft > 0 ? _timeLeft ~/ 2 : 0);
      }
    });

    // Update score in DB
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      updatePlayerScore(
        widget.sessionId,
        userId,
        _myScore,
        _currentIdx + 1,
        finished: _currentIdx >= _questions.length - 1,
      );
    }

    // Show leaderboard flash, then advance
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _showingLeaderboard = true);
    });

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      setState(() => _showingLeaderboard = false);

      if (_currentIdx < _questions.length - 1) {
        setState(() {
          _currentIdx++;
          _selectedAnswer = null;
          _answered = false;
        });

        // Host advances question
        final lobby = ref.read(lobbyProvider(widget.sessionId));
        if (lobby.session?.hostId == supabase.auth.currentUser?.id) {
          advanceQuestion(widget.sessionId, _currentIdx);
        }

        final config = _questions.isNotEmpty
            ? ref.read(lobbyProvider(widget.sessionId)).session?.config
            : null;
        _startTimer((config?['time_limit_secs'] as int?) ?? 0);
      } else {
        // Game over
        setState(() => _gameFinished = true);
        final lobby = ref.read(lobbyProvider(widget.sessionId));
        if (lobby.session?.hostId == supabase.auth.currentUser?.id) {
          finishGame(widget.sessionId);
          if (_moduleCreatorId != null) {
            awardMultiplayerXp(widget.sessionId, _moduleCreatorId!);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lobby = ref.watch(lobbyProvider(widget.sessionId));

    if (_gameFinished) {
      return _buildFinalLeaderboard(theme, lobby);
    }

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showingLeaderboard) {
      return _buildLeaderboardFlash(theme, lobby);
    }

    final q = _questions[_currentIdx];
    final options = List<String>.from(q['options'] as List? ?? []);
    final correctIdx = q['answer'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Q${_currentIdx + 1} / ${_questions.length}'),
        actions: [
          // Player progress dots
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: lobby.players.map((p) {
                final color = _playerColor(lobby.players.indexOf(p));
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.finished ? color : color.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentIdx + 1) / _questions.length),
          if (_timeLeft > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '$_timeLeft',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _timeLeft <= 5
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Text(
              q['q'] as String? ?? '',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: List.generate(options.length, (i) {
                Color? bgColor;
                Color? fgColor;

                if (_answered) {
                  if (i == correctIdx) {
                    bgColor = Colors.green.withValues(alpha: 0.15);
                    fgColor = Colors.green;
                  } else if (i == _selectedAnswer) {
                    bgColor = Colors.red.withValues(alpha: 0.15);
                    fgColor = Colors.red;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: bgColor ?? theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _answered ? null : () => _onAnswer(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          options[i],
                          style: TextStyle(
                            color: fgColor,
                            fontWeight: fgColor != null
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // My score bar
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your score: ',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  '$_myScore',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardFlash(ThemeData theme, LobbyState lobby) {
    final sorted = List<GamePlayer>.from(lobby.players)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Standings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            ...sorted.asMap().entries.map((e) {
              final idx = e.key;
              final p = e.value;
              final isMe = p.playerId == supabase.auth.currentUser?.id;

              return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 4,
                    ),
                    child: Card(
                      color: isMe ? theme.colorScheme.primaryContainer : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _playerColor(idx),
                          radius: 16,
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          '@${p.username ?? 'player'}${isMe ? ' (you)' : ''}',
                          style: TextStyle(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          '${p.score}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: (idx * 100).ms)
                  .slideY(begin: 0.2, end: 0);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalLeaderboard(ThemeData theme, LobbyState lobby) {
    final sorted = List<GamePlayer>.from(lobby.players)
      ..sort((a, b) => b.score.compareTo(a.score));
    final currentUserId = supabase.auth.currentUser?.id;
    final myRank = sorted.indexWhere((p) => p.playerId == currentUserId);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.amber,
              ).animate().scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 12),
              Text(
                'Game Over!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 300.ms),
              if (myRank >= 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+${myRank == 0
                        ? 10
                        : myRank == 1
                        ? 5
                        : myRank == 2
                        ? 3
                        : 2} XP',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final p = sorted[index];
                    final isMe = p.playerId == currentUserId;

                    return Card(
                          color: isMe
                              ? theme.colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _playerColor(index),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '@${p.username ?? 'player'}${isMe ? ' (you)' : ''}',
                              style: TextStyle(
                                fontWeight: isMe
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              '${p.score}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (index * 150).ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                ),
              ),
              FilledButton(
                onPressed: () => context.go('/studio'),
                child: const Text('Back to Studio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _playerColor(int index) {
    const colors = [
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF10B981),
      Color(0xFFF97316),
    ];
    return colors[index % colors.length];
  }
}
