import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tenant_state.dart';
import '../tenant_service.dart';

/// User management tab: list users, invite, revoke.
class UsersTab extends ConsumerWidget {
  final String tenantId;

  const UsersTab({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tenantUsersProvider(tenantId));
    final invitesAsync = ref.watch(tenantInvitesProvider(tenantId));
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Invite button
        FilledButton.icon(
          onPressed: () => _showInviteDialog(context, ref),
          icon: const Icon(Icons.person_add),
          label: const Text('Invite User'),
        ),
        const SizedBox(height: 24),

        // Current users
        Text('Team Members', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (users) => Column(
            children: [
              for (var i = 0; i < users.length; i++)
                _UserTile(
                  user: users[i],
                  tenantId: tenantId,
                )
                    .animate()
                    .fadeIn(delay: (i * 50).ms)
                    .slideX(begin: 0.05, end: 0),
              if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No team members yet'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Pending invites
        Text('Pending Invites', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        invitesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (invites) {
            final pending =
                invites.where((i) => i.status == 'pending').toList();
            return Column(
              children: [
                for (final invite in pending)
                  _InviteTile(
                    invite: invite,
                    tenantId: tenantId,
                  ),
                if (pending.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No pending invites'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    String role = 'member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'user@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('Member')),
                  DropdownMenuItem(
                      value: 'moderator', child: Text('Moderator')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setDialogState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await TenantService.instance.createInvite(
                  tenantId: tenantId,
                  email: emailCtrl.text.trim().isNotEmpty
                      ? emailCtrl.text.trim()
                      : null,
                  role: role,
                );
                ref.invalidate(tenantInvitesProvider(tenantId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create Invite'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final TenantAdmin user;
  final String tenantId;

  const _UserTile({required this.user, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roleColor = switch (user.role) {
      'owner' => Colors.amber,
      'admin' => theme.colorScheme.primary,
      'moderator' => Colors.green,
      _ => theme.colorScheme.onSurfaceVariant,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (user.displayName ?? user.username ?? '?')[0].toUpperCase(),
          ),
        ),
        title: Text(user.displayName ?? user.username ?? 'Unknown'),
        subtitle: Text(
          user.role.toUpperCase(),
          style: TextStyle(color: roleColor, fontSize: 12),
        ),
        trailing: user.role != 'owner'
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove user?'),
                      content: Text(
                          'Remove ${user.displayName ?? user.username} from this tenant?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await TenantService.instance
                        .removeUser(tenantId, user.userId);
                    ref.invalidate(tenantUsersProvider(tenantId));
                  }
                },
              )
            : null,
      ),
    );
  }
}

class _InviteTile extends ConsumerWidget {
  final TenantInvite invite;
  final String tenantId;

  const _InviteTile({required this.invite, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mail_outline),
        title: Text(invite.email ?? 'Open invite'),
        subtitle: Text('Code: ${invite.inviteCode} · ${invite.role}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copy invite code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invite.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Revoke',
              onPressed: () async {
                await TenantService.instance.revokeInvite(invite.id);
                ref.invalidate(tenantInvitesProvider(tenantId));
              },
            ),
          ],
        ),
      ),
    );
  }
}
