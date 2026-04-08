import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _channels = [
  _Channel('de-general', 'German General', 'DE', '🇩🇪'),
  _Channel('de-grammar', 'German Grammar', 'DE', '🇩🇪'),
  _Channel('de-culture', 'German Culture', 'DE', '🇩🇪'),
  _Channel('ru-general', 'Russian General', 'RU', '🇷🇺'),
  _Channel('ru-grammar', 'Russian Grammar', 'RU', '🇷🇺'),
  _Channel('ru-culture', 'Russian Culture', 'RU', '🇷🇺'),
  _Channel('ar-general', 'Arabic General', 'AR', '🇸🇦'),
  _Channel('ar-grammar', 'Arabic Grammar', 'AR', '🇸🇦'),
  _Channel('ar-culture', 'Arabic Culture', 'AR', '🇸🇦'),
  _Channel('zh-general', 'Mandarin General', 'ZH', '🇨🇳'),
  _Channel('zh-grammar', 'Mandarin Grammar', 'ZH', '🇨🇳'),
  _Channel('zh-culture', 'Mandarin Culture', 'ZH', '🇨🇳'),
];

class TopicListScreen extends StatelessWidget {
  const TopicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group by language
    final grouped = <String, List<_Channel>>{};
    for (final ch in _channels) {
      grouped.putIfAbsent(ch.lang, () => []).add(ch);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Topics')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final lang in grouped.keys) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
              child: Text(
                '${grouped[lang]!.first.flag} ${_langName(lang)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...grouped[lang]!.map((ch) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        ch.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(ch.name),
                    subtitle: Text(
                      ch.key,
                      style: TextStyle(
                          fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(
                      '/topics/${ch.key}',
                      extra: {'name': ch.name, 'flag': ch.flag},
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _langName(String code) {
    return switch (code) {
      'DE' => 'German',
      'RU' => 'Russian',
      'AR' => 'Arabic',
      'ZH' => 'Mandarin',
      _ => code,
    };
  }
}

class _Channel {
  const _Channel(this.key, this.name, this.lang, this.flag);
  final String key;
  final String name;
  final String lang;
  final String flag;
}
