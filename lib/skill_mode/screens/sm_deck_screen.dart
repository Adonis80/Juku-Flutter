import 'package:flutter/material.dart';

/// Card queue screen for a Skill Mode session.
/// Full implementation in SM-1.6.
class SmDeckScreen extends StatelessWidget {
  const SmDeckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: const Center(
        child: Text('Deck screen — coming in SM-1'),
      ),
    );
  }
}
