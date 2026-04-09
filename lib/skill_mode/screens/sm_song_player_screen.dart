import 'package:flutter/material.dart';

/// Karaoke song player.
/// Full implementation in v0.4.
class SmSongPlayerScreen extends StatelessWidget {
  final String songId;
  const SmSongPlayerScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: Center(child: Text('Song $songId — coming in v0.4')),
    );
  }
}
