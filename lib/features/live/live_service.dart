import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';

/// Gift tiers for Juku Live.
enum LiveGiftType {
  wave(juice: 1, label: 'Wave', emoji: '\u{1F30A}'),
  fire(juice: 5, label: 'Fire', emoji: '\u{1F525}'),
  crown(juice: 20, label: 'Crown', emoji: '\u{1F451}');

  const LiveGiftType({
    required this.juice,
    required this.label,
    required this.emoji,
  });

  final int juice;
  final String label;
  final String emoji;
}

/// A live session model.
class LiveSession {
  LiveSession({
    required this.id,
    required this.hostId,
    required this.title,
    this.language,
    this.status = 'live',
    this.currentCardIndex = 0,
    this.moduleId,
    this.viewerCount = 0,
    this.totalGiftsJuice = 0,
    this.startedAt,
    this.hostName,
  });

  factory LiveSession.fromMap(Map<String, dynamic> map) {
    return LiveSession(
      id: map['id'] as String,
      hostId: map['host_id'] as String,
      title: map['title'] as String? ?? '',
      language: map['language'] as String?,
      status: map['status'] as String? ?? 'live',
      currentCardIndex: map['current_card_index'] as int? ?? 0,
      moduleId: map['module_id'] as String?,
      viewerCount: map['viewer_count'] as int? ?? 0,
      totalGiftsJuice: map['total_gifts_juice'] as int? ?? 0,
      startedAt: map['started_at'] != null
          ? DateTime.tryParse(map['started_at'] as String)
          : null,
      hostName:
          (map['profiles'] as Map<String, dynamic>?)?['display_name']
              as String?,
    );
  }

  final String id;
  final String hostId;
  final String title;
  final String? language;
  final String status;
  final int currentCardIndex;
  final String? moduleId;
  final int viewerCount;
  final int totalGiftsJuice;
  final DateTime? startedAt;
  final String? hostName;
}

/// Centralized service for Juku Live.
class LiveService {
  LiveService._();
  static final instance = LiveService._();

  RealtimeChannel? _sessionChannel;
  RealtimeChannel? _presenceChannel;

  /// Start a new live session as host.
  Future<LiveSession?> startSession({
    required String title,
    String? language,
    String? moduleId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('live_sessions')
        .insert({
          'host_id': user.id,
          'title': title,
          'language': language,
          'module_id': moduleId,
          'status': 'live',
        })
        .select()
        .single();

    return LiveSession.fromMap(data);
  }

  /// End a live session.
  Future<void> endSession(String sessionId) async {
    await supabase
        .from('live_sessions')
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId);

    _sessionChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _sessionChannel = null;
    _presenceChannel = null;
  }

  /// Advance the current card (host only).
  Future<void> advanceCard(String sessionId, int newIndex) async {
    await supabase
        .from('live_sessions')
        .update({'current_card_index': newIndex})
        .eq('id', sessionId);

    // Broadcast via Realtime
    _sessionChannel?.sendBroadcastMessage(
      event: 'card_advance',
      payload: {'index': newIndex},
    );
  }

  /// Send a gift during a live session.
  Future<bool> sendGift({
    required String sessionId,
    required String hostId,
    required LiveGiftType giftType,
  }) async {
    final result = await supabase.rpc(
      'send_live_gift',
      params: {
        'p_session_id': sessionId,
        'p_host_id': hostId,
        'p_gift_type': giftType.name,
        'p_juice_amount': giftType.juice,
      },
    );

    if (result == true) {
      // Broadcast gift to all viewers
      _sessionChannel?.sendBroadcastMessage(
        event: 'gift',
        payload: {
          'sender_id': supabase.auth.currentUser?.id,
          'gift_type': giftType.name,
          'juice': giftType.juice,
        },
      );
      return true;
    }
    return false;
  }

  /// Subscribe to a session's Realtime channel.
  /// Returns streams for card advances and gifts.
  ({
    Stream<int> cardAdvances,
    Stream<Map<String, dynamic>> gifts,
    Stream<int> viewerCount,
  })
  joinSession(String sessionId) {
    final cardController = StreamController<int>.broadcast();
    final giftController = StreamController<Map<String, dynamic>>.broadcast();
    final viewerController = StreamController<int>.broadcast();

    // Broadcast channel for card advances and gifts
    _sessionChannel = supabase.channel('live:$sessionId');
    _sessionChannel!
        .onBroadcast(
          event: 'card_advance',
          callback: (payload) {
            final index = payload['index'] as int?;
            if (index != null) cardController.add(index);
          },
        )
        .onBroadcast(
          event: 'gift',
          callback: (payload) {
            giftController.add(payload);
          },
        )
        .subscribe();

    // Presence channel for viewer count
    _presenceChannel = supabase.channel('presence:$sessionId');
    _presenceChannel!
        .onPresenceSync((payload) {
          final count = _presenceChannel!.presenceState().length;
          viewerController.add(count);

          // Update viewer count in DB
          supabase
              .from('live_sessions')
              .update({'viewer_count': count})
              .eq('id', sessionId);
        })
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _presenceChannel!.track({
              'user_id': supabase.auth.currentUser?.id,
              'joined_at': DateTime.now().toIso8601String(),
            });
          }
        });

    return (
      cardAdvances: cardController.stream,
      gifts: giftController.stream,
      viewerCount: viewerController.stream,
    );
  }

  /// Leave a session (unsubscribe from channels).
  void leaveSession() {
    _sessionChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _sessionChannel = null;
    _presenceChannel = null;
  }

  /// Fetch all currently live sessions.
  Future<List<LiveSession>> getLiveSessions() async {
    final data = await supabase
        .from('live_sessions')
        .select('*, profiles!live_sessions_host_id_fkey(display_name)')
        .eq('status', 'live')
        .order('started_at', ascending: false);

    return data.map((m) => LiveSession.fromMap(m)).toList();
  }

  /// Fetch top gifters for a session.
  Future<List<Map<String, dynamic>>> getTopGifters(String sessionId) async {
    final data = await supabase
        .from('live_gifts')
        .select('sender_id, profiles!live_gifts_sender_id_fkey(display_name)')
        .eq('session_id', sessionId);

    // Aggregate by sender
    final totals = <String, Map<String, dynamic>>{};
    for (final row in data) {
      final senderId = row['sender_id'] as String;
      final name =
          (row['profiles'] as Map<String, dynamic>?)?['display_name']
              as String? ??
          'Unknown';
      final amount = row['juice_amount'] as int? ?? 0;

      if (totals.containsKey(senderId)) {
        totals[senderId]!['total'] =
            (totals[senderId]!['total'] as int) + amount;
      } else {
        totals[senderId] = {'name': name, 'total': amount};
      }
    }

    final sorted = totals.entries.toList()
      ..sort(
        (a, b) => (b.value['total'] as int).compareTo(a.value['total'] as int),
      );

    return sorted.take(3).map((e) => {'sender_id': e.key, ...e.value}).toList();
  }
}
