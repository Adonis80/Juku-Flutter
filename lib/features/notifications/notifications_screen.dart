import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    if (mounted) {
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', user.id)
        .eq('read', false);

    if (mounted) {
      setState(() {
        for (final n in _notifications) {
          n['read'] = true;
        }
      });
    }
  }

  Future<void> _markRead(String id) async {
    await supabase.from('notifications').update({'read': true}).eq('id', id);

    if (mounted) {
      setState(() {
        final n = _notifications.firstWhere(
          (n) => n['id'] == id,
          orElse: () => {},
        );
        if (n.isNotEmpty) n['read'] = true;
      });
    }
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'vote' => Icons.arrow_upward_rounded,
      'follow' => Icons.person_add_rounded,
      'message' => Icons.chat_bubble_rounded,
      'level_up' => Icons.trending_up_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _colorForType(String type, ThemeData theme) {
    return switch (type) {
      'vote' => theme.colorScheme.primary,
      'follow' => Colors.blue,
      'message' => Colors.green,
      'level_up' => Colors.orange,
      _ => theme.colorScheme.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => n['read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  final isRead = n['read'] as bool? ?? false;
                  final type = n['type'] as String? ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _colorForType(
                        type,
                        theme,
                      ).withValues(alpha: 0.12),
                      child: Icon(
                        _iconForType(type),
                        color: _colorForType(type, theme),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      n['title'] as String? ?? '',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: n['body'] != null
                        ? Text(
                            n['body'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          )
                        : null,
                    trailing: !isRead
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                    onTap: () {
                      if (!isRead) _markRead(n['id'] as String);
                      final link = n['link'] as String?;
                      if (link != null && link.isNotEmpty) {
                        context.push(link);
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}

/// Badge widget to show unread notification count in AppBar
class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('read', false);

    if (mounted) {
      setState(() => _unreadCount = (data as List).length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Badge(
        isLabelVisible: _unreadCount > 0,
        label: Text('$_unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => context.push('/notifications'),
    );
  }
}
