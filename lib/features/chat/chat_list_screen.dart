import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Fetch all private messages involving the user, grouped by conversation partner
    final sent = await supabase
        .from('private_messages')
        .select('receiver_id, content, created_at, read_at')
        .eq('sender_id', user.id)
        .order('created_at', ascending: false);

    final received = await supabase
        .from('private_messages')
        .select('sender_id, content, created_at, read_at')
        .eq('receiver_id', user.id)
        .order('created_at', ascending: false);

    // Build conversation map: partner_id -> latest message
    final Map<String, Map<String, dynamic>> convos = {};

    for (final msg in List<Map<String, dynamic>>.from(sent)) {
      final partnerId = msg['receiver_id'] as String;
      if (!convos.containsKey(partnerId)) {
        convos[partnerId] = {
          'partner_id': partnerId,
          'last_message': msg['content'],
          'last_at': msg['created_at'],
          'unread': false,
        };
      }
    }

    for (final msg in List<Map<String, dynamic>>.from(received)) {
      final partnerId = msg['sender_id'] as String;
      final existing = convos[partnerId];
      final msgTime = DateTime.parse(msg['created_at'] as String);

      if (existing == null ||
          msgTime.isAfter(DateTime.parse(existing['last_at'] as String))) {
        convos[partnerId] = {
          'partner_id': partnerId,
          'last_message': msg['content'],
          'last_at': msg['created_at'],
          'unread': msg['read_at'] == null,
        };
      } else if (msg['read_at'] == null && existing['unread'] == false) {
        existing['unread'] = true;
      }
    }

    // Fetch profile info for partners
    final partnerIds = convos.keys.toList();
    if (partnerIds.isNotEmpty) {
      final profiles = await supabase
          .from('profiles')
          .select('id, username, display_name, photo_url')
          .inFilter('id', partnerIds);

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in List<Map<String, dynamic>>.from(profiles)) {
        profileMap[p['id'] as String] = p;
      }

      for (final convo in convos.values) {
        convo['profile'] = profileMap[convo['partner_id']];
      }
    }

    // Sort by recency
    final sorted = convos.values.toList()
      ..sort(
        (a, b) => (b['last_at'] as String).compareTo(a['last_at'] as String),
      );

    if (mounted) {
      setState(() {
        _conversations = sorted;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow someone and they follow you back to start chatting',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _conversations.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final convo = _conversations[index];
                  final profile = convo['profile'] as Map<String, dynamic>?;
                  final username = profile?['username'] as String? ?? 'unknown';
                  final displayName =
                      profile?['display_name'] as String? ?? username;
                  final unread = convo['unread'] as bool? ?? false;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        username[0].toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: unread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      convo['last_message'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: unread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: unread
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                    onTap: () {
                      context.push(
                        '/chat/${convo['partner_id']}',
                        extra: {
                          'username': username,
                          'displayName': displayName,
                        },
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
