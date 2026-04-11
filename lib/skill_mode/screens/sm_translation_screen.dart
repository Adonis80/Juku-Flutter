import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_config.dart';
import '../models/sm_translation.dart';
import '../services/sm_translation_service.dart';

/// Community translations screen (SM-6).
///
/// Shows all translations for a card or lyric line, allows submission,
/// editing, voting, and expert verification.
class SmTranslationScreen extends ConsumerStatefulWidget {
  final String? cardId;
  final String? songId;
  final int? lyricLineIndex;
  final String sourceText;

  const SmTranslationScreen({
    super.key,
    this.cardId,
    this.songId,
    this.lyricLineIndex,
    required this.sourceText,
  });

  @override
  ConsumerState<SmTranslationScreen> createState() =>
      _SmTranslationScreenState();
}

class _SmTranslationScreenState extends ConsumerState<SmTranslationScreen> {
  final _service = SmTranslationService();
  List<SmTranslation> _translations = [];
  Map<String, int> _userVotes = {};
  SmTranslatorStats? _myStats;
  bool _loading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = supabase.auth.currentUser?.id;
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    try {
      List<SmTranslation> translations;
      if (widget.cardId != null) {
        translations = await _service.getCardTranslations(
          cardId: widget.cardId!,
        );
      } else {
        translations = await _service.getLyricTranslations(
          songId: widget.songId!,
          lineIndex: widget.lyricLineIndex!,
        );
      }

      // Batch-load user votes
      Map<String, int> votes = {};
      if (_userId != null && translations.isNotEmpty) {
        votes = await _service.getUserVotesBatch(
          translationIds: translations.map((t) => t.id).toList(),
          userId: _userId!,
        );
        _myStats = await _service.getTranslatorStats(userId: _userId!);
      }

      if (mounted) {
        setState(() {
          _translations = translations;
          _userVotes = votes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Translations'),
        actions: [
          if (_myStats != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                avatar: Text(_myStats!.tierEmoji),
                label: Text(
                  _myStats!.tierLabel,
                  style: theme.textTheme.labelSmall,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Source text header
                SliverToBoxAdapter(child: _buildSourceHeader(theme, cs)),
                // Translation list
                if (_translations.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState(theme, cs))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTranslationCard(
                        _translations[index],
                        theme,
                        cs,
                      ),
                      childCount: _translations.length,
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmitDialog(context, theme),
        icon: const Icon(Icons.translate),
        label: const Text('Add Translation'),
      ),
    );
  }

  Widget _buildSourceHeader(ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Original Text',
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.sourceText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${_translations.length} translation${_translations.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              if (_translations.any((t) => t.isVerified))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.translate,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No translations yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to translate this! You\'ll earn the First Translator badge.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationCard(
    SmTranslation translation,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final userVote = _userVotes[translation.id];
    final isOwn = translation.translatorId == _userId;
    final canExpertVerify = _myStats?.tier == 'expert' && !isOwn;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: translation.isExpertVerified
            ? BorderSide(color: cs.primary, width: 2)
            : translation.isVerified
            ? BorderSide(color: cs.primary.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Translator info row
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: translation.translatorPhotoUrl != null
                      ? NetworkImage(translation.translatorPhotoUrl!)
                      : null,
                  child: translation.translatorPhotoUrl == null
                      ? const Icon(Icons.person, size: 14)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            translation.translatorUsername ?? 'Anonymous',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (translation.isFirstTranslator) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'First \u{1F451}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.amber.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                _buildStatusBadge(translation, theme, cs),
              ],
            ),
            const SizedBox(height: 10),
            // Translation text
            Text(translation.translatedText, style: theme.textTheme.bodyLarge),
            // Notes
            if (translation.notes != null && translation.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        translation.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Action row: votes + actions
            Row(
              children: [
                // Upvote
                _VoteButton(
                  icon: Icons.thumb_up_outlined,
                  activeIcon: Icons.thumb_up,
                  count: translation.upvotes,
                  isActive: userVote == 1,
                  activeColor: cs.primary,
                  onTap: () => _vote(translation.id, 1),
                ),
                const SizedBox(width: 12),
                // Downvote
                _VoteButton(
                  icon: Icons.thumb_down_outlined,
                  activeIcon: Icons.thumb_down,
                  count: translation.downvotes,
                  isActive: userVote == -1,
                  activeColor: cs.error,
                  onTap: () => _vote(translation.id, -1),
                ),
                const Spacer(),
                if (translation.isAiDraft)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        'AI Draft',
                        style: theme.textTheme.labelSmall,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                // Expert verify button
                if (canExpertVerify && translation.isPending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.verified, color: cs.primary),
                        iconSize: 20,
                        tooltip: 'Expert Verify',
                        onPressed: () => _expertVerify(translation.id),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.error),
                        iconSize: 20,
                        tooltip: 'Reject',
                        onPressed: () => _reject(translation.id),
                      ),
                    ],
                  ),
                // Edit own translation
                if (isOwn && translation.isPending)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit',
                    onPressed: () =>
                        _showEditDialog(context, theme, translation),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    SmTranslation translation,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (translation.isExpertVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text(
              'Expert Verified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (translation.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (translation.isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Rejected',
          style: theme.textTheme.labelSmall?.copyWith(color: cs.error),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Actions ──

  Future<void> _vote(String translationId, int vote) async {
    if (_userId == null) return;
    final oldVote = _userVotes[translationId];

    // Optimistic update
    setState(() {
      if (oldVote == vote) {
        _userVotes.remove(translationId);
      } else {
        _userVotes[translationId] = vote;
      }
      // Update counts optimistically
      final idx = _translations.indexWhere((t) => t.id == translationId);
      if (idx >= 0) {
        // Reload after server confirms
      }
    });

    await _service.castVote(
      translationId: translationId,
      voterId: _userId!,
      vote: vote,
    );
    await _loadTranslations();
  }

  Future<void> _expertVerify(String translationId) async {
    if (_userId == null) return;
    await _service.expertVerify(
      translationId: translationId,
      verifierId: _userId!,
    );
    await _loadTranslations();
  }

  Future<void> _reject(String translationId) async {
    if (_userId == null) return;
    await _service.rejectTranslation(
      translationId: translationId,
      rejectorId: _userId!,
    );
    await _loadTranslations();
  }

  void _showSubmitDialog(BuildContext context, ThemeData theme) {
    final textController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Translation', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Translate: "${widget.sourceText}"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Your translation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional — grammar hints, context)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (textController.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await _submitTranslation(
                    textController.text.trim(),
                    notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTranslation(String text, String? notes) async {
    if (_userId == null) return;

    await _service.submitTranslation(
      translatorId: _userId!,
      sourceText: widget.sourceText,
      translatedText: text,
      cardId: widget.cardId,
      songId: widget.songId,
      lyricLineIndex: widget.lyricLineIndex,
      notes: notes,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Translation submitted!')));
    }
    await _loadTranslations();
  }

  void _showEditDialog(
    BuildContext context,
    ThemeData theme,
    SmTranslation translation,
  ) {
    final textController = TextEditingController(
      text: translation.translatedText,
    );
    final notesController = TextEditingController(
      text: translation.notes ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Translation', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Translation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _service.deleteTranslation(
                        translationId: translation.id,
                      );
                      await _loadTranslations();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (textController.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      await _service.editTranslation(
                        translationId: translation.id,
                        translatedText: textController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );
                      await _loadTranslations();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable vote button with count.
class _VoteButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.activeIcon,
    required this.count,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 18,
              color: isActive
                  ? activeColor
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? activeColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
