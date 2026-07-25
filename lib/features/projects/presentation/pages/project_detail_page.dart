import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/kanban_board.dart';
import '../providers/project_providers.dart';

class ProjectDetailPage extends ConsumerWidget {
  const ProjectDetailPage({
    super.key,
    required this.orgId,
    required this.teamId,
    required this.projectId,
  });

  final String orgId;
  final String teamId;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider(projectId));

    return FutureBuilder(
      future: ref.read(projectRepositoryProvider).getProjectById(projectId),
      builder: (ctx, snap) {
        final projectName = snap.data?.name ?? 'Project';
        return Scaffold(
          appBar: AppBar(
            title: Text(projectName),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_task_rounded),
                tooltip: 'Add Task',
                onPressed: () => context.push(
                  '${RouteNames.projectDetailPath(orgId, teamId, projectId)}/tasks/create',
                ),
              ),
            ],
          ),
          body: tasksAsync.when(
            loading: () => const AppLoader(message: 'Loading board...'),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(tasksProvider(projectId)),
            ),
            data: (tasks) => KanbanBoard(
              tasks: tasks,
              onMoveTask: (taskId, newStatus) async {
                await ref
                    .read(tasksProvider(projectId).notifier)
                    .moveTask(taskId, newStatus);
              },
              onTapTask: (task) => context.push(
                '${RouteNames.projectDetailPath(orgId, teamId, projectId)}/tasks/${task.id}',
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_task',
            onPressed: () => context.push(
              '${RouteNames.projectDetailPath(orgId, teamId, projectId)}/tasks/create',
            ),
            child: const Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }
}
