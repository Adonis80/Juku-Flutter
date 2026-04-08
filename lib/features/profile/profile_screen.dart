import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';
import '../auth/auth_state.dart';
import '../gamification/jukumon_widget.dart';
import '../gamification/level_bar.dart';
import '../gamification/streak_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _profile = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profile not found'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar
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

                        // Display name
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
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Level bar
                        LevelBar(
                          xp: _profile!['xp'] as int? ?? 0,
                          level: _profile!['level'] as int? ?? 1,
                          rank: _profile!['rank'] as String? ?? 'bronze',
                        ),
                        const SizedBox(height: 8),

                        // Streak card
                        StreakCard(
                          current:
                              _profile!['streak_current'] as int? ?? 0,
                          best: _profile!['streak_best'] as int? ?? 0,
                        ),
                        const SizedBox(height: 8),

                        // Jukumon companion
                        JukumonWidget(
                          level: _profile!['level'] as int? ?? 1,
                          rank: _profile!['rank'] as String? ?? 'bronze',
                        ),
                        const SizedBox(height: 16),

                        // Bio
                        if (_profile!['bio'] != null &&
                            (_profile!['bio'] as String).isNotEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _profile!['bio'] as String,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
