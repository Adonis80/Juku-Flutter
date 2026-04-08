import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';

class TopicChannelScreen extends StatefulWidget {
  const TopicChannelScreen({
    super.key,
    required this.topicKey,
    this.channelName,
  });

  final String topicKey;
  final String? channelName;

  @override
  State<TopicChannelScreen> createState() => _TopicChannelScreenState();
}

class _TopicChannelScreenState extends State<TopicChannelScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribe();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final data = await supabase
        .from('topic_messages')
        .select(
            'id, content, upvotes, created_at, user_id, profiles!topic_messages_user_id_fkey(username)')
        .eq('topic_key', widget.topicKey)
        .order('created_at', ascending: true)
        .limit(100);

    if (mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _subscribe() {
    _sub = supabase
        .from('topic_messages')
        .stream(primaryKey: ['id'])
        .eq('topic_key', widget.topicKey)
        .listen((data) {
      if (mounted) {
        setState(() => _messages = List<Map<String, dynamic>>.from(data));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await supabase.from('topic_messages').insert({
        'topic_key': widget.topicKey,
        'user_id': user.id,
        'content': text,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _toggleVote(String messageId) async {
    try {
      await supabase.rpc('toggle_topic_message_vote',
          params: {'p_message_id': messageId});
      // Realtime will update the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vote failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName ?? widget.topicKey),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet — start the discussion!',
                          style:
                              TextStyle(color: theme.colorScheme.outline),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final author = msg['profiles']
                              as Map<String, dynamic>?;
                          final isOwn = msg['user_id'] == userId;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '@${author?['username'] ?? 'unknown'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isOwn
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                      const Spacer(),
                                      // Upvote button
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        onTap: () => _toggleVote(
                                            msg['id'] as String),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons
                                                    .arrow_upward_rounded,
                                                size: 16,
                                                color: theme
                                                    .colorScheme.primary,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${msg['upvotes'] ?? 0}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    msg['content'] as String? ?? '',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Join the discussion...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
