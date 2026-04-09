import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/supabase_config.dart';

/// Post-session tip prompt (SM-2.5.5).
///
/// "Enjoyed this deck? Support [Creator]" — Juice amount chips,
/// coin animation, tip jar milestones.
class SmTipPrompt extends StatefulWidget {
  final String deckId;
  final String creatorId;
  final String creatorName;
  final String tipperId;
  final VoidCallback onDismiss;

  const SmTipPrompt({
    super.key,
    required this.deckId,
    required this.creatorId,
    required this.creatorName,
    required this.tipperId,
    required this.onDismiss,
  });

  /// Show as bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String deckId,
    required String creatorId,
    required String creatorName,
    required String tipperId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SmTipPrompt(
        deckId: deckId,
        creatorId: creatorId,
        creatorName: creatorName,
        tipperId: tipperId,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<SmTipPrompt> createState() => _SmTipPromptState();
}

class _SmTipPromptState extends State<SmTipPrompt>
    with SingleTickerProviderStateMixin {
  int _selectedAmount = 5;
  bool _sending = false;
  bool _sent = false;

  late AnimationController _coinController;

  static const _amounts = [5, 10, 25, 50];

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _sendTip() async {
    setState(() => _sending = true);

    try {
      // Use existing tip RPC from Sprint 13.
      await supabase.rpc('credit_tip', params: {
        'sender_id': widget.tipperId,
        'receiver_id': widget.creatorId,
        'amount': _selectedAmount,
        'content_type': 'skill_mode_deck',
        'content_id': widget.deckId,
      });

      // Update creator stats.
      await supabase.rpc('spend_juice', params: {
        'user_id': widget.tipperId,
        'amount': _selectedAmount,
      });

      // Coin animation.
      _coinController.forward();

      if (mounted) {
        setState(() {
          _sending = false;
          _sent = true;
        });
      }

      // Auto-dismiss after animation.
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) widget.onDismiss();
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tip failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle.
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (_sent) ...[
            // Sent confirmation.
            const Icon(Icons.favorite, size: 48, color: Color(0xFFEF4444))
                .animate()
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 12),
            Text(
              'Tip sent!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_selectedAmount Juice → ${widget.creatorName}',
              style: theme.textTheme.bodySmall,
            ),
          ] else ...[
            // Header.
            Text(
              'Enjoyed this deck?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Support ${widget.creatorName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Amount chips.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _amounts.map((amount) {
                final selected = _selectedAmount == amount;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text('$amount'),
                    avatar: const Icon(Icons.water_drop, size: 16),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedAmount = amount),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Send button.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendTip,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text('Send $_selectedAmount Juice'),
              ),
            ),
            const SizedBox(height: 8),

            // Skip.
            TextButton(
              onPressed: widget.onDismiss,
              child: Text(
                'Skip',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
