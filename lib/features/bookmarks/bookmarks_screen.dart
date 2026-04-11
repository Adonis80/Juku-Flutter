import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
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
        .from('bookmarks')
        .select(
          'id, lesson_id, created_at, lessons(id, title, topic, language_pair, score, profiles!lessons_author_id_fkey(username))',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _bookmarks = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    }
  }

  Future<void> _removeBookmark(String bookmarkId, int index) async {
    final removed = _bookmarks[index];
    setState(() => _bookmarks.removeAt(index));

    try {
      await supabase.from('bookmarks').delete().eq('id', bookmarkId);
    } catch (_) {
      if (mounted) {
        setState(() => _bookmarks.insert(index, removed));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Lessons')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved lessons yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark lessons from the feed to save them here',
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
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _bookmarks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final bm = _bookmarks[index];
                  final lesson = bm['lessons'] as Map<String, dynamic>? ?? {};
                  final author = lesson['profiles'] as Map<String, dynamic>?;

                  return Dismissible(
                    key: ValueKey(bm['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: theme.colorScheme.error,
                      child: Icon(
                        Icons.delete,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                    onDismissed: (_) =>
                        _removeBookmark(bm['id'] as String, index),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          lesson['title'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
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
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          '${lesson['score'] ?? 0}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        onTap: () => context.push('/lesson/${lesson['id']}'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Bookmark toggle button for lesson detail screen
class BookmarkButton extends StatefulWidget {
  const BookmarkButton({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<BookmarkButton> {
  bool _bookmarked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', user.id)
        .eq('lesson_id', widget.lessonId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _bookmarked = data != null;
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _bookmarked = !_bookmarked);

    try {
      if (_bookmarked) {
        await supabase.from('bookmarks').insert({
          'user_id': user.id,
          'lesson_id': widget.lessonId,
        });
      } else {
        await supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('lesson_id', widget.lessonId);
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarked = !_bookmarked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(width: 24, height: 24);

    return IconButton(
      icon: Icon(
        _bookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: _bookmarked ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: _toggle,
    );
  }
}
