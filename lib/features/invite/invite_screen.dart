import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/supabase_config.dart';

/// NFC proximity invite screen.
/// NFC hardware interaction requires `flutter_nfc_kit` package — added to pubspec
/// but actual NFC read/write is gated behind platform availability.
/// Fallback: share invite link via clipboard / system share sheet.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _nfcScanning = false;
  String? _inviteLink;
  int _inviteCount = 0;

  @override
  void initState() {
    super.initState();
    _generateLink();
    _loadInviteCount();
  }

  void _generateLink() {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    // Short invite link with user ID as referrer
    _inviteLink = 'https://juku.pro/invite/${user.id.substring(0, 8)}';
  }

  Future<void> _loadInviteCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Count users who were referred by this user (referrer_id on profiles)
    final data = await supabase
        .from('profiles')
        .select('id')
        .eq('referrer_id', user.id);

    if (mounted) {
      setState(() => _inviteCount = (data as List).length);
    }
  }

  Future<void> _startNfcScan() async {
    setState(() => _nfcScanning = true);

    // NFC scanning placeholder — requires flutter_nfc_kit
    // In production: write invite link to NFC tag, or use Android Beam / iOS Core NFC
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _nfcScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'NFC not available yet — use the share link below instead',
          ),
        ),
      );
    }
  }

  void _copyLink() {
    if (_inviteLink == null) return;
    Clipboard.setData(ClipboardData(text: _inviteLink!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite link copied!')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // NFC tap illustration
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.nfc_rounded,
                    size: 56,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 1200.ms,
                ),
            const SizedBox(height: 24),

            Text(
              'Tap Phones to Invite',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hold your phone close to a friend\'s to send an instant invite. Juku is invite-only — every member is vouched for.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // NFC scan button
            FilledButton.icon(
              onPressed: _nfcScanning ? null : _startNfcScan,
              icon: _nfcScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.nfc_rounded),
              label: Text(
                _nfcScanning
                    ? 'Scanning for nearby phone...'
                    : 'Start NFC Invite',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or share a link',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Invite link
            if (_inviteLink != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _inviteLink!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyLink,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$_inviteCount',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Friends invited',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${_inviteCount * 25}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'XP earned',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // XP rewards info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite Rewards',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RewardRow(
                      icon: Icons.person_add,
                      text: 'Friend joins',
                      xp: '+25 XP',
                    ),
                    _RewardRow(
                      icon: Icons.trending_up,
                      text: 'Friend hits Level 5',
                      xp: '+50 XP',
                    ),
                    _RewardRow(
                      icon: Icons.school,
                      text: 'Friend creates first lesson',
                      xp: '+15 XP',
                    ),
                    _RewardRow(
                      icon: Icons.monetization_on,
                      text: 'Friend sends first tip',
                      xp: '+10 XP',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.text, required this.xp});

  final IconData icon;
  final String text;
  final String xp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          Text(
            xp,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
