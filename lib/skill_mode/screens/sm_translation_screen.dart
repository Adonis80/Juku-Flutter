import 'package:flutter/material.dart';

/// Community translations for lyrics.
/// Full implementation in v0.5.
class SmTranslationScreen extends StatelessWidget {
  const SmTranslationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translations')),
      body: const Center(child: Text('Translations — coming in v0.5')),
    );
  }
}
