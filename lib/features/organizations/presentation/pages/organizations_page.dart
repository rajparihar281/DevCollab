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
                  itemBuilder: (_, i) => OrganizationCard(
                    organization: orgs[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrgWorkspacePage(organization: orgs[i]),
                      ),
                    ),
                    onDelete: orgs[i].ownerId ==
                            ref.read(authRepositoryProvider).currentUser?.id
                        ? () async {
                            final confirmed = await _confirmDelete(context);
                            if (confirmed) {
                              await ref
                                  .read(organizationsProvider.notifier)
                                  .deleteOrganization(orgs[i].id);
                            }
                          }
                        : null,
                  ),
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
}
