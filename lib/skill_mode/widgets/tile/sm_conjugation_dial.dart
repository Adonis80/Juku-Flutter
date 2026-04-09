import 'package:flutter/material.dart';

/// Conjugation tumbler dial for inflected tiles.
/// Full implementation in SM-2.2.
class SmConjugationDial extends StatelessWidget {
  final List<String> forms;
  final int correctIndex;
  final ValueChanged<int>? onLocked;

  const SmConjugationDial({
    super.key,
    required this.forms,
    required this.correctIndex,
    this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Stub — implemented in SM-2.2
  }
}
