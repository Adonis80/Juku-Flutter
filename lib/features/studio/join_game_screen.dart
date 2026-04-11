import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'multiplayer_state.dart';

class JoinGameScreen extends StatefulWidget {
  final String sessionId;

  const JoinGameScreen({super.key, required this.sessionId});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  bool _joining = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    try {
      await joinGameSession(widget.sessionId);
      if (mounted) {
        context.go('/studio/lobby/${widget.sessionId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_joining) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Joining game...', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Could not join game', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _joining = true;
                  _error = null;
                });
                _join();
              },
              child: const Text('Try Again'),
            ),
            TextButton(
              onPressed: () => context.go('/studio'),
              child: const Text('Back to Studio'),
            ),
          ],
        ),
      ),
    );
  }
}
