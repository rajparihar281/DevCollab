import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../providers/team_providers.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/widgets/project_card.dart';

class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({
    super.key,
    required this.orgId,
    required this.teamId,
  });

  final String orgId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamRepo = ref.read(teamRepositoryProvider);

    return FutureBuilder(
      future: teamRepo.getTeamById(teamId),
      builder: (context, snap) {
        final teamName =
            snap.hasData ? snap.data!.name : 'Team';
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(teamName),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  tooltip: 'Team Chat',
                  onPressed: () => context.push(
                    RouteNames.chatPath(orgId, teamId),
                  ),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.folder_rounded), text: 'Projects'),
                  Tab(icon: Icon(Icons.people_rounded), text: 'Members'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ProjectsTab(orgId: orgId, teamId: teamId),
                _MembersTab(teamId: teamId),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'create_project',
              onPressed: () =>
                  context.push(RouteNames.createProjectPath(orgId, teamId)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Project'),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab({required this.orgId, required this.teamId});
  final String orgId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider(teamId));
    return projectsAsync.when(
      loading: () => const AppLoader(message: 'Loading projects...'),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(projectsProvider(teamId)),
      ),
      data: (projects) => projects.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(projectsProvider(teamId).notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: projects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => ProjectCard(
                  project: projects[i],
                  onTap: () => context.push(
                    RouteNames.projectDetailPath(orgId, teamId, projects[i].id),
                  ),
                ),
              ),
            ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    return membersAsync.when(
      loading: () => const AppLoader(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (members) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (_, i) {
          final m = members[i];
          return ListTile(
            leading: AvatarWidget(
              avatarUrl: m.avatarUrl,
              name: m.fullName,
            ),
            title: Text(m.fullName ?? 'Unknown'),
          );
        },
      ),
    );
  }
}
