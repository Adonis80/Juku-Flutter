import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../auth/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  // Edit controllers
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();

  // Notification prefs
  bool _notifVotes = true;
  bool _notifFollows = true;
  bool _notifMessages = true;
  bool _notifLevelUps = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _photoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (mounted && data != null) {
      setState(() {
        _profile = data;
        _displayNameCtrl.text = data['display_name'] as String? ?? '';
        _bioCtrl.text = data['bio'] as String? ?? '';
        _photoUrlCtrl.text = data['photo_url'] as String? ?? '';

        // Parse notification prefs from jsonb
        final prefs =
            data['notification_prefs'] as Map<String, dynamic>? ?? {};
        _notifVotes = prefs['vote'] as bool? ?? true;
        _notifFollows = prefs['follow'] as bool? ?? true;
        _notifMessages = prefs['message'] as bool? ?? true;
        _notifLevelUps = prefs['level_up'] as bool? ?? true;

        _loading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').update({
        'display_name': _displayNameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'photo_url': _photoUrlCtrl.text.trim().isEmpty
            ? null
            : _photoUrlCtrl.text.trim(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveNotifPrefs() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('profiles').update({
        'notification_prefs': {
          'vote': _notifVotes,
          'follow': _notifFollows,
          'message': _notifMessages,
          'level_up': _notifLevelUps,
        },
      }).eq('id', user.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account info
                  Text('Account',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user?.email ?? 'Not set'}'),
                          const SizedBox(height: 4),
                          Text(
                              'Username: @${_profile?['username'] ?? 'unknown'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Edit profile
                  Text('Edit Profile',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _displayNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Display Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _photoUrlCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Photo URL'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                  const SizedBox(height: 24),

                  // Notification preferences
                  Text('Notifications',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Votes on your lessons'),
                    value: _notifVotes,
                    onChanged: (v) {
                      setState(() => _notifVotes = v);
                      _saveNotifPrefs();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('New followers'),
                    value: _notifFollows,
                    onChanged: (v) {
                      setState(() => _notifFollows = v);
                      _saveNotifPrefs();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Messages'),
                    value: _notifMessages,
                    onChanged: (v) {
                      setState(() => _notifMessages = v);
                      _saveNotifPrefs();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Level ups'),
                    value: _notifLevelUps,
                    onChanged: (v) {
                      setState(() => _notifLevelUps = v);
                      _saveNotifPrefs();
                    },
                  ),
                  const SizedBox(height: 24),

                  // Quick links
                  Text('More',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.bookmark_border),
                          title: const Text('Saved Lessons'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/bookmarks'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text('Invite Friends'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/invite'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.card_giftcard),
                          title: const Text('Refer & Earn'),
                          subtitle: const Text('Get 50 Juice per referral'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/referral'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.shield_outlined),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/privacy'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Terms of Service'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/terms'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
