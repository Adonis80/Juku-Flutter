import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  List<Map<String, dynamic>> _circles = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Fetch circles the user is a member of
    final memberData = await supabase
        .from('circle_members')
        .select('circle_id, status, circles(id, name, owner_id, created_at)')
        .eq('user_id', user.id);

    final members = List<Map<String, dynamic>>.from(memberData);
    final circles = <Map<String, dynamic>>[];
    final invites = <Map<String, dynamic>>[];

    for (final m in members) {
      final circle = m['circles'] as Map<String, dynamic>?;
      if (circle == null) continue;
      if (m['status'] == 'invited') {
        invites.add({...circle, 'member_id': m['circle_id']});
      } else {
        circles.add(circle);
      }
    }

    if (mounted) {
      setState(() {
        _circles = circles;
        _invitations = invites;
        _loading = false;
      });
    }
  }

  Future<void> _createCircle() async {
    final nameCtrl = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Circle'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Circle Name',
            hintText: 'e.g. German Study Squad',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();

    if (name == null || name.isEmpty) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final circle = await supabase
          .from('circles')
          .insert({'name': name, 'owner_id': user.id})
          .select()
          .single();

      // Add owner as member
      await supabase.from('circle_members').insert({
        'circle_id': circle['id'],
        'user_id': user.id,
        'status': 'active',
      });

      if (mounted) {
        setState(() => _circles.insert(0, circle));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Circle "$name" created!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _acceptInvite(Map<String, dynamic> circle) async {
    try {
      await supabase
          .from('circle_members')
          .update({'status': 'active'})
          .eq('circle_id', circle['id'])
          .eq('user_id', supabase.auth.currentUser!.id);

      if (mounted) {
        setState(() {
          _invitations.removeWhere((c) => c['id'] == circle['id']);
          _circles.insert(0, circle);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _declineInvite(Map<String, dynamic> circle) async {
    try {
      await supabase
          .from('circle_members')
          .delete()
          .eq('circle_id', circle['id'])
          .eq('user_id', supabase.auth.currentUser!.id);

      if (mounted) {
        setState(() {
          _invitations.removeWhere((c) => c['id'] == circle['id']);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Circles')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCircle,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_circles.isEmpty && _invitations.isEmpty)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No circles yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a circle to learn with up to 5 friends',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // Invitations
                  if (_invitations.isNotEmpty) ...[
                    Text(
                      'Invitations',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._invitations.map(
                      (c) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.tertiaryContainer,
                            child: const Icon(Icons.mail),
                          ),
                          title: Text(c['name'] as String? ?? 'Circle'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                onPressed: () => _acceptInvite(c),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => _declineInvite(c),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Circles
                  if (_circles.isNotEmpty) ...[
                    Text(
                      'Your Circles',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._circles.map(
                      (c) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              (c['name'] as String? ?? '?')[0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(c['name'] as String? ?? 'Circle'),
                          subtitle: const Text('Max 5 members'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/circles/${c['id']}'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
