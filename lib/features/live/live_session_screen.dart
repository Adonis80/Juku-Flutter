import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import 'live_service.dart';

/// The main live session screen — used by both host and viewers.
class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({
    super.key,
    required this.sessionId,
    this.isHost = false,
  });

  final String sessionId;
  final bool isHost;

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  LiveSession? _session;
  bool _loading = true;
  int _viewerCount = 0;
  int _currentCardIndex = 0;
  List<Map<String, dynamic>> _topGifters = [];

  // Gift animation state
  LiveGiftType? _lastGift;
  bool _showGiftAnimation = false;

  StreamSubscription<int>? _cardSub;
  StreamSubscription<Map<String, dynamic>>? _giftSub;
  StreamSubscription<int>? _viewerSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cardSub?.cancel();
    _giftSub?.cancel();
    _viewerSub?.cancel();
    LiveService.instance.leaveSession();
    super.dispose();
  }

  Future<void> _load() async {
    // Fetch session info
    final data = await supabase
        .from('live_sessions')
        .select('*, profiles!live_sessions_host_id_fkey(display_name)')
        .eq('id', widget.sessionId)
        .maybeSingle();

    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session not found')),
        );
        GoRouter.of(context).pop();
      }
      return;
    }

    final session = LiveSession.fromMap(data);

    // Join Realtime channels
    final streams = LiveService.instance.joinSession(widget.sessionId);

    _cardSub = streams.cardAdvances.listen((index) {
      if (mounted) setState(() => _currentCardIndex = index);
    });

    _giftSub = streams.gifts.listen((payload) {
      if (mounted) {
        final giftName = payload['gift_type'] as String? ?? 'wave';
        final giftType = LiveGiftType.values.firstWhere(
          (g) => g.name == giftName,
          orElse: () => LiveGiftType.wave,
        );
        _showGiftOverlay(giftType);
        _loadGifters();
      }
    });

    _viewerSub = streams.viewerCount.listen((count) {
      if (mounted) setState(() => _viewerCount = count);
    });

    if (mounted) {
      setState(() {
        _session = session;
        _currentCardIndex = session.currentCardIndex;
        _viewerCount = session.viewerCount;
        _loading = false;
      });
    }

    _loadGifters();
  }

  Future<void> _loadGifters() async {
    final gifters =
        await LiveService.instance.getTopGifters(widget.sessionId);
    if (mounted) setState(() => _topGifters = gifters);
  }

  void _showGiftOverlay(LiveGiftType giftType) {
    setState(() {
      _lastGift = giftType;
      _showGiftAnimation = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showGiftAnimation = false);
    });
  }

  Future<void> _sendGift(LiveGiftType giftType) async {
    final session = _session;
    if (session == null) return;

    final success = await LiveService.instance.sendGift(
      sessionId: session.id,
      hostId: session.hostId,
      giftType: giftType,
    );

    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough Juice')),
        );
      }
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('This will end the live session for all viewers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await LiveService.instance.endSession(widget.sessionId);
    if (mounted) GoRouter.of(context).pop();
  }

  void _advanceCard(int delta) {
    final newIndex = _currentCardIndex + delta;
    if (newIndex < 0) return;
    setState(() => _currentCardIndex = newIndex);
    LiveService.instance.advanceCard(widget.sessionId, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = _session!;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.black
          : theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar: session info + viewer count
                _buildTopBar(theme, session),

                // Main content area: current card display
                Expanded(child: _buildCardArea(theme)),

                // Top gifters leaderboard
                if (_topGifters.isNotEmpty) _buildGifterBar(theme),

                // Bottom: gift buttons (viewer) or controls (host)
                _buildBottomControls(theme),
              ],
            ),

            // Gift animation overlay
            if (_showGiftAnimation && _lastGift != null)
              _GiftOverlay(giftType: _lastGift!),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, LiveSession session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).pop(),
          ),
          const SizedBox(width: 8),
          // Live indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                Text(
                  session.hostName ?? 'Host',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          // Viewer count
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_viewerCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardArea(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card number
          Text(
            'Card ${_currentCardIndex + 1}',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder card display
          Container(
            width: 280,
            height: 400,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Card ${_currentCardIndex + 1}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(key: ValueKey(_currentCardIndex))
              .slideX(begin: 0.3, duration: 300.ms, curve: Curves.easeOut)
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildGifterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Top Gifters',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          ..._topGifters.take(3).indexed.map((entry) {
            final (i, gifter) = entry;
            final medals = ['\u{1F947}', '\u{1F948}', '\u{1F949}'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Text(medals[i], style: const TextStyle(fontSize: 14)),
                label: Text(
                  '${gifter['name']} (${gifter['total']}J)',
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    if (widget.isHost) {
      // Host controls: prev/next card + end session
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton.filled(
              onPressed: () => _advanceCard(-1),
              icon: const Icon(Icons.arrow_back),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop),
              label: const Text('End'),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: () => _advanceCard(1),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      );
    }

    // Viewer controls: gift buttons
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: LiveGiftType.values.map((giftType) {
          return _GiftButton(
            giftType: giftType,
            onTap: () => _sendGift(giftType),
          );
        }).toList(),
      ),
    );
  }
}

/// Animated gift overlay that plays when a gift is sent.
class _GiftOverlay extends StatelessWidget {
  const _GiftOverlay({required this.giftType});

  final LiveGiftType giftType;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Text(
            giftType.emoji,
            style: const TextStyle(fontSize: 120),
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.2, 1.2),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 200.ms)
              .then()
              .fadeOut(delay: 800.ms, duration: 400.ms),
        ),
      ),
    );
  }
}

/// A gift button for viewers.
class _GiftButton extends StatelessWidget {
  const _GiftButton({
    required this.giftType,
    required this.onTap,
  });

  final LiveGiftType giftType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: Text(
                giftType.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          giftType.label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          '${giftType.juice}J',
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
