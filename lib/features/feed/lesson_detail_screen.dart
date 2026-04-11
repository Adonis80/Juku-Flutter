import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/supabase_config.dart';
import '../bookmarks/bookmarks_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Map<String, dynamic>? _lesson;
  String? _userVote; // 'up', 'down', or null
  bool _loading = true;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('lessons')
        .select(
          'id, title, content, example, topic, subtopic, domain, language_pair, score, upvote_count, downvote_count, created_at, author_id, profiles!lessons_author_id_fkey(username, display_name, level, rank, photo_url)',
        )
        .eq('id', widget.lessonId)
        .maybeSingle();

    String? vote;
    if (user != null && data != null) {
      final voteRow = await supabase
          .from('lesson_votes')
          .select('vote_type')
          .eq('lesson_id', widget.lessonId)
          .eq('user_id', user.id)
          .maybeSingle();
      vote = voteRow?['vote_type'] as String?;
    }

    if (mounted) {
      setState(() {
        _lesson = data;
        _userVote = vote;
        _loading = false;
      });
    }
  }

  Future<void> _castVote(String voteType) async {
    if (_voting || _lesson == null) return;
    setState(() => _voting = true);

    // Optimistic update
    final oldVote = _userVote;
    final oldScore = _lesson!['score'] as int;
    final oldUp = _lesson!['upvote_count'] as int;
    final oldDown = _lesson!['downvote_count'] as int;

    int newUp = oldUp;
    int newDown = oldDown;

    if (oldVote == voteType) {
      // Toggle off
      if (voteType == 'up') newUp--;
      if (voteType == 'down') newDown--;
      setState(() {
        _userVote = null;
        _lesson!['upvote_count'] = newUp;
        _lesson!['downvote_count'] = newDown;
        _lesson!['score'] = newUp - newDown;
      });
    } else {
      // New vote or switch
      if (oldVote == 'up') newUp--;
      if (oldVote == 'down') newDown--;
      if (voteType == 'up') newUp++;
      if (voteType == 'down') newDown++;
      setState(() {
        _userVote = voteType;
        _lesson!['upvote_count'] = newUp;
        _lesson!['downvote_count'] = newDown;
        _lesson!['score'] = newUp - newDown;
      });
    }

    try {
      final result = await supabase.rpc(
        'cast_lesson_vote',
        params: {'p_lesson_id': widget.lessonId, 'p_vote_type': voteType},
      );

      if (mounted && result is List && result.isNotEmpty) {
        final row = result[0] as Map<String, dynamic>;
        setState(() {
          _lesson!['score'] = row['new_score'];
          _lesson!['upvote_count'] = row['new_upvote_count'];
          _lesson!['downvote_count'] = row['new_downvote_count'];
          _userVote = row['user_vote'] as String?;
        });
      }
    } catch (_) {
      // Rollback on error
      if (mounted) {
        setState(() {
          _userVote = oldVote;
          _lesson!['score'] = oldScore;
          _lesson!['upvote_count'] = oldUp;
          _lesson!['downvote_count'] = oldDown;
        });
      }
    }

    if (mounted) setState(() => _voting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        actions: [BookmarkButton(lessonId: widget.lessonId)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lesson == null
          ? const Center(child: Text('Lesson not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _Badge(
                        label: _lesson!['topic'] as String? ?? '',
                        color: theme.colorScheme.primaryContainer,
                        textColor: theme.colorScheme.onPrimaryContainer,
                      ),
                      if (_lesson!['language_pair'] != null)
                        _Badge(
                          label: _lesson!['language_pair'] as String,
                          color: theme.colorScheme.secondaryContainer,
                          textColor: theme.colorScheme.onSecondaryContainer,
                        ),
                      if (_lesson!['subtopic'] != null)
                        _Badge(
                          label: _lesson!['subtopic'] as String,
                          color: theme.colorScheme.tertiaryContainer,
                          textColor: theme.colorScheme.onTertiaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    _lesson!['title'] as String? ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),

                  // Content
                  Text(
                    _lesson!['content'] as String? ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),

                  // Example
                  if (_lesson!['example'] != null &&
                      (_lesson!['example'] as String).isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Example',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lesson!['example'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Vote buttons
                  _VoteBar(
                    score: _lesson!['score'] as int? ?? 0,
                    upvotes: _lesson!['upvote_count'] as int? ?? 0,
                    userVote: _userVote,
                    onVote: _castVote,
                  ),
                  const SizedBox(height: 20),

                  // Author card
                  _AuthorCard(
                    author: _lesson!['profiles'] as Map<String, dynamic>? ?? {},
                  ),
                ],
              ),
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  const _VoteBar({
    required this.score,
    required this.upvotes,
    required this.userVote,
    required this.onVote,
  });

  final int score;
  final int upvotes;
  final String? userVote;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Upvote
        _VoteButton(
          icon: Icons.arrow_upward_rounded,
          active: userVote == 'up',
          activeColor: theme.colorScheme.primary,
          onTap: () => onVote('up'),
        ),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Downvote
        _VoteButton(
          icon: Icons.arrow_downward_rounded,
          active: userVote == 'down',
          activeColor: theme.colorScheme.error,
          onTap: () => onVote('down'),
        ),
        const Spacer(),
        Icon(Icons.arrow_upward, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '$upvotes',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: active ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: active ? activeColor : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.author});

  final Map<String, dynamic> author;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = author['username'] as String? ?? 'unknown';
    final displayName = author['display_name'] as String? ?? username;
    final level = author['level'] as int? ?? 1;
    final rank = author['rank'] as String? ?? 'bronze';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                username[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '@$username · Level $level · ${rank[0].toUpperCase()}${rank.substring(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
