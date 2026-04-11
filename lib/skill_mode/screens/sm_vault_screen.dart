import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_state.dart';
import '../services/sm_badge_service.dart';
import '../widgets/animations/sm_badge_unlock.dart';

/// Vault screen — badge gallery and profile stats (SM-3.4).
class SmVaultScreen extends ConsumerStatefulWidget {
  const SmVaultScreen({super.key});

  @override
  ConsumerState<SmVaultScreen> createState() => _SmVaultScreenState();
}

class _SmVaultScreenState extends ConsumerState<SmVaultScreen> {
  List<String> _unlockedIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final unlocked = await SmBadgeService.instance.getUnlockedBadges(
      userId: user.id,
      language: 'de',
    );

    if (mounted) {
      setState(() {
        _unlockedIds = unlocked;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Badge Vault')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress summary.
                  Text(
                    '${_unlockedIds.length} of ${SmBadgeService.badges.length} badges unlocked',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: SmBadgeService.badges.isNotEmpty
                        ? _unlockedIds.length / SmBadgeService.badges.length
                        : 0,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),

                  // Badge grid.
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: SmBadgeService.badges.length,
                      itemBuilder: (context, index) {
                        final badge = SmBadgeService.badges[index];
                        final unlocked = _unlockedIds.contains(badge.id);
                        return GestureDetector(
                          onTap: unlocked
                              ? () => SmBadgeUnlock.show(context, badge)
                              : null,
                          child: SmBadgeCard(badge: badge, unlocked: unlocked),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
