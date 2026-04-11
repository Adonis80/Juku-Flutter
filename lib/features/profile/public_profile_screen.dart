import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/supabase_config.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  bool get _isOwnProfile => supabase.auth.currentUser?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profileData = await supabase
        .from('profiles')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();

    bool following = false;
    final user = supabase.auth.currentUser;
    if (user != null && user.id != widget.userId) {
      final followRow = await supabase
          .from('follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', widget.userId)
          .maybeSingle();
      following = followRow != null;
    }

    if (mounted) {
      setState(() {
        _profile = profileData;
        _isFollowing = following;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading || _isOwnProfile) return;
    setState(() => _followLoading = true);

    try {
      if (_isFollowing) {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', supabase.auth.currentUser!.id)
            .eq('following_id', widget.userId);
        if (mounted) setState(() => _isFollowing = false);
      } else {
        await supabase.from('follows').insert({
          'follower_id': supabase.auth.currentUser!.id,
          'following_id': widget.userId,
        });
        if (mounted) setState(() => _isFollowing = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }

    if (mounted) setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (_profile!['username'] as String? ?? '?')[0]
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _profile!['display_name'] as String? ??
                        _profile!['username'] as String? ??
                        'Unknown',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${_profile!['username'] ?? ''}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Follow button (hidden on own profile)
                  if (!_isOwnProfile)
                    SizedBox(
                      width: 160,
                      child: _followLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _isFollowing
                          ? OutlinedButton(
                              onPressed: _toggleFollow,
                              child: const Text('Following'),
                            )
                          : FilledButton(
                              onPressed: _toggleFollow,
                              child: const Text('Follow'),
                            ),
                    ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(label: 'XP', value: '${_profile!['xp'] ?? 0}'),
                      _Stat(
                        label: 'Level',
                        value: '${_profile!['level'] ?? 1}',
                      ),
                      _Stat(
                        label: 'Rank',
                        value:
                            rankLabels[_profile!['rank'] as String? ??
                                'bronze'] ??
                            'Bronze',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_profile!['bio'] != null &&
                      (_profile!['bio'] as String).isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(_profile!['bio'] as String),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}
