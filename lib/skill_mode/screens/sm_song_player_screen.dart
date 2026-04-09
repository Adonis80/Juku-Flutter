import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import '../models/sm_song.dart';

/// Song player with karaoke lyrics (SM-5.3).
///
/// Scrolling lyrics highlight current line. Tap any line to puzzle.
class SmSongPlayerScreen extends ConsumerStatefulWidget {
  final String songId;
  const SmSongPlayerScreen({super.key, required this.songId});

  @override
  ConsumerState<SmSongPlayerScreen> createState() =>
      _SmSongPlayerScreenState();
}

class _SmSongPlayerScreenState extends ConsumerState<SmSongPlayerScreen> {
  SmSong? _song;
  bool _loading = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final _player = AudioPlayer();
  final _scrollController = ScrollController();

  // Lyrics with timestamps.
  List<_LyricLine> _lyrics = [];
  int _currentLineIndex = -1;

  // Audio source toggle (full mix / vocals / accompaniment).
  String _audioSource = 'full'; // 'full' | 'vocals' | 'accompaniment'

  @override
  void initState() {
    super.initState();
    _loadSong();
    _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
        _updateCurrentLine();
      }
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSong() async {
    try {
      final data = await supabase
          .from('skill_mode_songs')
          .select()
          .eq('id', widget.songId)
          .single();

      final song = SmSong.fromJson(data);

      // Load lyrics.
      final lyricsData = await supabase
          .from('skill_mode_lyrics')
          .select()
          .eq('song_id', widget.songId)
          .order('timestamp_ms');

      _lyrics = (lyricsData as List).map((l) {
        return _LyricLine(
          text: l['text'] as String? ?? '',
          translation: l['translation'] as String?,
          timestampMs: l['timestamp_ms'] as int? ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _song = song;
          _loading = false;
        });

        // Start playback.
        if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
          await _player.play(UrlSource(song.audioUrl!));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateCurrentLine() {
    final posMs = _position.inMilliseconds;
    int newIndex = -1;
    for (var i = _lyrics.length - 1; i >= 0; i--) {
      if (posMs >= _lyrics[i].timestampMs) {
        newIndex = i;
        break;
      }
    }
    if (newIndex != _currentLineIndex) {
      setState(() => _currentLineIndex = newIndex);
      _scrollToLine(newIndex);
    }
  }

  void _scrollToLine(int index) {
    if (index >= 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * 60.0 - 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.resume();
    }
  }

  void _seek(double value) {
    _player.seek(Duration(
      milliseconds: (value * _duration.inMilliseconds).round(),
    ));
  }

  void _onLineTapped(int index) {
    // Pause and show puzzle for this line.
    _player.pause();
    // TODO(SM-5.4): Launch tile puzzle for this lyric line.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Puzzle: "${_lyrics[index].text}"')),
    );
  }

  void _switchAudioSource(String source) {
    setState(() => _audioSource = source);
    final song = _song;
    if (song == null) return;

    final url = switch (source) {
      'vocals' => song.vocalsUrl,
      'accompaniment' => song.instrumentalUrl,
      _ => song.audioUrl,
    };

    if (url != null && url.isNotEmpty) {
      final currentPos = _position;
      _player.play(UrlSource(url));
      _player.seek(currentPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final song = _song;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: Text('Song not found')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Hero header with cover art.
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      song.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Audio source toggle (if stems available).
          if (song.vocalsUrl != null || song.instrumentalUrl != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<String>(
                segments: [
                  const ButtonSegment(value: 'full', label: Text('Full')),
                  if (song.vocalsUrl != null)
                    const ButtonSegment(
                        value: 'vocals', label: Text('Vocals')),
                  if (song.instrumentalUrl != null)
                    const ButtonSegment(
                        value: 'accompaniment', label: Text('Music')),
                ],
                selected: {_audioSource},
                onSelectionChanged: (v) => _switchAudioSource(v.first),
              ),
            ),

          // Lyrics.
          Expanded(
            child: _lyrics.isEmpty
                ? Center(
                    child: Text(
                      'No lyrics synced yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _lyrics.length,
                    itemBuilder: (_, i) {
                      final line = _lyrics[i];
                      final isCurrent = i == _currentLineIndex;
                      final isPast = i < _currentLineIndex;

                      return GestureDetector(
                        onTap: () => _onLineTapped(i),
                        onLongPress: () {
                          context.push(
                            '/skill-mode/translations?songId=${widget.songId}'
                            '&lineIndex=$i'
                            '&sourceText=${Uri.encodeComponent(line.text)}',
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.text,
                                style: TextStyle(
                                  fontSize: isCurrent ? 20 : 16,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isCurrent
                                      ? theme.colorScheme.primary
                                      : isPast
                                          ? theme.colorScheme.onSurface
                                              .withAlpha(100)
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                              if (line.translation != null)
                                Text(
                                  line.translation!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withAlpha(isCurrent ? 200 : 100),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Controls.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Seek bar.
                Slider(
                  value: _duration.inMilliseconds > 0
                      ? (_position.inMilliseconds /
                              _duration.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  onChanged: _seek,
                ),
                // Time labels.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: theme.textTheme.labelSmall,
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Play/pause.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        _player.seek(Duration(
                          milliseconds:
                              (_position.inMilliseconds - 10000).clamp(0, _duration.inMilliseconds),
                        ));
                      },
                    ),
                    IconButton.filled(
                      iconSize: 48,
                      icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        _player.seek(Duration(
                          milliseconds:
                              (_position.inMilliseconds + 10000).clamp(0, _duration.inMilliseconds),
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _LyricLine {
  final String text;
  final String? translation;
  final int timestampMs;

  const _LyricLine({
    required this.text,
    this.translation,
    required this.timestampMs,
  });
}
