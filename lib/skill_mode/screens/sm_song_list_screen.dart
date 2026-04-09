import 'package:flutter/material.dart';

/// Browse songs for Music Mode.
/// Full implementation in v0.4.
class SmSongListScreen extends StatelessWidget {
  const SmSongListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: const Center(child: Text('Music Mode — coming in v0.4')),
    );
  }
}
