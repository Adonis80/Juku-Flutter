import 'package:flutter/material.dart';

/// Single card view with three-press interaction.
/// Full implementation in SM-1.6.
class SmCardScreen extends StatelessWidget {
  final String cardId;
  const SmCardScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: Center(
        child: Text('Card $cardId — coming in SM-1'),
      ),
    );
  }
}
