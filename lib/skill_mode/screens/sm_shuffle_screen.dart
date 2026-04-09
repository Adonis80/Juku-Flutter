import 'package:flutter/material.dart';

/// Shuffle puzzle — drag tiles to correct word order.
/// Full implementation in SM-2.1.
class SmShuffleScreen extends StatelessWidget {
  final String cardId;
  const SmShuffleScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shuffle')),
      body: Center(
        child: Text('Shuffle puzzle $cardId — coming in SM-2'),
      ),
    );
  }
}
