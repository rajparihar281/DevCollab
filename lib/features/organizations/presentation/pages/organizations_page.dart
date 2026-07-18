import 'package:dev_collab/features/auth/presentation/providers/saved_accounts_provider.dart';
import 'package:dev_collab/features/auth/presentation/services/pending_login_credential_holder.dart';
import 'package:dev_collab/features/organizations/presentation/pages/org_workspace_page.dart';
import 'package:dev_collab/shared/services/sticky_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/themes/theme_provider.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/organization_providers.dart';
import '../../../../routing/route_names.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/notifications/data/repositories/notifications_repository.dart' as dev_collab_notifs;
import '../widgets/organization_card.dart';

class OrganizationsPage extends ConsumerStatefulWidget {
  const OrganizationsPage({super.key});

  @override
  ConsumerState<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends ConsumerState<OrganizationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingLoginPrompt();
      _dismissOngoingNotification();
    });
  }

  Future<void> _dismissOngoingNotification() async {
    try {
      await StickyNotificationService().dismissStickyNotification(101);
    } catch (_) {}
  }

  Future<void> _checkPendingLoginPrompt() async {
    final pendingEmail = PendingLoginCredentialHolder.pendingEmail;
    final pendingPwd = PendingLoginCredentialHolder.pendingPassword;

    if (pendingEmail != null && mounted) {
      PendingLoginCredentialHolder.clear();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.key_rounded,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Save your login info?',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We can save your login info for $pendingEmail on this device so you don\'t need to enter it next time.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.read(savedAccountsProvider.notifier).saveAccount(
                          email: pendingEmail,
                          password: pendingPwd ?? '',
                          fullName: pendingEmail.split('@').first,
                        );
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Save Info'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Not Now'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('DevCollab'),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notifsAsync = ref.watch(dev_collab_notifs.notificationsStreamProvider);
              final unreadCount = notifsAsync.maybeWhen(
                data: (notifs) => notifs.where((n) => !n.isRead).length,
                orElse: () => 0,
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () => _showNotificationsSheet(context, ref),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            tooltip: 'Join with Invite Code',
            onPressed: _showJoinWithCodeModal,
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme Mode',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings & Legal',
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: orgsAsync.when(
        loading: () => const AppLoader(message: 'Loading organizations...'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (orgs) => orgs.isEmpty
            ? EmptyState(
                icon: Icons.domain_rounded,
                title: 'No organizations yet',
                subtitle:
                    'Create your first organization or join with an invite code.',
                action: () => context.push(RouteNames.createOrganization),
                actionLabel: 'Create Organization',
              )
            : RefreshIndicator(
                onRefresh: () => ref.read(organizationsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orgs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final org = orgs[i];
                    final isOwner = org.ownerId == ref.read(authRepositoryProvider).currentUser?.id;
                    return Dismissible(
                      key: ValueKey(org.id),
                      direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) {
                        ref.read(organizationsProvider.notifier).deleteOrganization(org.id);
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      child: OrganizationCard(
                        organization: org,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrgWorkspacePage(organization: org),
                          ),
                        ),
                        onDelete: isOwner
                            ? () async {
                                final confirmed = await _confirmDelete(context);
                                if (confirmed) {
                                  await ref
                                      .read(organizationsProvider.notifier)
                                      .deleteOrganization(org.id);
                                }
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_organization',
        onPressed: () => context.push(RouteNames.createOrganization),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Organization'),
      ),
    );
  }

  void _showJoinWithCodeModal() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the invite code shared by your organization leader (e.g., DEV-12345):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                hintText: 'DEV-XXXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(organizationRepositoryProvider)
                    .joinOrgWithCode(code);
                ref.invalidate(organizationsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joined organization successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Organization'),
            content: const Text(
                'This will permanently delete the organization and all its data.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            final notifsAsync = ref.watch(dev_collab_notifs.notificationsStreamProvider);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref.read(dev_collab_notifs.notificationsRepositoryProvider).markAllAsRead();
                        },
                        child: const Text('Mark all as read'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: notifsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (notifs) {
                      if (notifs.isEmpty) {
                        return const Center(child: Text('No notifications yet.'));
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: notifs.length,
                        itemBuilder: (context, index) {
                          final n = notifs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: n.isRead ? Colors.grey.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                              child: Icon(
                                n.type == 'task_assigned' ? Icons.assignment_turned_in : Icons.notifications,
                                color: n.isRead ? Colors.grey : Colors.blue,
                              ),
                            ),
                            title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(n.message),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () {
                                ref.read(dev_collab_notifs.notificationsRepositoryProvider).deleteNotification(n.id);
                              },
                            ),
                            onTap: () {
                              if (!n.isRead) {
                                ref.read(dev_collab_notifs.notificationsRepositoryProvider).markAsRead(n.id);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
