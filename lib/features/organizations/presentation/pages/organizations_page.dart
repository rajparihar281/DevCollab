import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/organization_providers.dart';
import '../../../../routing/route_names.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/organization_card.dart';

class OrganizationsPage extends ConsumerWidget {
  const OrganizationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationsProvider);
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
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
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
                    'Create your first organization to start collaborating with your team.',
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
                    onTap: () => context.push(
                      RouteNames.organizationDetailPath(orgs[i].id),
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
        onPressed: () => context.push(RouteNames.createOrganization),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Organization'),
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
