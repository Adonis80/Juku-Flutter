import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../models/sm_song.dart';

/// Song list / discovery screen (SM-5.6).
///
/// Browse songs by language, search, most played, recently added.
class SmSongListScreen extends ConsumerStatefulWidget {
  const SmSongListScreen({super.key});

  @override
  ConsumerState<SmSongListScreen> createState() => _SmSongListScreenState();
}

class _SmSongListScreenState extends ConsumerState<SmSongListScreen> {
  List<SmSong> _songs = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final data = await supabase
          .from('skill_mode_songs')
          .select()
          .order('play_count', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _songs =
              (data as List).map((e) => SmSong.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Mode'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/skill-mode/songs/upload'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar.
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                // Song list.
                Expanded(
                  child: _songs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.music_note,
                                  size: 48, color: theme.colorScheme.outline),
                              const SizedBox(height: 8),
                              Text(
                                'No songs yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.push('/skill-mode/songs/upload'),
                                icon: const Icon(Icons.upload),
                                label: const Text('Upload First Song'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredSongs.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (_, i) {
                            final song = _filteredSongs[i];
                            return _buildSongCard(song, theme);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<SmSong> get _filteredSongs {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _songs;
    return _songs
        .where((s) =>
            s.title.toLowerCase().contains(query) ||
            s.artist.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildSongCard(SmSong song, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/skill-mode/songs/${song.id}'),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.music_note),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${song.artist} • ${song.language.toUpperCase()} • ${song.playCount} plays',
        ),
        trailing: const Icon(Icons.play_arrow),
      ),
    );
  }
}
