import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        _search(query.trim());
      } else {
        setState(() {
          _lessons = [];
          _profiles = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);

    final lessonsFuture = supabase
        .from('lessons')
        .select(
            'id, title, topic, language_pair, score, profiles!lessons_author_id_fkey(username)')
        .or('title.ilike.%$query%,content.ilike.%$query%')
        .eq('hidden', false)
        .order('score', ascending: false)
        .limit(15);

    final profilesFuture = supabase
        .from('profiles')
        .select('id, username, display_name, level, rank, photo_url')
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(10);

    final results = await Future.wait([lessonsFuture, profilesFuture]);

    if (mounted) {
      setState(() {
        _lessons = List<Map<String, dynamic>>.from(results[0] as List);
        _profiles = List<Map<String, dynamic>>.from(results[1] as List);
        _loading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: false,
          decoration: InputDecoration(
            hintText: 'Search lessons & users...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onChanged: _onSearchChanged,
        ),
        toolbarHeight: 64,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? _BuildSuggestions()
              : (_lessons.isEmpty && _profiles.isEmpty)
                  ? Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        // Profiles section
                        if (_profiles.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Users',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._profiles.map((p) => _ProfileTile(profile: p)),
                          const SizedBox(height: 16),
                        ],

                        // Lessons section
                        if (_lessons.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Lessons',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._lessons.map((l) => _LessonTile(lesson: l)),
                        ],
                      ],
                    ),
    );
  }
}

class _BuildSuggestions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Explore Juku',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for lessons, topics, or users',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = profile['username'] as String? ?? 'unknown';
    final displayName = profile['display_name'] as String? ?? username;
    final level = profile['level'] as int? ?? 1;
    final rank = profile['rank'] as String? ?? 'bronze';

    return Card(
      child: ListTile(
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
        title: Text(displayName),
        subtitle: Text(
          '@$username · Level $level · ${rank[0].toUpperCase()}${rank.substring(1)}',
          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
        ),
        onTap: () => context.push('/profile/${profile['id']}'),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final Map<String, dynamic> lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = lesson['profiles'] as Map<String, dynamic>?;

    return Card(
      child: ListTile(
        title: Text(
          lesson['title'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lesson['topic'] as String? ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '@${author?['username'] ?? 'unknown'}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 2),
            Text(
              '${lesson['score'] ?? 0}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () => context.push('/lesson/${lesson['id']}'),
      ),
    );
  }
}
