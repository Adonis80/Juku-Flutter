import 'package:flutter/material.dart';

/// Mic + waveform + pronunciation scoring.
/// Full implementation in SM-4.
class SmPronunciationScreen extends StatelessWidget {
  const SmPronunciationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pronunciation')),
      body: const Center(
        child: Text('Pronunciation — coming in SM-4'),
      ),
    );
  }
}
