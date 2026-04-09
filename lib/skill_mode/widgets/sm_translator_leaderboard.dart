import 'package:flutter/material.dart';

import '../models/sm_translation.dart';
import '../services/sm_translation_service.dart';

/// Translator leaderboard widget — shows top translators by trust score (SM-6).
class SmTranslatorLeaderboard extends StatefulWidget {
  const SmTranslatorLeaderboard({super.key});

  @override
  State<SmTranslatorLeaderboard> createState() =>
      _SmTranslatorLeaderboardState();
}

class _SmTranslatorLeaderboardState extends State<SmTranslatorLeaderboard> {
  final _service = SmTranslationService();
  List<SmTranslatorStats> _translators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getTopTranslators(limit: 10);
      if (mounted) setState(() { _translators = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_translators.isEmpty) {
      return Center(
        child: Text(
          'No translators yet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Top Translators',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...List.generate(_translators.length, (i) {
          final t = _translators[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: i < 3
                  ? [Colors.amber, Colors.grey.shade400, Colors.brown][i]
                  : cs.surfaceContainerHighest,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: i < 3 ? Colors.white : cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text('${t.tierEmoji} ${t.tierLabel}'),
            subtitle: Text(
              '${t.verifiedCount} verified \u{2022} ${t.totalSubmissions} total',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                t.trustScore.toStringAsFixed(1),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
