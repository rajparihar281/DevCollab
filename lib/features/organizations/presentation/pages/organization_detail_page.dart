import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../providers/organization_providers.dart';
import '../providers/activity_providers.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../widgets/activity_feed.dart';
import '../../../teams/presentation/widgets/team_card.dart';

class OrganizationDetailPage extends ConsumerWidget {
  const OrganizationDetailPage({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationDetailProvider(orgId));

    return orgAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
      data: (org) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(org.name),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.groups_rounded), text: 'Teams'),
                Tab(icon: Icon(Icons.history_rounded), text: 'Activity'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _TeamsTab(orgId: orgId),
              _ActivityTab(orgId: orgId),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'create_team',
            onPressed: () =>
                context.push(RouteNames.createTeamPath(orgId)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Team'),
          ),
        ),
      ),
    );
  }
}

class _TeamsTab extends ConsumerWidget {
  const _TeamsTab({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(orgId));

    return teamsAsync.when(
      loading: () => const AppLoader(message: 'Loading teams...'),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(teamsProvider(orgId)),
      ),
      data: (teams) => teams.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No teams yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a team to start working on projects.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(teamsProvider(orgId).notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: teams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => TeamCard(
                  team: teams[i],
                  onTap: () => context.push(
                    RouteNames.teamDetailPath(orgId, teams[i].id),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider(orgId));
    return logsAsync.when(
      loading: () => const AppLoader(message: 'Loading activity...'),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (logs) => ActivityFeed(logs: logs),
    );
  }
}
