import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_state.dart';
import '../services/sm_conversation_service.dart';
import '../state/sm_conversation_state.dart';

/// API key management screen for BYOK (GL-3).
///
/// Users enter their own OpenAI (Whisper), Anthropic (Claude),
/// and ElevenLabs (TTS) API keys.
class SmApiKeysScreen extends ConsumerStatefulWidget {
  const SmApiKeysScreen({super.key});

  @override
  ConsumerState<SmApiKeysScreen> createState() => _SmApiKeysScreenState();
}

class _SmApiKeysScreenState extends ConsumerState<SmApiKeysScreen> {
  final _service = SmConversationService.instance;

  static const _providers = [
    (
      id: 'openai',
      name: 'OpenAI',
      description: 'Used for Whisper speech-to-text transcription',
      icon: Icons.hearing,
    ),
    (
      id: 'anthropic',
      name: 'Anthropic',
      description: 'Used for Claude AI conversation responses',
      icon: Icons.smart_toy,
    ),
    (
      id: 'elevenlabs',
      name: 'ElevenLabs',
      description: 'Used for text-to-speech synthesis',
      icon: Icons.record_voice_over,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keysAsync = ref.watch(aiApiKeysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Keys'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: keysAsync.when(
        data: (keys) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info card.
              Card(
                color: theme.colorScheme.primaryContainer.withAlpha(40),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Conversation uses your own API keys (BYOK). '
                          'Keys are stored securely and only used for your conversations.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Provider cards.
              ..._providers.map((p) {
                final existing = keys.where((k) => k.provider == p.id);
                final hasKey = existing.isNotEmpty;
                final isValid = hasKey ? existing.first.isValid : false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hasKey
                          ? (isValid
                                ? const Color(0xFF10B981).withAlpha(25)
                                : const Color(0xFFEF4444).withAlpha(25))
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        p.icon,
                        color: hasKey
                            ? (isValid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      hasKey
                          ? (isValid ? 'Active' : 'Invalid — update key')
                          : p.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasKey && !isValid
                            ? const Color(0xFFEF4444)
                            : null,
                      ),
                    ),
                    trailing: hasKey
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () =>
                                    _showKeyDialog(p.id, p.name, update: true),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Color(0xFFEF4444),
                                ),
                                onPressed: () => _deleteKey(p.id),
                              ),
                            ],
                          )
                        : FilledButton.tonal(
                            onPressed: () => _showKeyDialog(p.id, p.name),
                            child: const Text('Add'),
                          ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showKeyDialog(String provider, String name, {bool update = false}) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(update ? 'Update $name Key' : 'Add $name Key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: 'sk-...',
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) return;

              final user = ref.read(currentUserProvider);
              if (user == null) return;

              await _service.saveApiKey(
                userId: user.id,
                provider: provider,
                apiKey: key,
              );

              ref.invalidate(aiApiKeysProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteKey(String provider) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _service.deleteApiKey(userId: user.id, provider: provider);
    ref.invalidate(aiApiKeysProvider);
  }
}
