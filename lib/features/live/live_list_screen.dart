import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import 'live_service.dart';

/// Shows all currently live sessions and lets the user start one.
class LiveListScreen extends StatefulWidget {
  const LiveListScreen({super.key});

  @override
  State<LiveListScreen> createState() => _LiveListScreenState();
}

class _LiveListScreenState extends State<LiveListScreen> {
  List<LiveSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await LiveService.instance.getLiveSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  Future<void> _startSession() async {
    final titleController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go Live'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Session title (e.g. "German Basics")',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, titleController.text),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    final session = await LiveService.instance.startSession(
      title: result.trim(),
    );

    if (session != null && mounted) {
      GoRouter.of(context).push('/live/${session.id}', extra: {'isHost': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Juku Live')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startSession,
        icon: const Icon(Icons.videocam),
        label: const Text('Go Live'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.live_tv,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No live sessions right now',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to go live!',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                itemBuilder: (_, index) {
                  final session = _sessions[index];
                  return _LiveSessionCard(session: session).animate().fadeIn(
                    delay: Duration(milliseconds: index * 80),
                    duration: 300.ms,
                  );
                },
              ),
            ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          GoRouter.of(context).push(
            '/live/${session.id}',
            extra: {'isHost': supabase.auth.currentUser?.id == session.hostId},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Live indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.circle, color: Colors.red, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title.isNotEmpty ? session.title : 'Live Session',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.hostName ?? 'Unknown host',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${session.viewerCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  if (session.totalGiftsJuice > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '\u{1F9C3} ${session.totalGiftsJuice}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
