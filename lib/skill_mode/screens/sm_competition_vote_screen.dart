import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sm_competition.dart';
import '../state/sm_competition_notifier.dart';

/// Vote on competition entries — star rating per entry.
class SmCompetitionVoteScreen extends ConsumerWidget {
  final String competitionId;
  const SmCompetitionVoteScreen({super.key, required this.competitionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(smCompetitionDetailProvider(competitionId));
    final theme = Theme.of(context);

    if (detail.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vote')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final entries = detail.entries;
    final myVotes = detail.myVotes;
    final comp = detail.competition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vote on Translations'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${myVotes.length}/${entries.length} rated',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No entries to vote on'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final entry = entries[i];
                final myScore = myVotes[entry.id];

                return _VoteEntryCard(
                  entry: entry,
                  myScore: myScore,
                  songLanguage: comp?.songLanguage ?? 'de',
                  onVote: (score) {
                    SmCompetitionDetailActions(
                      ref,
                      competitionId,
                    ).vote(entryId: entry.id, score: score);
                  },
                );
              },
            ),
    );
  }
}

class _VoteEntryCard extends StatefulWidget {
  final SmCompetitionEntry entry;
  final int? myScore;
  final String songLanguage;
  final ValueChanged<int> onVote;

  const _VoteEntryCard({
    required this.entry,
    this.myScore,
    required this.songLanguage,
    required this.onVote,
  });

  @override
  State<_VoteEntryCard> createState() => _VoteEntryCardState();
}

class _VoteEntryCardState extends State<_VoteEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          ListTile(
            leading: CircleAvatar(
              backgroundImage: entry.translatorPhotoUrl != null
                  ? NetworkImage(entry.translatorPhotoUrl!)
                  : null,
              child: entry.translatorPhotoUrl == null
                  ? Text((entry.translatorUsername ?? '?')[0].toUpperCase())
                  : null,
            ),
            title: Text(
              entry.translatorUsername ?? 'Anonymous',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: entry.styleNote != null
                ? Text(
                    entry.styleNote!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),

          // Translations (expandable).
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: entry.translations.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${t.lineIndex + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.sourceText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                t.translatedText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else if (entry.translations.isNotEmpty)
            // Show first line as preview.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '"${entry.translations.first.translatedText}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Star rating.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starNum = i + 1;
                final isFilled =
                    widget.myScore != null && starNum <= widget.myScore!;

                return GestureDetector(
                  onTap: () => widget.onVote(starNum),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      size: 32,
                      color: isFilled
                          ? const Color(0xFFFFC107)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
