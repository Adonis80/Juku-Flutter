import 'package:flutter/material.dart';

/// Suspended cards vault.
/// Full implementation in SM-3.
class SmVaultScreen extends StatelessWidget {
  const SmVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: const Center(child: Text('Card vault — coming in SM-3')),
    );
  }
}
