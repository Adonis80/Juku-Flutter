import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.partnerId,
    this.partnerName,
  });

  final String partnerId;
  final String? partnerName;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  String get _userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final data = await supabase
        .from('private_messages')
        .select('id, sender_id, receiver_id, content, created_at, read_at')
        .or(
          'and(sender_id.eq.$_userId,receiver_id.eq.${widget.partnerId}),and(sender_id.eq.${widget.partnerId},receiver_id.eq.$_userId)',
        )
        .order('created_at', ascending: true)
        .limit(100);

    if (mounted) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
      _scrollToBottom();
    }

    // Mark received messages as read
    await supabase
        .from('private_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('sender_id', widget.partnerId)
        .eq('receiver_id', _userId)
        .isFilter('read_at', null);
  }

  void _subscribeRealtime() {
    _realtimeSub = supabase
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final relevant = data.where((m) {
            final s = m['sender_id'] as String;
            final r = m['receiver_id'] as String;
            return (s == _userId && r == widget.partnerId) ||
                (s == widget.partnerId && r == _userId);
          }).toList();

          if (mounted && relevant.isNotEmpty) {
            setState(() => _messages = relevant);
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

    setState(() => _sending = true);
    _msgCtrl.clear();

    // Optimistic insert
    final optimistic = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'sender_id': _userId,
      'receiver_id': widget.partnerId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
      'read_at': null,
    };
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    try {
      await supabase.from('private_messages').insert({
        'sender_id': _userId,
        'receiver_id': widget.partnerId,
        'content': text,
      });
    } catch (e) {
      // Remove optimistic message on error
      if (mounted) {
        setState(
          () => _messages.removeWhere((m) => m['id'] == optimistic['id']),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }

    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.partnerName ?? 'Chat')),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'Say hello!',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _userId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            msg['content'] as String? ?? '',
                            style: TextStyle(
                              color: isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
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
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
